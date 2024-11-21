const zm = @import("zmath");

pub const Vertex = extern struct {
    pos: @Vector(3, f32),
};

pub const vertices = [_]Vertex{
    .{ .pos = .{ -100, 0, -100 } },
    .{ .pos = .{ -100, 0, 100 } },
    .{ .pos = .{ 100, 0, 100 } },
    .{ .pos = .{ 100, 0, 100 } },
    .{ .pos = .{ 100, 0, -100 } },
    .{ .pos = .{ -100, 0, -100 } },
};
