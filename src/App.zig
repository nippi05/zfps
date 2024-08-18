const std = @import("std");
const mach = @import("mach");
const zm = @import("zmath");

const Renderer = @import("Renderer.zig");

pub const name = .app;
pub const Mod = mach.Mod(@This());

pub const systems = .{
    .init = .{ .handler = init },
    .deinit = .{ .handler = deinit },
    .update = .{ .handler = update },
};

title_timer: mach.Timer,

pub fn deinit(game: *Mod, renderer: *Renderer.Mod) void {
    _ = game; // autofix
    renderer.schedule(.deinit);
}

fn init(game: *Mod, renderer: *Renderer.Mod) !void {
    renderer.schedule(.init);

    // Store our render pipeline in our module's state, so we can access it later on.
    game.init(.{
        .title_timer = try mach.Timer.start(),
    });
}

fn update(core: *mach.Core.Mod, game: *Mod, renderer: *Renderer.Mod) !void {
    var iter = core.state().pollEvents();
    while (iter.next()) |event| {
        switch (event) {
            .close => core.schedule(.exit), // Tell mach.Core to exit the app
            else => {},
        }
    }

    // update the window title every second
    if (game.state().title_timer.read() >= 1.0) {
        game.state().title_timer.reset();
        try updateWindowTitle(core);
    }

    renderer.schedule(.render_frame);
}

fn updateWindowTitle(core: *mach.Core.Mod) !void {
    try core.state().printTitle(
        core.state().main_window,
        "core-custom-entrypoint [ {d}fps ] [ Input {d}hz ]",
        .{
            // TODO(Core)
            core.state().frameRate(),
            core.state().inputRate(),
        },
    );
}
