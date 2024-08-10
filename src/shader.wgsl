@binding(0) @group(0) var<uniform> mvp : mat4x4<f32>;

@vertex fn vertex_main(
    @builtin(vertex_index) VertexIndex: u32
) -> @builtin(position) vec4<f32> {
    var pos = array<vec4<f32>, 3>(
        vec4<f32>(0.0, 0.5, 0.0, 1.0),
        vec4<f32>(-0.5, -0.5, 0.0, 1.0),
        vec4<f32>(0.5, -0.5, 0.0, 1.0)
    );
    return mvp * pos[VertexIndex];
}

@fragment fn frag_main() -> @location(0) vec4<f32> {
    return vec4<f32>(1.0, 0.0, 0.0, 1.0);
}