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
    var gpa_implementation = std.heap.GeneralPurposeAllocator(.{}){};
    // defer std.debug.assert(gpa_implementation.deinit() == .ok);
    const gpa = gpa_implementation.allocator();

    try mach.mods.init(gpa);

    mach.mods.schedule(.app, .start);

    const stack_space = try gpa.alloc(u8, 8 * 1024 * 1024);
    try mach.mods.dispatch(stack_space, .{});
}
