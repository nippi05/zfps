const zm = @import("zmath");
const Renderer = @import("Renderer.zig");

pub inline fn rotationToMat(rotation: Renderer.Rotation) zm.Mat {
    return zm.mul(zm.rotationY(rotation.horizontal), zm.rotationX(rotation.vertical));
}
