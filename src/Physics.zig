const std = @import("std");

const mach = @import("mach");
const zm = @import("zmath");

pub const name = .physics;
pub const Mod = mach.Mod(@This());

timer: mach.time.Timer,

pub const components = .{
    .position = .{ .type = @Vector(3, f32) },
    .velocity = .{ .type = @Vector(3, f32) },
};

pub const systems = .{
    .init = .{ .handler = init },
    .update = .{ .handler = update },
};

fn init(physics: *Mod) !void {
    physics.init(.{
        .timer = try mach.time.Timer.start(),
    });
}

fn update(
    physics: *Mod,
    entities: *mach.Entities.Mod,
) !void {
    var q = try entities.query(.{
        .position = Mod.write(.position),
        .velocity = Mod.read(.velocity),
    });
    const dt: f32 = physics.state().timer.lap();
    while (q.next()) |v| {
        for (v.position, v.velocity) |*pos, vel| {
            pos.* += vel * zm.splat(@Vector(3, f32), dt);
        }
    }
}
