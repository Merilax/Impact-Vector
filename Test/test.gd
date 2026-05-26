extends Node2D

var color_count = 1;
var c1 = Vector4(.5,.5,.5,1);
var c2 = Vector4(1,1,1,1);
var c3 = Vector4(1,1,1,1);
var c4 = Vector4(1,1,1,1);

func rgb2hsv(c:Vector3) -> Vector3:
	var K := Vector4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
	var p:Vector4 = lerp(Vector4(c.z, c.y, K.w, K.z), Vector4(c.y, c.z, K.x, K.y), 0 if c.y < c.z else 1);
	var q:Vector4 = lerp(Vector4(p.x, p.y, p.w, c.x), Vector4(c.x, p.y, p.z, p.x), 0 if c.x < p.x else 1);

	var d:float = q.x - min(q.w, q.y);
	var e := 1.0e-10;
	return Vector3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);

func hsv2rgb(c:Vector3) -> Vector3:
	var K := Vector4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
	var cxxx := Vector3(c.x,c.x,c.x);
	var Kxyz := Vector3(K.x,K.y,K.z);
	var Kwww := Vector3(K.w,K.w,K.w);
	var Kxxx := Vector3(K.x,K.x,K.x);
	var p:Vector3 = abs(((cxxx + Kxyz) - floor(cxxx + Kxyz)) * 6.0 - Kwww);
	return c.z * lerp(Kxxx, clamp(p - Kxxx, 0.0, 1.0), c.y);

func shift_hsv(source:Vector3, from:Vector3, to:Vector3) -> Vector3:
	var hsv_shift = to - from;
	return source + hsv_shift;

func _ready():
	var tex := Vector3(1, .5, .5);
	var hsv_src := rgb2hsv(tex);
	# var threshold := 1.0 / (float(color_count) * 2.0);

	# for i in range(color_count):
	# 	var hsv_i := Vector3((1.0 / float(color_count)) * float(i - 1) , 1.0, 1.0);

	# 	if (min(abs(hsv_src.x - hsv_i.x), 1.0 - abs(hsv_src.x - hsv_i.x)) <= threshold):
	# 		if (i == 1):
	# 			tex = hsv2rgb(shift_hsv(hsv_src, hsv_i, rgb2hsv(Vector3(c1.x,c1.y,c1.z))));
			
	# 		if (i == 2):
	# 			tex = hsv2rgb(shift_hsv(hsv_src, hsv_i, rgb2hsv(Vector3(c2.x,c2.y,c2.z))));
			
	# 		if (i == 3):
	# 			tex = hsv2rgb(shift_hsv(hsv_src, hsv_i, rgb2hsv(Vector3(c3.x,c3.y,c3.z))));
			
	# 		if (i == 4):
	# 			tex = hsv2rgb(shift_hsv(hsv_src, hsv_i, rgb2hsv(Vector3(c4.x,c4.y,c4.z))));
	
	var hsv_base := rgb2hsv(Vector3(1,0,0));
	var hsv_target := rgb2hsv(Vector3(c1.x, c1.y, c1.z));
	#print("RGB BASE  : ", Vector3(1,0,0));
	print("HSV BASE  : ", hsv_base);
	#print("RGB SOURCE: ", Vector3(1,0.5,0.5));
	print("HSV SOURCE: ", hsv_src);
	#print("RGB TARGET: ", Vector3(0.4,0.4,0.4));
	print("HSV TARGET: ", hsv_target);
	print("HSV SHIFT : ", hsv_target - hsv_base);
	print("HSV RESULT: ", hsv_src + (hsv_target - hsv_base));
