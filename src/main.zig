const std = @import("std");
const mach = @import("mach");

pub const modules = .{
    mach.Core,
    @import("App.zig"),
    @import("Movement.zig"),
    @import("Physics.zig"),
    @import("Renderer.zig"),
};

pub fn main() !void {
    const allocator = std.heap.c_allocator;
    try mach.mods.init(allocator);

    mach.mods.schedule(.app, .start);

    const stack_space = try allocator.alloc(u8, 8 * 1024 * 1024);
    try mach.mods.dispatch(stack_space, .{});
}
