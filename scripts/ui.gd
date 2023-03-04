extends CanvasLayer

var map_node

func _ready() -> void:
	map_node = get_parent().get_node("Map")
	SignalBus.build_mode_activated.connect(_set_building_preview)


func _set_building_preview(build_type, preview_position):
	var building_instance = load("res://scenes/previews/" + build_type.to_lower() + ".tscn").instantiate()
	building_instance.name = "BuildingInstance"
	var control = Control.new()
	control.add_child(building_instance, true)
	control.position = preview_position
	control.name = "BuildingPreview"
	add_child(control, true)
	move_child(get_node("BuildingPreview"), 0)


func set_lands_for_sale_preview(build_type, preview_position):
	var building_instance = load("res://scenes/previews/" + build_type.to_lower() + ".tscn").instantiate()
	var control = Control.new()
	control.add_child(building_instance,true)
	control.position = preview_position
	control.name = "LandPreview"
	$LandPreviews.add_child(control, true)
#	move_child(get_node("LandPreview"), 0)

func update_building_preview(new_pos, color):
	get_node("BuildingPreview").position = new_pos
	get_node("BuildingPreview/BuildingInstance").modulate = Color(color)

func show_sell_dialog(array,dict):
	$HUD/Dialog/VBoxContainer/Label.text = "Sell "+ dict["type"]+"?"
	paint_building(array,Color(1,0,0,0.7))
	modulate_ui(Color(1,1,1,0.3))
	get_node("HUD/Dialog").visible = true
	var callable = Callable(map_node,"erase_building")
	get_node("HUD").connect_dialog_buttons(dict,callable)

func show_expansion_dialog(array,rect_pos):
	$HUD/Dialog/VBoxContainer/Label.text = "Buy Expansion?"
	paint_building(array,Color(0,0,1,0.5))
	modulate_ui(Color(1,1,1,0.4))
	get_node("HUD/Dialog").visible = true
	var callable = Callable(map_node,"buy_expansion")
	get_node("HUD").connect_dialog_buttons({"position": rect_pos},callable)

func modulate_ui(c):
#	var c = Color(1,1,1,0.4)
	map_node.modulate = c
	$LandPreviews.modulate = c
	$ColoredRectangles.modulate = c

func desactivate_dialog_btns():
	get_node("HUD/Dialog").visible = false
	modulate_ui(Color(1,1,1,1))
	var color_rect_array = $ColoredRectangles.get_children()
	if color_rect_array.size() > 0:
		for i in color_rect_array:
			i.queue_free()
	if Globals.has_painted_building:
		Globals.has_painted_building = false

	var c = null
	if Globals.sell_mode:
		c = Callable(map_node,"erase_building")
	if Globals.expanse_mode:
		c = Callable(map_node,"buy_expansion")

	get_node("HUD").disconnect_dialog_buttons(c)



func paint_building(rects_array: Array, color):
	for cell in rects_array:
		var cr = ColorRect.new()
		cr.size = Vector2i(32,32)
		cr.position = cell * 32
		cr.modulate = color
		cr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		$ColoredRectangles.add_child(cr)
	Globals.has_painted_building = true
