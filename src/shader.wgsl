@binding(0) @group(0) var<uniform> mvp : mat4x4<f32>;

@vertex fn vertex_main(
    @location(0) pos : vec3<f32>,
) -> @builtin(position) vec4<f32> {
    return mvp * vec4<f32>(pos, 1);
}

@fragment fn frag_main() -> @location(0) vec4<f32> {
    return vec4<f32>(1.0, 0.0, 0.0, 1.0);
}