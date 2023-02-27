extends Node2D

var is_first_time = true
var file_manager: FileManager = FileManager.new()
#var state = State.GAME
var build_type: String
var build_location
var place_valid: bool

func _ready() -> void:
	
	Globals.state = State.GAME
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
#	print(Globals.state)
	if Globals.state == State.BUILD:
		$Map.update_building_preview()

func _unhandled_input(event: InputEvent) -> void:
	if Globals.state == State.BUILD:
		if event.is_action_released("ui_accept"):
#			prepare_to_place_dict()
			$Map.place_building()
			if build_type != "Road":
				cancel_build_mode()
				$Map/Base.modulate = Color(1,1,1,1)
		if event.is_action_released("ui_cancel"):
			cancel_build_mode()
			$Map/Base.modulate = Color(1,1,1,1)
	if Globals.state == State.EXPANSE:
		if event.is_action_released("ui_accept"):
			if !Globals.has_painted_building:
				$Map.choose_expansion_land()






func cancel_build_mode():
	$Map/Cells.visible = false
	place_valid = false
	Globals.state = State.GAME
	get_node("UI/BuildingPreview").queue_free()
	$UI/HUD/BuildButtons.visible = true
	$UI/HUD/DoneButton.visible = true



func _set_build_type(_type,_pos):
	build_type = _type
	print(build_type)
#	$Map/Cells.visible = true


#func cell_legal_to_place(cell: Vector2i) -> bool:
#	return $Map/Land.get_used_cells(0).has(cell) and $Map/Land.get_cell_source_id(0, cell) == 0


func load_config():
	var content = file_manager.load_from_file("config")
	if content == "not_first_time":
		is_first_time = false
