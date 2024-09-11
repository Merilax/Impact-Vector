extends Node2D
class_name HealthComponent

@export var health:int = 0
@export var signal_on_depleted:bool = true

signal health_depleted()

func damage(amount:int):
	health -= amount

	if health <= 0 and signal_on_depleted:
		health_depleted.emit()

func heal(amount:int):
	health += amount