extends Node2D
class_name TurretComponent

signal spawn_bullet(pos:Vector2, dir:float);
signal expire();

var enabled:bool = false;
@export var ammo:int = 12;
@export var reload:float = 0.3;
@export var fire_player:AudioStreamPlayer2D;
var on_cooldown:bool = false;
@onready var current_ammo:int = ammo;

func activate():
	current_ammo = ammo;
	on_cooldown = false;
	enabled = true;
	visible = true;

func deactivate():
	enabled = false;
	current_ammo = 0;
	on_cooldown = false;
	visible = false;

func fire():
	if not enabled or on_cooldown: return;

	spawn_bullet.emit(self.global_position, self.global_rotation);
	fire_player.play();

	current_ammo -= 1;
	if current_ammo <= 0:
		expire.emit();
		deactivate();
		return;

	on_cooldown = true;
	await get_tree().create_timer(reload).timeout;
	on_cooldown = false;