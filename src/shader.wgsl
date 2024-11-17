@binding(0) @group(0) var<uniform> mvp : mat4x4<f32>;

struct Output {
    @builtin(position) pos: vec4<f32>,
	@location(0) color: vec3<f32>,
};

@vertex fn vertex_main(
    @location(0) pos : vec3<f32>,
) -> Output {
	var output: Output;
	output.pos = mvp * vec4(pos, 1);
	output.color = pos;
    return output;
}

@fragment fn frag_main(@location(0) color: vec3<f32>) -> @location(0) vec4<f32> {
    return vec4(color, 1);
}
