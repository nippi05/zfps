const std = @import("std");
const mach = @import("mach");
const zm = @import("zmath");
const util = @import("util.zig");
const Renderer = @import("Renderer.zig");
const Physics = @import("Physics.zig");
const Movement = @import("Movement.zig");

pub const name = .app;
pub const Mod = mach.Mod(@This());

pub const systems = .{
    .init = .{ .handler = init },
    .deinit = .{ .handler = deinit },
    .update = .{ .handler = update },
};

player: mach.EntityID,

pub fn deinit(renderer: *Renderer.Mod) void {
    renderer.schedule(.deinit);
}

fn init(
    game: *Mod,
    renderer: *Renderer.Mod,
    physics: *Physics.Mod,
    entities: *mach.Entities.Mod,
    movement: *Movement.Mod,
) !void {
    renderer.schedule(.init);
    physics.schedule(.init);
    movement.schedule(.init);

    const player = try entities.new();

    try physics.set(player, .position, .{ 0, 0, -4 });
    try physics.set(player, .velocity, .{ 0, 0, 0 });
    try renderer.set(player, .rotation, .{ .vertical = 0, .horizontal = 0 });
    try renderer.set(player, .camera, {});

    // Store our render pipeline in our module's state, so we can access it later on.
    game.init(.{
        .player = player,
    });
}

fn update(
    core: *mach.Core.Mod,
    game: *Mod,
    renderer: *Renderer.Mod,
    physics: *Physics.Mod,
    movement: *Movement.Mod,
) !void {
    _ = core; // autofix
    _ = game; // autofix
    movement.schedule(.update);
    physics.schedule(.update);
    renderer.schedule(.render_frame);
}
