extends Control

@export var page_container:Control
@export var exit:Button
@export var previous:Button
@export var next:Button
var current_page:int = 0;
var page_count:int = 0;
signal menu_closed();

func _ready():
	if not page_container: return;
	if exit: exit.pressed.connect(on_close_menu);
	if previous and next:
		previous.pressed.connect(goto.bind(-1));
		next.pressed.connect(goto.bind(1));

	page_count = page_container.get_child_count();

func goto(target:int):
	if (current_page + target >= page_count) or (current_page + target < 0): return;

	current_page += target;

	for page in page_container.get_children():
		page.hide();
	page_container.get_child(current_page).show();

func on_close_menu():
	menu_closed.emit();
	self.hide();