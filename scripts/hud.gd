extends Control


var sell_cursor
var move_cursor
var default_cursor



func _ready() -> void:
	for btn in get_tree().get_nodes_in_group("menu_buttons"):
		btn.pressed.connect(init_menu_mode.bind(btn))
	
	for btn in get_tree().get_nodes_in_group("build_buttons"):
		btn.pressed.connect(init_build_mode.bind(btn))
	
	default_cursor = load("res://assets/ui/default_cursor_32.png")
	move_cursor = load("res://assets/ui/move_cursor_32.png")
	sell_cursor = load("res://assets/ui/sell_cursor_32.png")
	DisplayServer.cursor_set_custom_image(default_cursor)
	


func init_menu_mode(btn):
	match btn.name:
		"BuilderButton":
			$BuildButtons.visible = true
			$Menu.visible = false
			$DoneButton.visible = true
			
		"MoveButton":
			Globals.move_mode = true
			$DoneButton.visible = true
			$Menu.visible = false
			DisplayServer.cursor_set_custom_image(move_cursor)
			
		"SellButton":
			Globals.sell_mode = true
			$DoneButton.visible = true
			$Menu.visible = false
			DisplayServer.cursor_set_custom_image(sell_cursor)
			
		"ResearchButton":
			pass
		"WorldMapButton":
			pass
		"InventoryButton":
			pass


func init_build_mode(type):
	$BuildButtons.visible = false
	$DoneButton.visible = false
	Globals.build_mode = true
	if type.name != "Expansion":
		SignalBus.build_mode_activated.emit(type.name, get_global_mouse_position())
#		get_parent().set_building_preview(type.name, get_global_mouse_position())
	else:
		get_parent().get_parent().get_node("Map").show_lands_for_sale()
		Globals.has_lands_preview = true
		$DoneButton.visible = true
		Globals.build_mode = false
		Globals.expanse_mode = true


func connect_dialog_buttons(b_dict,func_name):
	for btn in get_tree().get_nodes_in_group("dialog_buttons"):
		if !btn.pressed.is_connected(func_name):
			btn.pressed.connect(func_name.bind(btn.name,b_dict))


func disconnect_dialog_buttons(func_name):
#	print(func_name)
	if func_name != null:
		for btn in get_tree().get_nodes_in_group("dialog_buttons"):
			if btn.pressed.is_connected(func_name):
				btn.pressed.disconnect(func_name)

func _on_done_button_pressed() -> void:
	
	if Globals.has_lands_preview:
		for l in get_parent().get_node("LandPreviews").get_children():
			l.queue_free()
	get_parent().get_parent().get_node("Map/Base").modulate = Color(1,1,1,1)
	Globals.has_lands_preview = false
	get_parent().modulate_ui(Color(1,1,1,1))
	Globals.has_painted_building = false
	get_parent().get_parent().get_node("Map/Cells").visible = false
	
	Globals.build_mode = false
	Globals.sell_mode = false
	Globals.move_mode = false
	Globals.drag_mode = false
	Globals.expanse_mode = false
	
	DisplayServer.cursor_set_custom_image(default_cursor)
	$BuildButtons.visible = false
	$Menu.visible = true
	$DoneButton.visible = false
	$Dialog.visible = false
	var color_rect_array = get_parent().get_node("ColoredRectangles").get_children()
	if color_rect_array.size() > 0:
		for i in color_rect_array:
			i.queue_free()


