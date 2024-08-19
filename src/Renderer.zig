const std = @import("std");
const mach = @import("mach");
const zm = @import("zmath");

const util = @import("util.zig");
const cube = @import("cube.zig");

const Game = @import("App.zig");
const Physics = @import("Physics.zig");

const gpu = mach.gpu;

pub const name = .renderer;
pub const Mod = mach.Mod(@This());

pipeline: *gpu.RenderPipeline,
uniform_buffer: *gpu.Buffer,
vertex_buffer: *gpu.Buffer,
bind_group: *gpu.BindGroup,

pub const Rotation = struct {
    vertical: f32,
    horizontal: f32,
};

pub const components = .{
    .camera = .{ .type = void },
    .rotation = .{ .type = Rotation },
};

pub const systems = .{
    .deinit = .{ .handler = deinit },
    .init = .{ .handler = init },
    .render_frame = .{ .handler = renderFrame },
};

const UniformBufferObject = struct {
    model_view_projection_matrix: zm.Mat, // zmath is row major, have to transpose.
};

pub fn deinit(renderer: *Mod) void {
    renderer.state().pipeline.release();
    renderer.state().uniform_buffer.release();
    renderer.state().bind_group.release();
    renderer.state().vertex_buffer.release();
}

fn init(
    core: *mach.Core.Mod,
    renderer: *Mod,
) !void {
    const label = @tagName(name) ++ ".init";
    const device: *gpu.Device = core.state().device;

    // Create our shader module
    const shader_module = device.createShaderModuleWGSL(
        "shader.wgsl",
        @embedFile("shader.wgsl"),
    );
    defer shader_module.release();

    const vertex_attributes = [_]gpu.VertexAttribute{.{
        .format = .float32x3,
        .offset = @offsetOf(cube.Vertex, "pos"),
        .shader_location = 0,
    }};

    const vertex_buffer_layout = gpu.VertexBufferLayout.init(.{
        .array_stride = @sizeOf(cube.Vertex),
        .step_mode = .vertex,
        .attributes = &vertex_attributes,
    });

    const vertex_buffer = device.createBuffer(&.{
        .label = label ++ " vertex buffer",
        .usage = .{ .vertex = true, .copy_dst = true },
        .size = @sizeOf(cube.Vertex) * cube.vertices.len,
        .mapped_at_creation = .true,
    });

    const vertex_mapped = vertex_buffer.getMappedRange(
        cube.Vertex,
        0,
        cube.vertices.len,
    ).?;
    @memcpy(vertex_mapped, cube.vertices[0..]);
    vertex_buffer.unmap();

    // Blend state describes how rendered colors get blended
    const blend = gpu.BlendState{};

    // Color target describes e.g. the pixel format of the window we are rendering to.
    const color_target = gpu.ColorTargetState{
        // "get preferred format"
        .format = core.get(
            core.state().main_window,
            .framebuffer_format,
        ).?,
        .blend = &blend,
    };

    // Fragment state describes which shader and entrypoint to use for rendering fragments.
    const fragment = gpu.FragmentState.init(.{
        .module = shader_module,
        .entry_point = "frag_main",
        .targets = &.{color_target},
    });

    const uniform_buffer = device.createBuffer(&.{
        .label = label ++ " uniform buffer",
        .mapped_at_creation = .false,
        .usage = .{ .copy_dst = true, .uniform = true },
        .size = @sizeOf(UniformBufferObject),
    });

    const bind_group_layout_entry = gpu.BindGroupLayout.Entry.buffer(
        0,
        .{ .vertex = true },
        .uniform,
        false,
        0,
    );
    const bind_group_layout = device.createBindGroupLayout(
        &gpu.BindGroupLayout.Descriptor.init(.{
            .label = label ++ " bind group layout",
            .entries = &.{bind_group_layout_entry},
        }),
    );
    defer bind_group_layout.release();

    const bind_group = device.createBindGroup(
        &gpu.BindGroup.Descriptor.init(.{
            .label = label ++ " bind group",
            .layout = bind_group_layout,
            .entries = &.{gpu.BindGroup.Entry.buffer(
                0,
                uniform_buffer,
                0,
                @sizeOf(UniformBufferObject),
                @sizeOf(UniformBufferObject),
            )},
        }),
    );

    const bind_group_layouts = [_]*gpu.BindGroupLayout{bind_group_layout};
    const pipeline_layout = device.createPipelineLayout(
        &gpu.PipelineLayout.Descriptor.init(.{
            .label = label ++ " pipeline layout",
            .bind_group_layouts = &bind_group_layouts,
        }),
    );
    defer pipeline_layout.release();
    // Create our render pipeline that will ultimately get pixels onto the screen.
    const pipeline_descriptor = gpu.RenderPipeline.Descriptor{
        .label = label ++ " pipeline descriptor",
        .fragment = &fragment,
        .layout = pipeline_layout,
        .vertex = gpu.VertexState.init(.{
            .module = shader_module,
            .entry_point = "vertex_main",
            .buffers = &.{vertex_buffer_layout},
        }),
    };
    const pipeline = device.createRenderPipeline(&pipeline_descriptor);

    // Store our render pipeline in our module's state, so we can access it later on.
    renderer.init(.{
        .pipeline = pipeline,
        .bind_group = bind_group,
        .uniform_buffer = uniform_buffer,
        .vertex_buffer = vertex_buffer,
    });
}

fn renderFrame(
    core: *mach.Core.Mod,
    renderer: *Mod,
    game: *Game.Mod,
    physics: *Physics.Mod,
) !void {
    // Grab the back buffer of the swapchain
    // TODO(Core)
    const back_buffer_view = core.state().swap_chain.getCurrentTextureView().?;
    defer back_buffer_view.release();

    // Create a command encoder
    const label = @tagName(name) ++ ".update";
    const encoder: *gpu.CommandEncoder = core.state().device.createCommandEncoder(&.{
        .label = label ++ " command encoder",
    });
    defer encoder.release();

    // Calculate mvp matrix
    const main_window_id: mach.EntityID = core.state().main_window;
    const window_width: u32 = core.get(main_window_id, .width).?; // These have to be set so use .?
    const window_height: u32 = core.get(main_window_id, .height).?;

    const mvp: zm.Mat = blk: {
        const model = zm.identity(); // zm.mul(zm.rotationX(time * (std.math.pi / 2.0)), zm.rotationZ(time * (std.math.pi / 2.0)));
        // Get player position
        const player = game.state().player;
        const rotation = renderer.get(player, .rotation).?;
        const position = physics.get(player, .position).?;

        // UNDERSTANDME: Courtesy of CHATGPT!! I DONT UNDERSTAND THE FOLLOWING.
        // Is the handedness of this not right haha...
        const view = zm.mul(
            zm.translationV(-zm.Vec{ position[0], position[1], position[2], 1 }),
            util.rotationToMat(rotation),
        );

        const proj = zm.perspectiveFovLh(
            std.math.pi / 4.0,
            @as(f32, @floatFromInt(window_width)) / @as(
                f32,
                @floatFromInt(window_height),
            ),
            0.5,
            100,
        );

        break :blk zm.mul(zm.mul(model, view), proj);
    };
    // Update uniform buffer
    const ubo: UniformBufferObject = .{
        .model_view_projection_matrix = mvp,
    };
    encoder.writeBuffer(
        renderer.state().uniform_buffer,
        0,
        &[_]UniformBufferObject{ubo},
    );

    // Begin render pass
    const sky_blue_background = gpu.Color{ .r = 0.776, .g = 0.988, .b = 1, .a = 1 };
    const color_attachments = [_]gpu.RenderPassColorAttachment{.{
        .view = back_buffer_view,
        .clear_value = sky_blue_background,
        .load_op = .clear,
        .store_op = .store,
    }};
    const render_pass = encoder.beginRenderPass(
        &gpu.RenderPassDescriptor.init(.{
            .label = label ++ " render pass",
            .color_attachments = &color_attachments,
        }),
    );
    defer render_pass.release();

    // Draw
    render_pass.setPipeline(renderer.state().pipeline);
    render_pass.setBindGroup(
        0,
        renderer.state().bind_group,
        null,
    );
    render_pass.setVertexBuffer(
        0,
        renderer.state().vertex_buffer,
        0,
        @sizeOf(cube.Vertex) * cube.vertices.len,
    );

    render_pass.draw(cube.vertices.len, 1, 0, 0);

    // Finish render pass
    render_pass.end();

    // Submit our commands to the queue
    var command = encoder.finish(&.{ .label = label ++ " command buffer" });
    defer command.release();
    core.state().queue.submit(&[_]*gpu.CommandBuffer{command});

    core.schedule(.present_frame);
}
