const std = @import("std");

const mach = @import("mach");
const zm = @import("zmath");

const Game = @import("App.zig");
const Physics = @import("Physics.zig");
const Renderer = @import("Renderer.zig");

pub const name = .movement;
pub const Mod = mach.Mod(@This());

pressed_keys: std.StaticBitSet(std.meta.fields(MoveKeys).len),
delta_timer: mach.time.Timer,

pub const systems = .{
    .init = .{ .handler = init },
    .update = .{ .handler = update },
};

const MoveKeys = enum {
    q,
    w,
    e,
    r,
    f,
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
        .delta_timer = try mach.time.Timer.start(),
    });
}

fn update(
    core: *mach.Core.Mod,
    movement: *Mod,
    renderer: *Renderer.Mod,
    physics: *Physics.Mod,
    entities: *mach.Entities.Mod,
) !void {
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
            .mouse_press => |mouse_event| {
                std.log.debug("Mouse button pressed: {}", .{mouse_event});
            },
            else => {},
        }
    }

    var camera = renderer.state().camera;
    const camera_speed = 1;
    const delta_time = movement.state().delta_timer.lap();
    inline for (std.meta.fields(MoveKeys)) |field| {
        const key = @field(MoveKeys, field.name);
        if (pressed_keys.isSet(@intFromEnum(key))) {
            switch (key) {
                // camera
                .left => {
                    camera.position.x -= delta_time * camera_speed;
                },
                .right => camera.position.x += delta_time * camera_speed,
                .up => camera.position.z += delta_time * camera_speed,
                .down => camera.position.z -= delta_time * camera_speed,

                // center camrea on champion
                .space => {
                    camera.position.x = 0;
                    camera.position.z = 0;
                },

                .q => {
                    const projectile = try entities.new();

                    try physics.set(projectile, .position, .{ 0, 0.5, 0 });
                    try physics.set(projectile, .velocity, .{ 1, 0, 1 });
                },
                // Abilities
                else => {}, // TOOD: handle these events
            }
        }
    }
    renderer.state().camera = camera;
    movement.state().pressed_keys = pressed_keys;
}
