shader_type canvas_item;

uniform int color_count: hint_range(0, 4, 1);
uniform vec4 target_color1: source_color;
uniform vec4 target_color2: source_color;
uniform vec4 target_color3: source_color;
uniform vec4 target_color4: source_color;
uniform float brightness : hint_range(-1, 1) = 0;

mat4 brightnessMatrix( float _brightness ) {
    return mat4( vec4(1, 0, 0, 0),
                 vec4(0, 1, 0, 0),
                 vec4(0, 0, 1, 0),
                 vec4(_brightness, _brightness, _brightness, 1));
}

vec3 rgb2hsv(vec3 c) {
    vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
    vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));

    float d = q.x - min(q.w, q.y);
    float e = 1.0e-10;
    return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}
vec3 hsv2rgb(vec3 c) {
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

// All arguments are HSV
vec3 shift_hsv(vec3 source, vec3 from, vec3 to) {
	vec3 hsv_shift = to - from;
	return source + hsv_shift;
}

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	vec3 hsv_src = rgb2hsv(tex.rgb);
	float threshold = 1.0 / (float(color_count) * 2.0);

	for (int i = 1; i <= color_count; i++) {
		vec3 hsv_i = vec3((1.0 / float(color_count)) * float(i - 1) , 1.0, 1.0);

		if (min(abs(hsv_src.r - hsv_i.r), 1.0 - abs(hsv_src.r - hsv_i.r)) <= threshold) {
			if (i == 1) {
				//tex.rgb = hsv2rgb(hsv_src * rgb2hsv(target_color1.rgb));
				tex.rgb = hsv2rgb(shift_hsv(hsv_src, hsv_i, rgb2hsv(target_color1.rgb)));
			}
			if (i == 2) {
				tex.rgb = hsv2rgb(shift_hsv(hsv_src, hsv_i, rgb2hsv(target_color2.rgb)));
			}
			if (i == 3) {
				tex.rgb = hsv2rgb(shift_hsv(hsv_src, hsv_i, rgb2hsv(target_color3.rgb)));
			}
			if (i == 4) {
				tex.rgb = hsv2rgb(shift_hsv(hsv_src, hsv_i, rgb2hsv(target_color4.rgb)));
			}
		}
	}
	COLOR = tex * brightnessMatrix( brightness );
}