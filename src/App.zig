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
    .deinit = .{ .handler = deinit },
    .init = .{ .handler = init },
    .update = .{ .handler = update },
};

pub fn deinit(renderer: *Renderer.Mod) void {
    renderer.schedule(.deinit);
}

fn init(
    entities: *mach.Entities.Mod,
    game: *Mod,
    movement: *Movement.Mod,
    physics: *Physics.Mod,
    renderer: *Renderer.Mod,
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
