extends Node2D

@export var size:Vector2;
@export var cell_width:float = 6;
@export var cell_height:float = 10;
@export var offset_x:float = 0;
@export var offset_y:float = 0;
@export var color:Color = Color(1, 1, 1, .3);
@export var line_width:float = 1;
@export var skip_x:float = 1#cell_height;
@export var skip_y:float = 1#cell_width;

func _draw():
	var top = position.y;
	var bottom = position.y + size.y;
	var left = position.x
	var right = position.x + size.x;
	var x_distance = cell_width * skip_x;
	for i in range(0, size.x / x_distance):
		var x = offset_x - 1 + (x_distance * i) + x_distance;
		draw_line(Vector2(x, top), Vector2(x, bottom), color, line_width, true);
	
	var y_distance = cell_height * skip_y;
	for i in range(0, size.y / y_distance):
		var y = offset_y + (y_distance * i) + y_distance;
		draw_line(Vector2(left, y), Vector2(right, y), color, line_width, true);

	draw_line(Vector2(left, top), Vector2(left, bottom), color, line_width, true);
	draw_line(Vector2(left, top), Vector2(right, top), color, line_width, true);
	draw_line(Vector2(right, top), Vector2(right, bottom), color, line_width, true);
	draw_line(Vector2(left, bottom), Vector2(right, bottom), color, line_width, true);