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
			
#		"SellButton":
#			DisplayServer.cursor_set_custom_image(sell_cursor)
#			sell_mode = true
#			menu.visible = false
#			done_btn.visible = true
#		"MoveButton":
#			move_mode = true
#			$Mesh.visible = true
#			DisplayServer.cursor_set_custom_image(move_cursor)
#			menu.visible = false
#			done_btn.visible = true
		"ResearchButton":
			pass
		"WorldMapButton":
			pass
		"InventoryButton":
			pass


func init_build_mode(type):
	$BuildButtons.visible = false
	$DoneButton.visible = false
	if type.name != "Expansion":
		Globals.state = State.BUILD
		SignalBus.build_mode_activated.emit(type.name, get_global_mouse_position())
#		get_parent().set_building_preview(type.name, get_global_mouse_position())
	else:
		get_parent().get_parent().get_node("Map").show_lands_for_sale()
		Globals.has_lands_preview = true
		$DoneButton.visible = true
		Globals.state = State.EXPANSE


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
	Globals.state = State.GAME
	DisplayServer.cursor_set_custom_image(default_cursor)
	$BuildButtons.visible = false
	$Menu.visible = true
	$DoneButton.visible = false
	$Dialog.visible = false
	var color_rect_array = get_parent().get_node("ColoredRectangles").get_children()
	if color_rect_array.size() > 0:
		for i in color_rect_array:
			i.queue_free()


