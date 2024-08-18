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

pub const MoveKeys = enum {
    w,
    a,
    s,
    d,
    left_shift,
    space,
};

player: mach.EntityID,
pressed_keys: std.StaticBitSet(std.meta.fields(MoveKeys).len),

pub fn deinit(renderer: *Renderer.Mod) void {
    renderer.schedule(.deinit);
}

fn init(
    game: *Mod,
    renderer: *Renderer.Mod,
    physics: *Physics.Mod,
    entities: *mach.Entities.Mod,
) !void {
    renderer.schedule(.init);
    physics.schedule(.init);

    const player = try entities.new();

    try physics.set(player, .position, .{ 0, 0, -4 });
    try physics.set(player, .velocity, .{ 0, 0, 0 });
    try physics.set(player, .rotation, zm.quatFromRollPitchYaw(0, 0, 0));
    try renderer.set(player, .is_camera, {});

    // Store our render pipeline in our module's state, so we can access it later on.
    game.init(.{
        .player = player,
        .pressed_keys = std.StaticBitSet(std.meta.fields(MoveKeys).len).initEmpty(),
    });
}

fn update(
    core: *mach.Core.Mod,
    game: *Mod,
    renderer: *Renderer.Mod,
    physics: *Physics.Mod,
) !void {
    var iter: mach.Core.EventIterator = core.state().pollEvents();
    var pressed_keys = game.state().pressed_keys;
    while (iter.next()) |event| {
        switch (event) {
            .close => core.schedule(.exit), // Tell mach.Core to exit the app
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

    const player: mach.EntityID = game.state().player;
    var player_velocity = @Vector(3, f32){ 0, 0, 0 };
    const move_speed = 10;
    inline for (std.meta.fields(MoveKeys)) |field| {
        const key = @field(MoveKeys, field.name);
        if (pressed_keys.isSet(@intFromEnum(key))) {
            switch (key) {
                .w => player_velocity[2] = move_speed,
                .s => player_velocity[2] = -move_speed,
                .d => player_velocity[0] = move_speed,
                .a => player_velocity[0] = -move_speed,
                .space => player_velocity[1] = move_speed,
                .left_shift => player_velocity[1] = -move_speed,
            }
        }
    }
    game.state().pressed_keys = pressed_keys;

    try physics.set(player, .velocity, player_velocity);

    physics.schedule(.update);
    renderer.schedule(.render_frame);
}
