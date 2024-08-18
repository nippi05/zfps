const zm = @import("zmath");

pub const Vertex = extern struct {
    pos: zm.Vec,
};

pub const vertices = [_]Vertex{
    .{ .pos = .{ 0, 0, 0, 1 } },
    .{ .pos = .{ 0, 1, 0, 1 } },
    .{ .pos = .{ 1, 0, 0, 1 } },
    .{ .pos = .{ 1, 0, 0, 1 } },
    .{ .pos = .{ 0, 1, 0, 1 } },
    .{ .pos = .{ 1, 1, 0, 1 } },
};
