const std = @import("std");
const zm = @import("zmath");
const mach = @import("mach");

pub const name = .physics;
pub const Mod = mach.Mod(@This());

timer: mach.Timer,

pub const components = .{
    .position = .{ .type = @Vector(3, f32) },
    .rotation = .{ .type = zm.Quat },
    .velocity = .{ .type = @Vector(3, f32) },
};

pub const systems = .{
    .init = .{ .handler = init },
    .update = .{ .handler = update },
};

fn init(physics: *Mod) !void {
    physics.init(.{
        .timer = try mach.Timer.start(),
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
