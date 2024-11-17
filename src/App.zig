const std = @import("std");
const mach = @import("mach");
const zm = @import("zmath");

const util = @import("util.zig");

const Movement = @import("Movement.zig");
const Physics = @import("Physics.zig");
const Renderer = @import("Renderer.zig");

pub const name = .app;
pub const Mod = mach.Mod(@This());

player: mach.EntityID,

pub const systems = .{
    .start = .{ .handler = start },
    .deinit = .{ .handler = deinit },
    .init = .{ .handler = init },
    .tick = .{ .handler = tick },
};

pub fn deinit(renderer: *Renderer.Mod) void {
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
    entities: *mach.Entities.Mod,
    game: *Mod,
    physics: *Physics.Mod,
    renderer: *Renderer.Mod,
) !void {
    core.state().on_tick = game.system(.tick);
    core.state().on_exit = game.system(.deinit);

    const player = try entities.new();

    try physics.set(player, .position, .{ 0, 0, -4 });
    try physics.set(player, .velocity, .{ 0, 0, 0 });
    try renderer.set(player, .rotation, .{ .vertical = 0, .horizontal = 0 });
    try renderer.set(player, .camera, {});

    // Store our render pipeline in our module's state, so we can access it later on.
    game.init(.{
        .player = player,
    });
    core.schedule(.start);
}

fn tick(
    core: *mach.Core.Mod,
    game: *Mod,
    movement: *Movement.Mod,
    physics: *Physics.Mod,
    renderer: *Renderer.Mod,
) !void {
    _ = core; // autofix
    _ = game; // autofix
    movement.schedule(.update);
    physics.schedule(.update);
    renderer.schedule(.render_frame);
}
