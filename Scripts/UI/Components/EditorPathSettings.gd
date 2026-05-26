extends VBoxContainer
class_name EditorActionSettings

# COMMON

@export var action_id: SpinBox;
@export var action_type: OptionButton;
@export var create_action_button: Button;
@export var delete_action_button: Button;

# MOVEMENT TYPE

@export_category("Movement")
@export var move_controls: Control;
@export var move_speed: SpinBox;
@export var move_looped: BaseButton;
@export var move_apply_rotation: BaseButton;
@export var move_steps: SpinBox;

# SPIN TYPE

@export_category("Spin")
@export var spin_controls: Control;
@export var spin_speed: SpinBox;
@export var spin_looped: BaseButton;
@export var spin_apply_rotation: BaseButton;
@export var spin_steps: SpinBox;
@export var spin_offset_by: SpinBox;
@export var spin_rotate_by: SpinBox;
@export var spin_apply_rotation_equally: BaseButton;

func _ready():
	action_type.item_selected.connect(_handle);
	action_id.value_changed.connect(_handle);

func _handle(_idx: int = 0):
	move_controls.hide();
	spin_controls.hide();
	if (action_id.value <= 0): return ;

	match action_type.selected:
		0:
			move_controls.show();
		1:
			spin_controls.show();