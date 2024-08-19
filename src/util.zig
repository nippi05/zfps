const zm = @import("zmath");

pub inline fn rotationToMat(rotation: @Vector(2, f32)) zm.Mat {
    return zm.mul(zm.rotationY(rotation[1]), zm.rotationX(rotation[0]));
}
