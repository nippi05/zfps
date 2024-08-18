const std = @import("std");
const mach = @import("mach");
const zm = @import("zmath");

const Renderer = @import("Renderer.zig");
const Physics = @import("Physics.zig");

pub const name = .app;
pub const Mod = mach.Mod(@This());

pub const systems = .{
    .init = .{ .handler = init },
    .deinit = .{ .handler = deinit },
    .update = .{ .handler = update },
};

const MoveKeys = enum {
    w,
    a,
    s,
    d,
    left_shift,
    space,
    left,
    right,
    up,
    down,
};

player: mach.EntityID,
pressed_keys: std.StaticBitSet(std.meta.fields(MoveKeys).len),
// mouse_position: LookingDirectionon, // Looking with mouse isn't supported due to the fact that mach.Core.cursor_mode.disabled isn't implemented for win32 backend

pub fn deinit(renderer: *Renderer.Mod) void {
    renderer.schedule(.deinit);
}

fn init(
    game: *Mod,
    renderer: *Renderer.Mod,
    physics: *Physics.Mod,
    entities: *mach.Entities.Mod,
    core: *mach.Core.Mod,
) !void {
    renderer.schedule(.init);
    physics.schedule(.init);
    core.state().setCursorMode(.disabled); // Unimplemented.
    const player = try entities.new();

    try physics.set(player, .position, .{ 0, 0, -4 });
    try physics.set(player, .velocity, .{ 0, 0, 0 });
    try renderer.set(player, .rotation, .{ 0, 0 });
    try renderer.set(player, .camera, {});

    // Store our render pipeline in our module's state, so we can access it later on.
    game.init(.{
        .player = player,
        .pressed_keys = std.StaticBitSet(std.meta.fields(MoveKeys).len).initEmpty(),
        // .mouse_position = .{ .x = 0, .y = 0 },
    });
}

fn update(
    core: *mach.Core.Mod,
    game: *Mod,
    renderer: *Renderer.Mod,
    physics: *Physics.Mod,
) !void {
    const player: mach.EntityID = game.state().player;

    var iter: mach.Core.EventIterator = core.state().pollEvents();
    var pressed_keys = game.state().pressed_keys;
    while (iter.next()) |event| {
        switch (event) {
            .close => core.schedule(.exit), // Tell mach.Core to exit the app
            // .mouse_motion => |mouse| {
            //     const prev_mouse_pos = game.state().mouse_position;
            //     // FIXME: No helper function and no bitches. Make this data more
            //     // about mosue movement and not pxiel movement / screen size.
            //     const mouse_pixel_delta: mach.Core.Position = .{
            //         .x = (prev_mouse_pos.x - mouse.pos.x) / 1000,
            //         .y = (prev_mouse_pos.y - mouse.pos.y) / 1000,
            //     };
            //     game.state().mouse_position = mouse.pos;
            //     const prev_rotation: zm.Quat = physics.get(player, .rotation).?;
            //     try physics.set(
            //         player,
            //         .rotation,
            //         zm.qmul(prev_rotation, zm.quatFromRollPitchYaw(
            //             @floatCast(mouse_pixel_delta.y),
            //             @floatCast(mouse_pixel_delta.x),
            //             0,
            //         )),
            //     );
            // },
            .key_press => |e| {
                switch (e.key) {
                    inline else => |key| {
                        if (@hasField(MoveKeys, @tagName(key))) {
                            pressed_keys.set(@intFromEnum(@field(MoveKeys, @tagName(key))));
                        }
                    },
                }
            },
            .key_release => |e| {
                switch (e.key) {
                    inline else => |key| {
                        if (@hasField(MoveKeys, @tagName(key))) {
                            pressed_keys.unset(@intFromEnum(@field(MoveKeys, @tagName(key))));
                        }
                    },
                }
            },
            else => {},
        }
    }

    var rotating_angles = @Vector(2, f32){ 0, 0 };
    const rotation_speed = 0.01;
    var player_velocity = @Vector(3, f32){ 0, 0, 0 };
    const move_speed = 10;
    inline for (std.meta.fields(MoveKeys)) |field| {
        const key = @field(MoveKeys, field.name);
        if (pressed_keys.isSet(@intFromEnum(key))) {
            switch (key) {
                .w => player_velocity[2] += move_speed,
                .s => player_velocity[2] -= move_speed,
                .d => player_velocity[0] += move_speed,
                .a => player_velocity[0] -= move_speed,
                .space => player_velocity[1] += move_speed,
                .left_shift => player_velocity[1] -= move_speed,
                .left => rotating_angles[1] += rotation_speed,
                .right => rotating_angles[1] -= rotation_speed,
                .up => rotating_angles[0] += rotation_speed,
                .down => rotating_angles[0] -= rotation_speed,
            }
        }
    }
    game.state().pressed_keys = pressed_keys;
    try physics.set(player, .velocity, player_velocity);

    const prev_rotation = renderer.get(player, .rotation).?;

    try renderer.set(
        player,
        .rotation,
        .{
            std.math.clamp(prev_rotation[0] + rotating_angles[0], -std.math.pi / @as(comptime_float, 2), std.math.pi / @as(comptime_float, 2)),
            prev_rotation[1] + rotating_angles[1],
        },
    );

    physics.schedule(.update);
    renderer.schedule(.render_frame);
}
