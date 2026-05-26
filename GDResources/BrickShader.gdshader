shader_type canvas_item;

const float EPSILON = 1e-10;

uniform int color_count: hint_range(0, 4, 1) = 0;
uniform vec4 target_color1: source_color = vec4(1,1,1,1);
uniform vec4 target_color2: source_color = vec4(1,1,1,1);
uniform vec4 target_color3: source_color = vec4(1,1,1,1);
uniform vec4 target_color4: source_color = vec4(1,1,1,1);
uniform float brightness : hint_range(-1, 1) = 0;
uniform vec4 modulate: source_color = vec4(1,1,1,1);

mat4 brightnessMatrix( float _brightness ){
    return mat4( vec4(1, 0, 0, 0),
                 vec4(0, 1, 0, 0),
                 vec4(0, 0, 1, 0),
                 vec4(_brightness, _brightness, _brightness, 1));
}
// My own design
float rgb2hue(vec3 c) {
	float maxc = max(max(c.r, c.g), c.b);
	float minc = min(min(c.r, c.g), c.b);
	if (minc == maxc) return 0.;

	float hue = 0.;
	if (c.r == maxc) {
		hue = (c.g - c.b) / (maxc-minc);
	} else if (c.g == maxc) {
		hue = 2.+ (c.b - c.r) / (maxc-minc);
	} else {
		hue = 4.+ (c.r - c.g) / (maxc-minc);
	}
	hue = mod(hue, 6);
	if (hue < 0.) hue = hue + 1.;
	return hue / 6.;
}
// https://www.shadertoy.com/view/wt23Rt
vec3 hue2rgb(float hue){
	hue=fract(hue);
	return clamp(vec3(
		abs(hue*6.-3.)-1.,
		2.-abs(hue*6.-2.),
		2.-abs(hue*6.-4.)
	), 0., 1.);
}
vec3 hsl2rgb(vec3 hsl){
	if(hsl.y==0.){
		return vec3(hsl.z); //Luminance.
	}else{
		float b;
		if(hsl.z<.5){
			b=hsl.z*(1.+hsl.y);
		}else{
			b=hsl.z+hsl.y-hsl.y*hsl.z;
		}
		float a=2.*hsl.z-b;
		return a+hue2rgb(hsl.x)*(b-a);
		/*vec3(
			hueRamp(a,b,hsl.x+(1./3.)),
			hueRamp(a,b,hsl.x),
			hueRamp(a,b,hsl.x-(1./3.))
		);*/
	}
}
vec3 rgb2hsl(vec3 c){
	float cMin=min(min(c.r,c.g),c.b),
	      cMax=max(max(c.r,c.g),c.b),
	      delta=cMax-cMin;
	vec3 hsl=vec3(0.,0.,(cMax+cMin)/2.);
	if(delta!=0.0){ //If it has chroma and isn't gray.
		if(hsl.z<.5){
			hsl.y=delta/(cMax+cMin); //Saturation.
		}else{
			hsl.y=delta/(2.-cMax-cMin); //Saturation.
		}
		float deltaR=(((cMax-c.r)/6.)+(delta/2.))/delta,
		      deltaG=(((cMax-c.g)/6.)+(delta/2.))/delta,
		      deltaB=(((cMax-c.b)/6.)+(delta/2.))/delta;
		//Hue.
		if(c.r==cMax){
			hsl.x=deltaB-deltaG;
		}else if(c.g==cMax){
			hsl.x=(1./3.)+deltaR-deltaB;
		}else{ //if(c.b==cMax){
			hsl.x=(2./3.)+deltaG-deltaR;
		}
		hsl.x=fract(hsl.x);
	}
	return hsl;
}

vec3 shift_hsl(vec3 source, vec3 from, vec3 to) {
	float hue = to.x;
	float sat = to.y;
	float lum = to.z;

	// Interpolate hue with the nearest predefined gradient colour.
	float hue_interval = 1. / float(color_count);
	vec3 nearest_src = from;
	vec3 nearest_hue = to;
	float smallest_distance = 1.;

	// Find nearest source colour (that isn't current) and corresponding user colour.
	bool source_accounted_for = false;
	for (int i = 0; i < color_count; i++) {
		float hue_i = hue_interval * float(i);
		float dx = abs(hue_i - source.x);
		if (dx > 0.5) dx = 1. - dx;

		//if ((hue_i == from.x && source_accounted_for == true) ||
		if( (hue_i != from.x && dx < smallest_distance)) {
			smallest_distance = dx;
			nearest_src = vec3(hue_i, 1.0, 0.5);
			switch (i) {
				case 0:
					nearest_hue = rgb2hsl(target_color1.rgb);
					break;
				case 1:
					nearest_hue = rgb2hsl(target_color2.rgb);
					break;
				case 2:
					nearest_hue = rgb2hsl(target_color3.rgb);
					break;
				case 3:
					nearest_hue = rgb2hsl(target_color4.rgb);
					break;
			}
		}
		if (hue_i == from.x) {
			//source_accounted_for = true;
		}
	}

	// Interpolate new hue gradient.
	float dxFromSrc = abs(from.x - source.x);
	float dxSrc = abs(from.x - nearest_src.x);
	float dxHue = abs(to.x - nearest_hue.x);
	dxFromSrc = 0.5 - abs(dxFromSrc - 0.5);
	dxSrc = 0.5 - abs(dxSrc - 0.5);
	dxHue = 0.5 - abs(dxHue - 0.5);

	if (dxSrc != 0.) {
		// Multi-hue gradients
		float dirHue = sign(mod((nearest_hue.x - to.x + 0.5), 1.) - 0.5);
		float weight = (dxFromSrc / dxSrc);
		hue = to.x + (dxHue * weight * dirHue);

		// Interpolate saturation towards grayscale (0) the higher/lower the luminescence (from half / pure colour).
		float satDelta = (nearest_hue.y - to.y);
		sat = to.y + (satDelta * weight);

		// Luminescense is interpolated such that the middle band is replaced with the
		// user colour 1:1, while also applying shades/highlights as it strays towards black/white.
		float lumDelta = (nearest_hue.z - to.z);
		lum = to.z + (lumDelta * weight);
	} else {
		// Single-hue gradients
		sat = mix(0., sat, (0.5 - abs(to.z - 0.5)) * 2.);
	}
	sat = sat * source.y;
	lum = lum * source.z * 2.;

	return vec3(hue, sat, lum);
}

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	vec3 hsl_src = rgb2hsl(tex.rgb);
	float threshold = 1.0 / (float(color_count) * 2.0);

	/**
	* The base texture is expected to be composed of <color_count> colours, which may form gradients flowing
	* into eachother, if so desired. For example, a texture of 2 colours would be made of red and cyan (0 and 0.5 hue).
	* A texture of 3 colours (such as the gradient used) should be made out of red, green and blue (0, 0.33 and 0.66).
	* These are then remapped to the respective user colours.
	*/
	for (int i = 0; i < color_count; i++) {
		vec3 hsl_i = vec3((1.0 / float(color_count)) * float(i) , 1.0, .5);

		if (min(abs(hsl_src.x - hsl_i.x), 1.0 - abs(hsl_src.x - hsl_i.x)) <= threshold) {
			if (i == 0) {
				//tex.rgb = hsv2rgb(hsv_src * rgb2hsv(target_color1.rgb));
				tex.rgb = hsl2rgb(shift_hsl(hsl_src, hsl_i, rgb2hsl(target_color1.rgb)));
			}
			if (i == 1) {
				tex.rgb = hsl2rgb(shift_hsl(hsl_src, hsl_i, rgb2hsl(target_color2.rgb)));
			}
			if (i == 2) {
				tex.rgb = hsl2rgb(shift_hsl(hsl_src, hsl_i, rgb2hsl(target_color3.rgb)));
			}
			if (i == 3) {
				tex.rgb = hsl2rgb(shift_hsl(hsl_src, hsl_i, rgb2hsl(target_color4.rgb)));
			}
		}
	}
	COLOR = tex * brightnessMatrix( brightness ) * modulate;
}