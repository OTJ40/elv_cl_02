extends Node2D

class_name Map


enum LAND_TYPE {
	GRASS
}


var file_manager: FileManager = FileManager.new()
var is_first_time: bool = true
var own_lands_array: Array = []
var for_sale_lands_array = []
var buildings_data_array: Array = []
var build_type: String
var build_location: Vector2i
var place_valid: bool
var ui
var item_to_move = {}


func _ready() -> void:
	ui = get_parent().get_node("UI")
	SignalBus.build_mode_activated.connect(_set_build_state)

#func _process(delta: float) -> void:
#	print(place_valid)


func get_neighbors_for_position(pos) -> Array:
	var result = []
	for dir in Globals.directions:
		result.append(pos+dir)
	return result



func has_point_in_for_sale_lands(point: Vector2i) -> bool:
	for pos in for_sale_lands_array:
		if Rect2i(pos,Vector2i(5,5)).has_point(point):
			return true
	return false


func get_base_pos_of_rect_for_sale(point: Vector2i):
	for pos in for_sale_lands_array:
		if Rect2i(pos,Vector2i(5,5)).has_point(point):
#			print(pos,222)
			return pos

func _set_build_state(_type,_pos):
	build_type = _type
#	print(build_type)
	$Cells.visible = true
	$Base.modulate = Color(1,1,1,0.5)


func build_main_hall():
	own_lands_array = [
	Vector2i(15, 0),
	Vector2i(20, 0),
	Vector2i(20, 5),
	Vector2i(15, 5),
	Vector2i(15, 10),
	Vector2i(20, 10)
	]
	var main_hall_dictionary = {}
	var main_hall_atlas = get_atlas_positions_array_from_dims(Vector2i(6,7),Vector2i(15,0)) # _get_atlas_array($Buildings.tile_set.get_source(BuildingType.MAIN_HALL))
	for cell in main_hall_atlas:
		$Buildings.set_cell(0,cell, BuildingType.MAIN_HALL,cell - Vector2i(15,0))
		
	main_hall_dictionary = {
				"id": str(Time.get_unix_time_from_system()).split(".")[0],
				"type": "Main_Hall",
				"base": Vector2i(15,0),
				"level": 1,
				"dims": Vector2i(6,7),
#				"atlas": main_hall_atlas,
				"connected": true,
				"last_coll": str(Time.get_unix_time_from_system()).split(".")[0]
			}
	buildings_data_array.append(main_hall_dictionary)
	
	var road_dictionary = {}
	road_dictionary = {
		"id": str(Time.get_unix_time_from_system() + 1).split(".")[0],
		"type": "Road",
		"base": Vector2i(17,7),
		"level": 1,
		"dims": Vector2i(1,1),
#		"atlas": [Vector2i(0,0)],
		"connected": true,
		"last_coll": 0
	}
	$Buildings.set_cells_terrain_connect(0,[Vector2i(17,7)],0,0,false)
	buildings_data_array.append(road_dictionary)
	
	file_manager.save_to_file("buildings_data",buildings_data_array)
	file_manager.save_to_file("lands_data",own_lands_array)
#	print_map_data()
	
	# change config
	file_manager.save_to_file("config","not_first_time")


func get_type_from_buildings_data_array(pos):
	for item in buildings_data_array:
		for cell in get_atlas_positions_array_from_dims(item["dims"],item["base"]):
			if cell == Vector2i(pos):
				return item["type"]


func get_atlas_positions_array_from_dims(dims,base) -> Array:
	var result = []
	for y in dims.y:
		for x in dims.x:
			result.append(base + Vector2i(x,y))
	return result

#func get_atlas_positions_array(atlas,base) -> Array:
#	var result = []
#	for cell in atlas:
#		result.append(cell + base)
#	return result

func update_building_preview():
	var current_cell = $Buildings.local_to_map(get_global_mouse_position())
	var current_cell_in_px = Vector2i($Buildings.map_to_local(current_cell))
	var atlas = _get_atlas_array($Buildings.tile_set.get_source(BuildingType[build_type.to_upper()])) if build_type != "Road" else [Vector2i(0,0)]
	var counter = 0
	for cell in atlas:
		if $Buildings.get_cell_source_id(0,current_cell + cell) == -1 and cell_legal_to_place(current_cell + cell):
			counter += 1
	if counter == atlas.size():
		ui.update_building_preview(current_cell_in_px,"33fd146b")
		place_valid = true
		build_location = current_cell
	else:
		ui.update_building_preview(current_cell_in_px,"f600039c")
		place_valid = false


func find_connected_to_place_b(building_dims):
	var connected: bool
	if build_type == "Road":
		connected = is_connected_R_for_position(build_location)
		if connected:
			change_connected_in_updated_road_tree(build_location,connected)
	else:
		for atlas_cell in get_atlas_positions_array_from_dims(building_dims,build_location):
			for n in get_neighbors_for_position(atlas_cell):
				if get_atlas_positions_array_from_dims(building_dims,build_location).has(n):
					continue
				else:
					if get_type_from_buildings_data_array(n) == "Road": # if building has neighbor road
						if is_connected_R_for_position(n):              # and it is connected to mh
							connected = true                            # then building is connected
		if !connected:
			connected = false
	return connected


func place_building():
	if place_valid:
		if Globals.build_mode:
			# -1- prepare dictionary
			var dict = {}
#			var building_atlas = [Vector2i(0,0)] if build_type == "Road" else _get_atlas_array($Buildings.tile_set.get_source(BuildingType[build_type.to_upper()]))
			var dims = Vector2i(1,1) if build_type == "Road" else Vector2i(2,2)
			var connected = find_connected_to_place_b(dims)
			dict = {
					"id": str(Time.get_unix_time_from_system()).split(".")[0],
					"type": build_type,
					"base": build_location,
					"level": 1,
					"dims": dims,
#					"atlas": building_atlas,
					"connected": connected,
					"last_coll": str(0) if build_type == "Road" else str(Time.get_unix_time_from_system()).split(".")[0]
				}
			# -2- place building
			if build_type == "Road":
				$Buildings.set_cells_terrain_connect(0,[build_location],0,0,false)
			else:
				for cell in get_atlas_positions_array_from_dims(dims,build_location):
					if connected:
						$Buildings.set_cell(0,cell,BuildingType[build_type.to_upper()],Vector2i(0,0)+cell)
					else:
						$Buildings.set_cell(0,cell,BuildingType[build_type.to_upper()]+2,Vector2i(0,0)+cell)
						
			# -3- save changes
			buildings_data_array.append(dict)
			file_manager.save_to_file("buildings_data", buildings_data_array)
		if Globals.drag_mode:
			# -1- prepare dictionary
			var dict = {}
#			var building_atlas = [Vector2i(0,0)] if build_type == "Road" else _get_atlas_array($Buildings.tile_set.get_source(BuildingType[build_type.to_upper()]))
			var connected
			if build_type == "Main_Hall":
				connected = true
			else:
				connected = find_connected_to_place_b(item_to_move["dims"])
			dict = {
					"id": item_to_move["id"],
					"type": build_type,
					"base": build_location,
					"level": item_to_move["level"],
					"dims": item_to_move["dims"],
#					"atlas": building_atlas,
					"connected": connected,
					"last_coll": item_to_move["last_coll"]
				}
			# -2- place building
			if build_type == "Road":
				$Buildings.set_cells_terrain_connect(0,[build_location],0,0,false)
			else:
				for atlas_cell in get_atlas_positions_array_from_dims(item_to_move["dims"],build_location):
					if connected:
						$Buildings.set_cell(0,atlas_cell,BuildingType[build_type.to_upper()],Vector2i(0,0) + atlas_cell)
					else:
						$Buildings.set_cell(0,atlas_cell,BuildingType[build_type.to_upper()] + 2,Vector2i(0,0) + atlas_cell)
			update_map()
			# -3- save changes
			if build_type == "Main_Hall":
				var base = build_location
				var dims = dict["dims"]
				for pos in get_atlas_positions_array_from_dims(dims,base):
					if pos.x - base.x == 0 or pos.y - base.y == 0 or pos.x - base.x + 1 == dims.x or pos.y - base.y + 1 == dims.y:
	#						print(pos)
						for n in get_neighbors_for_position(pos):
							if get_atlas_positions_array_from_dims(dims,base).has(n):
								continue
							else:
								if get_type_from_buildings_data_array(n) == "Road":
#									print(n)
									if !is_connected_R_for_position(n):
										change_connected_in_updated_road_tree(n, false)
									else:
										change_connected_in_updated_road_tree(n, true)
			
			buildings_data_array.append(dict)
			file_manager.save_to_file("buildings_data", buildings_data_array)
			update_map()
			place_valid = false
			get_parent().cancel_drag_mode()
		update_map()


func move_or_expanse():
	var current_cell = $Buildings.local_to_map(get_global_mouse_position())
	if $Buildings.get_used_cells(0).has(current_cell): # move
		
		for item in buildings_data_array:
			for position in get_atlas_positions_array_from_dims(item["dims"],item["base"]):
				if current_cell == position:
					item_to_move = item
#					print(item_to_move)
					Globals.move_mode = false
					Globals.drag_mode = true
#					ui.paint_building(get_atlas_positions_array_from_dims(item["dims"],item["base"]),Color(0,0,1,0.4))
					erase_building("Yes", item)
					ui._set_building_preview(item["type"],get_global_mouse_position())
					build_type = item["type"]
					$Cells.visible = true
		
	elif has_point_in_for_sale_lands(current_cell): # expanse
		Globals.expanse_mode = true
		var rect_for_sale = get_base_pos_of_rect_for_sale(current_cell)
		ui.show_expansion_dialog(get_atlas_positions_array_from_dims(Vector2i(5,5),rect_for_sale),rect_for_sale)

func change_connected_in_updated_road_tree(pos, bull):
	var road_tree = [pos]
	recursive_collecting_roads(pos, road_tree)
	var buis = []
	for road in road_tree:
		
		# roads
		for item in buildings_data_array:
			if road == item["base"]:
				item["connected"] = bull
		
		# buildings
#		check_neighbor_buildings_to_road_pos(road, bull)
#		check_neighbor_buildings_to_road_pos_2(road)
		
		for n in get_neighbors_for_position(road):
			if build_type_not_road_or_main_hall(n):
				for item in buildings_data_array:
					for cell in get_atlas_positions_array_from_dims(item["dims"],item["base"]):
						if cell == n:
							if !buis.has(item):
								buis.append(item)
	for b in buis:
		if qwer(b):
			b["connected"] = true
		else:
			b["connected"] = false
	
#	print(buis)
			
		
		

	file_manager.save_to_file("buildings_data",buildings_data_array)
	update_map()

func qwer(dict):
	for pos in get_atlas_positions_array_from_dims(dict["dims"],dict["base"]):
		var count_n = 0
		var max_count = dict["dims"].x * dict["dims"].y * 4
		for n in get_neighbors_for_position(pos):
			if get_atlas_positions_array_from_dims(dict["dims"],dict["base"]).has(n):
				count_n += 1
				continue
			elif get_type_from_buildings_data_array(n) != "Road":
				count_n += 1
			else:
				if get_type_from_buildings_data_array(n) == "Road":
					if is_connected_R_for_position(n):
						return true
					else:
						count_n += 1
			return false
#			prints(max_count,count_n)


func check_neighbor_buildings_to_road_pos_2(pos):
	var buis = []
	for n in get_neighbors_for_position(pos):
		if build_type_not_road_or_main_hall(n):
			for item in buildings_data_array:
				for cell in get_atlas_positions_array_from_dims(item["dims"],item["base"]):
					if cell == n:
						if !buis.has(item):
							buis.append(item)
	print(buis)

func check_neighbor_buildings_to_road_pos(pos, bull):
	for n in get_neighbors_for_position(pos):
		if build_type_not_road_or_main_hall(n):
			change_connected_in_buildings_data_array(n,bull)


func change_connected_in_buildings_data_array(pos,bull):
	for item in buildings_data_array:
		for tile in get_atlas_positions_array_from_dims(item["dims"],item["base"]):
			if pos == tile:
				item["connected"] = bull


func is_connected_R_for_position(pos) -> bool:
	var road_tree = [pos]
	recursive_collecting_roads(pos, road_tree)
	for road in road_tree:
		for n in get_neighbors_for_position(road):
			if get_type_from_buildings_data_array(n) == "Main_Hall":
				return true
	return false


func recursive_collecting_roads(pos, array):
	for n in get_neighbors_for_position(pos):
		if !array.has(n):
			if get_type_from_buildings_data_array(n) == "Road":
				array.append(n)
				recursive_collecting_roads(n, array)


func show_lands_for_sale():
	$Base.modulate = Color(1,1,1,0.5)
	$Cells.visible = true
	var all_lands = $Land.get_used_cells(0)
	for cell in all_lands:
		if cell.x % 5 == 0 and cell.y % 5 == 0:
			if !own_lands_array.has(cell):
				own_lands_array.append(cell)

	for_sale_lands_array.clear()
	for land_base in own_lands_array:
		for dir in Globals.directions:
			var cell = land_base + dir * 5
			if cell.x >= 0 and cell.x < 40 and cell.y >= 0 and cell.y < 30 and !own_lands_array.has(cell):
				if !for_sale_lands_array.has(cell):
					for_sale_lands_array.append(cell)

	for cell in for_sale_lands_array:
		ui.set_lands_for_sale_preview("expansion",cell * 32)


func selling_building():
	var current_tile = $Buildings.local_to_map(get_global_mouse_position())
	if $Buildings.get_cell_source_id(0, current_tile) == BuildingType.MAIN_HALL:
				print("You can`t!")
	else:
		if $Buildings.get_used_cells(0).has(current_tile):
			for item in buildings_data_array:
				for cell in item["atlas"]:
					if current_tile == cell + item["base"]:
						ui.show_sell_dialog(get_atlas_positions_array_from_dims(item["dims"],item["base"]),item)


func erase_building(btn_name, dict):
#	print(dict)
	if btn_name == "Yes":
		# if road for every neighbor find roadtree and check for connection to mh
		buildings_data_array.erase(dict)
		if dict["type"] == "Road":
			for n in get_neighbors_for_position(dict["base"]):
				if $Buildings.get_cell_source_id(0,n) == BuildingType.ROAD:
#					print(n)
					if !is_connected_R_for_position(n):
						# check all buildings along the roadtree
						change_connected_in_updated_road_tree(n, false)
						# NB - here check ALL neighbors to all neighbor buildings!!!
				elif build_type_not_road_or_main_hall(n):
					var building_dict = get_item_from_buildings_data_array_by_position(n)
					building_dict["connected"] = false
					
					for cell in get_atlas_positions_array_from_dims(building_dict["dims"],building_dict["base"]):
						for nei in get_neighbors_for_position(cell):
							if get_atlas_positions_array_from_dims(building_dict["dims"],building_dict["base"]).has(nei):
								continue
							else:
								if get_type_from_buildings_data_array(nei) == "Road":
									if is_connected_R_for_position(nei):
										building_dict["connected"] = true
					if !building_dict["connected"]:
						building_dict["connected"] = false
								# go round about the building to find if it has connection w road
		elif dict["type"] == "Main_Hall":
#			print(item_to_move)
			var base = item_to_move["base"]
			var dims = item_to_move["dims"]
			for pos in get_atlas_positions_array_from_dims(dict["dims"],dict["base"]):
				if pos.x - base.x == 0 or pos.y - base.y == 0 or pos.x - base.x + 1 == dims.x or pos.y - base.y + 1 == dims.y:
#					print(pos)
					for n in get_neighbors_for_position(pos):
						if get_atlas_positions_array_from_dims(dict["dims"],dict["base"]).has(n):
							continue
						else:
							if get_type_from_buildings_data_array(n) == "Road":
								if !is_connected_R_for_position(n):
									change_connected_in_updated_road_tree(n, false)
			update_map()
						
		
		file_manager.save_to_file("buildings_data", buildings_data_array)
		for cell in get_atlas_positions_array_from_dims(dict["dims"],dict["base"]):
			$Buildings.erase_cell(0, cell)
		update_map()
		ui.desactivate_dialog_btns()
	elif btn_name == "No":
		ui.desactivate_dialog_btns()


func get_item_from_buildings_data_array_by_position(pos) -> Dictionary:
	for item in buildings_data_array:
		for cell in get_atlas_positions_array_from_dims(item["dims"],item["base"]):
			if cell == pos:
				return item
	return {}


func choose_expansion_land():
	var current_tile = $Buildings.local_to_map(get_global_mouse_position())
	if has_point_in_for_sale_lands(current_tile):
		var rect_pos_for_sale = get_base_pos_of_rect_for_sale(current_tile)
		ui.show_expansion_dialog(get_atlas_positions_array_from_dims(Vector2i(5,5),rect_pos_for_sale),rect_pos_for_sale)

func buy_expansion(btn_name, dict):
#	print(dict)
	if btn_name == "Yes":
		$Land.set_pattern(0, dict["position"], $Land.tile_set.get_pattern(0))
		own_lands_array.append(dict["position"])
		file_manager.save_to_file("lands_data", own_lands_array)
		if Globals.has_lands_preview:
			for l in ui.get_node("LandPreviews").get_children():
				l.queue_free()
		show_lands_for_sale()
		ui.desactivate_dialog_btns()
	elif btn_name == "No":
		ui.desactivate_dialog_btns()



func load_from_buildings_data_file():
	
	var content: Array = file_manager.load_from_file("buildings_data") as Array
	buildings_data_array.clear()
	buildings_data_array.append_array(content)
	
	content = file_manager.load_from_file("lands_data") as Array
	own_lands_array.clear()
	own_lands_array.append_array(content)


func update_map():
	for land in own_lands_array:
		$Land.set_pattern(0, land, $Land.tile_set.get_pattern(0))
	
	var roads_array = []
	for item in buildings_data_array:
		if item["type"] == "Road":
			roads_array.append(item["base"])
		else:
			for cell in get_atlas_positions_array_from_dims(item["dims"],item["base"]):
				var sourse_id = BuildingType[item["type"].to_upper()] if item["connected"] else BuildingType[item["type"].to_upper()] + 2
				$Buildings.set_cell(0, cell, sourse_id, cell - item["base"])
				
#			for cell in entry["atlas"]:
	$Buildings.set_cells_terrain_connect(0, roads_array, 0, 0, false)


func cell_legal_to_place(cell: Vector2i) -> bool:
	return $Land.get_used_cells(0).has(cell) and $Land.get_cell_source_id(0, cell) == 0

func _get_atlas_array(atlas: TileSetAtlasSource) -> Array:
	var result = []
	var cells = atlas.get_atlas_grid_size()
	for cell in cells.x * cells.y:
		result.append(atlas.get_tile_id(cell))
	return result



func build_type_not_road_or_main_hall(pos : Vector2i) -> bool:
	return $Buildings.get_cell_source_id(0,pos) > 1


