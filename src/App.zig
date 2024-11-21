const std = @import("std");

const mach = @import("mach");
const zm = @import("zmath");

const Movement = @import("Movement.zig");
const Physics = @import("Physics.zig");
const Renderer = @import("Renderer.zig");

pub const name = .app;
pub const Mod = mach.Mod(@This());

pub const systems = .{
    .start = .{ .handler = start },
    .deinit = .{ .handler = deinit },
    .init = .{ .handler = init },
    .tick = .{ .handler = tick },
};

pub fn deinit(renderer: *Renderer.Mod, core: *mach.Core.Mod) void {
    renderer.schedule(.deinit);
    core.schedule(.deinit);
}

fn start(
    core: *mach.Core.Mod,
    renderer: *Renderer.Mod,
    physics: *Physics.Mod,
    movement: *Movement.Mod,
    app: *Mod,
) !void {
    core.schedule(.init);
    renderer.schedule(.init);
    physics.schedule(.init);
    movement.schedule(.init);
    app.schedule(.init);
}

fn init(
    core: *mach.Core.Mod,
    app: *Mod,
) !void {
    core.state().on_tick = app.system(.tick);
    core.state().on_exit = app.system(.deinit);

    // Store our render pipeline in our module's state, so we can access it later on.
    app.init(.{});
    core.schedule(.start);
}

fn tick(
    core: *mach.Core.Mod,
    app: *Mod,
    movement: *Movement.Mod,
    physics: *Physics.Mod,
    renderer: *Renderer.Mod,
) !void {
    _ = core; // autofix
    _ = app; // autofix
    movement.schedule(.update);
    physics.schedule(.update);
    renderer.schedule(.render_frame);
}
