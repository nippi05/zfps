const zm = @import("zmath");

pub const Vertex = extern struct {
    pos: @Vector(3, f32),
};

pub const vertices = [_]Vertex{
    .{ .pos = .{ 0, 0, 0 } },
    .{ .pos = .{ 0, 1, 0 } },
    .{ .pos = .{ 1, 0, 0 } },
    .{ .pos = .{ 1, 0, 0 } },
    .{ .pos = .{ 0, 1, 0 } },
    .{ .pos = .{ 1, 1, 0 } },
};
