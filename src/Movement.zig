const std = @import("std");

const mach = @import("mach");
const zm = @import("zmath");

const Game = @import("App.zig");
const Physics = @import("Physics.zig");
const Renderer = @import("Renderer.zig");
const util = @import("util.zig");

pub const name = .movement;
pub const Mod = mach.Mod(@This());

pressed_keys: std.StaticBitSet(std.meta.fields(MoveKeys).len),

pub const systems = .{
    .init = .{ .handler = init },
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

fn init(
    movement: *Mod,
) !void {
    movement.init(.{
        .pressed_keys = std.StaticBitSet(std.meta.fields(MoveKeys).len).initEmpty(),
    });
}

fn update(
    core: *mach.Core.Mod,
    game: *Game.Mod,
    movement: *Mod,
    physics: *Physics.Mod,
    renderer: *Renderer.Mod,
) !void {
    const player: mach.EntityID = game.state().player;

    var pressed_keys = movement.state().pressed_keys;
    while (core.state().nextEvent()) |event| {
        switch (event) {
            .close => core.schedule(.exit), // Tell mach.Core to exit the app
            .key_press => |e| {
                switch (e.key) {
                    inline else => |key| {
                        if (@hasField(MoveKeys, @tagName(key))) {
                            pressed_keys.set(@intFromEnum(@field(
                                MoveKeys,
                                @tagName(key),
                            )));
                        }
                    },
                }
            },
            .key_release => |e| {
                switch (e.key) {
                    inline else => |key| {
                        if (@hasField(MoveKeys, @tagName(key))) {
                            pressed_keys.unset(@intFromEnum(@field(
                                MoveKeys,
                                @tagName(key),
                            )));
                        }
                    },
                }
            },
            else => {},
        }
    }

    var rotating_angles = Renderer.Rotation{ .vertical = 0, .horizontal = 0 };
    const rotation_speed = 0.003;
    var player_velocity = @Vector(3, f32){ 0, 0, 0 };
    const move_speed = 10;
    inline for (std.meta.fields(MoveKeys)) |field| {
        const key = @field(MoveKeys, field.name);
        if (pressed_keys.isSet(@intFromEnum(key))) {
            switch (key) {
                // Movement
                .w => player_velocity[2] += move_speed,
                .s => player_velocity[2] -= move_speed,
                .d => player_velocity[0] += move_speed,
                .a => player_velocity[0] -= move_speed,
                .space => player_velocity[1] += move_speed,
                .left_shift => player_velocity[1] -= move_speed,
                // Rotation
                .left => rotating_angles.horizontal += rotation_speed,
                .right => rotating_angles.horizontal -= rotation_speed,
                .up => rotating_angles.vertical += rotation_speed,
                .down => rotating_angles.vertical -= rotation_speed,
            }
        }
    }
    movement.state().pressed_keys = pressed_keys;

    const prev_rotation = renderer.get(player, .rotation).?;
    const new_rotation = Renderer.Rotation{
        .vertical = std.math.clamp(
            prev_rotation.vertical + rotating_angles.vertical,
            -std.math.pi / 2.0,
            std.math.pi / 2.0,
        ),
        .horizontal = prev_rotation.horizontal + rotating_angles.horizontal,
    };
    try renderer.set(player, .rotation, new_rotation);

    const rotate_matrix: zm.Mat = util.rotationToMat(new_rotation);
    const rotated_player_velocity = zm.mul(rotate_matrix, zm.Vec{
        player_velocity[0],
        player_velocity[1],
        player_velocity[2],
        1,
    });
    try physics.set(player, .velocity, .{
        rotated_player_velocity[0],
        rotated_player_velocity[1],
        rotated_player_velocity[2],
    });
}
