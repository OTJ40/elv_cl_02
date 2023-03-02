extends Node2D

var is_first_time = true
var file_manager: FileManager = FileManager.new()
#var state = State.GAME
var build_type: String
var build_location
#var place_valid: bool

func _ready() -> void:
	Globals.build_mode = false
	Globals.sell_mode = false
	Globals.move_mode = false
	Globals.drag_mode = false
	Globals.expanse_mode = false
	Globals.has_lands_preview = false
	Globals.has_painted_building = false
	load_config()
	
	if is_first_time:
		$Map.build_main_hall()
	else:
		$Map.load_from_buildings_data_file()
	$Map.update_map()
	
	SignalBus.build_mode_activated.connect(_set_build_type)
	


func _process(_delta: float) -> void:
#	print(Globals.state,Globals.has_lands_preview,Globals.has_painted_building)
#	print(Globals.build_mode,Globals.move_mode,Globals.drag_mode,Globals.expanse_mode)
	if Globals.build_mode or Globals.drag_mode:
		$Map.update_building_preview()

func _unhandled_input(event: InputEvent) -> void:
	
	if Globals.build_mode:
		if event.is_action_released("ui_accept"):
			$Map.place_building()
			if build_type != "Road":
				cancel_build_mode()
				$Map/Base.modulate = Color(1,1,1,1)
		if event.is_action_released("ui_cancel"):
			cancel_build_mode()
			$Map/Base.modulate = Color(1,1,1,1)
	
	if Globals.expanse_mode:
		if event.is_action_released("ui_accept"):
			if !Globals.has_painted_building:
				$Map.choose_expansion_land()
	
	if Globals.move_mode:
#		Globals.has_painted_building = true
		if !Globals.has_lands_preview:
			$Map.show_lands_for_sale()
			Globals.has_lands_preview = true
		if event.is_action_released("ui_accept"):
			$Map.move_or_expanse()
	
	if Globals.drag_mode:
		Globals.move_mode = false
		if event.is_action_released("ui_accept"):
			$Map.place_building()
#			cancel_drag_mode()
		
	
	if Globals.sell_mode:
		if event.is_action_released("ui_accept"):
			if !Globals.has_painted_building:
				$Map.selling_building()

func cancel_drag_mode():
	Globals.drag_mode = false
	Globals.move_mode = true
	$Map/Cells.visible = false
	$UI/HUD/DoneButton.visible = true
	get_node("UI/BuildingPreview").queue_free()


func cancel_build_mode():
	$Map/Cells.visible = false
#	place_valid = false
	Globals.build_mode = false
	get_node("UI/BuildingPreview").queue_free()
	$UI/HUD/BuildButtons.visible = true
	$UI/HUD/DoneButton.visible = true



func _set_build_type(_type,_pos):
	build_type = _type
	print(build_type)
#	$Map/Cells.visible = true




func load_config():
	var content = file_manager.load_from_file("config")
	if content == "not_first_time":
		is_first_time = false
