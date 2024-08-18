const std = @import("std");
const mach = @import("mach");
const zm = @import("zmath");

const Renderer = @import("Renderer.zig");

pub const name = .app;
pub const Mod = mach.Mod(@This());

pub const systems = .{
    .init = .{ .handler = init },
    .deinit = .{ .handler = deinit },
    .update = .{ .handler = update },
};

timer: mach.Timer,
player: mach.EntityID,

pub fn deinit(renderer: *Renderer.Mod) void {
    renderer.schedule(.deinit);
}

fn init(
    game: *Mod,
    renderer: *Renderer.Mod,
    entities: *mach.Entities.Mod,
) !void {
    renderer.schedule(.init);

    const player = try entities.new();

    try renderer.set(player, .position, zm.Vec{ 0, 0, -4, 1 });
    try renderer.set(player, .rotation, zm.quatFromRollPitchYaw(0, 0, 0));
    try renderer.set(player, .is_camera, {});

    // Store our render pipeline in our module's state, so we can access it later on.
    game.init(.{
        .player = player,
        .timer = try mach.Timer.start(),
    });
}

fn update(core: *mach.Core.Mod, game: *Mod, renderer: *Renderer.Mod) !void {
    var iter = core.state().pollEvents();
    while (iter.next()) |event| {
        switch (event) {
            .close => core.schedule(.exit), // Tell mach.Core to exit the app
            else => {},
        }
    }

    const delta_time = game.state().timer.lap();
    const player = game.state().player;
    var player_pos = renderer.get(player, .position).?;
    player_pos[1] += 1 * delta_time;
    try renderer.set(player, .position, player_pos);

    renderer.schedule(.render_frame);
}
