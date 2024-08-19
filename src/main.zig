const std = @import("std");
const mach = @import("mach");

pub const modules = .{
    mach.Core,
    @import("App.zig"),
    @import("Renderer.zig"),
    @import("Physics.zig"),
    @import("Movement.zig"),
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.debug.assert(gpa.deinit() == .ok);
    const allocator = gpa.allocator();

    var app = try mach.App.init(allocator, .app);
    defer app.deinit(allocator);
    try app.run(.{ .allocator = allocator });
}
