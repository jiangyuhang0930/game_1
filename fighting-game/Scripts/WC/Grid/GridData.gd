extends Node

class_name GridData


# ------------------------------------------------------------------
# Grid Data
# ------------------------------------------------------------------

# Map dimensions in cells.
var width: int = 0
var height: int = 0
# Top-left cell coordinate in the TileMap.
var origin: Vector2i

# 2D array storing all CellData instances.
var cells: Array[Array] = []


# ------------------------------------------------------------------
# TileMap References
# ------------------------------------------------------------------

# References to TileMap layers used to build the grid.
var ground_layer: TileMapLayer
var grass_layer: TileMapLayer
var obstacle_layer: TileMapLayer


# ------------------------------------------------------------------
# Public Methods
# ------------------------------------------------------------------

func initialize(
	ground: TileMapLayer,
	grass: TileMapLayer,
	obstacle: TileMapLayer
) -> void:

	# Cache TileMap references.
	ground_layer = ground
	grass_layer = grass
	obstacle_layer = obstacle

	# Build the grid data.
	_build_grid()


# ------------------------------------------------------------------
# Public Methods
# ------------------------------------------------------------------

func get_cell(row: int, col: int) -> CellData:
	return cells[row][col]


func is_inside(row: int, col: int) -> bool:
	return (
		row >= 0
		and row < height
		and col >= 0
		and col < width
	)
	
	
func map_to_row_col(map_position: Vector2i) -> Vector2i:
	return Vector2i(
		_map_to_row(map_position.y),
		_map_to_col(map_position.x)
	)


func has_cell(map_position: Vector2i) -> bool:

	var row_col := map_to_row_col(map_position)

	return is_inside(row_col.x, row_col.y)
	

func get_cell_from_map(map_position: Vector2i) -> CellData:

	var row_col := map_to_row_col(map_position)

	return get_cell(row_col.x, row_col.y)
	

func can_select(map_position: Vector2i) -> bool:

	if not has_cell(map_position):
		return false

	var cell := get_cell_from_map(map_position)

	return cell.object == null
	
	
func map_to_world(map_position: Vector2i) -> Vector2:
	return ground_layer.map_to_local(map_position)
	

# ------------------------------------------------------------------
# Private Methods
# ------------------------------------------------------------------

func _build_grid() -> void:
	# Get the occupied area of the ground layer.
	var used_rect := ground_layer.get_used_rect()

	# Store the map origin.
	origin = used_rect.position

	# Store the map dimensions.
	width = used_rect.size.x
	height = used_rect.size.y
	
	# print("Grid Size: ", width, " x ", height)
	
	# Create all CellData instances.
	_create_cells()
	
	# Load terrain data from TileMap.
	_load_terrain()
	
	# Load object data from TileMap.
	_load_objects()


func _create_cells() -> void:

	# Clear any previous grid data.
	cells.clear()

	# Create every row.
	for row in range(height):

		var row_cells: Array[CellData] = []

		# Create every column.
		for col in range(width):

			var cell := CellData.new()

			# Store grid coordinates.
			cell.row = row
			cell.col = col

			row_cells.append(cell)

		cells.append(row_cells)

	# Debug
	# print("Created ", cells.size(), " rows.")
	# print("First row contains ", cells[0].size(), " cells.")
	
	
func _map_to_row(map_y: int) -> int:
	return map_y - origin.y


func _map_to_col(map_x: int) -> int:
	return map_x - origin.x
	
	
func _load_terrain() -> void:

	# var grass_count := 0

	# Find every grass tile.
	for map_position in grass_layer.get_used_cells():

		var row := _map_to_row(map_position.y)
		var col := _map_to_col(map_position.x)

		cells[row][col].terrain = GrassData.new()

		# grass_count += 1

	# print("Loaded ", grass_count, " grass tiles.")
	

func _load_objects() -> void:

	# var object_count := 0

	for map_position in obstacle_layer.get_used_cells():

		var row := _map_to_row(map_position.y)
		var col := _map_to_col(map_position.x)

		# Check for duplicate objects.
		if cells[row][col].object != null:
			push_error("Multiple objects found on the same cell.")
			continue

		cells[row][col].object = GeneralObjectData.new()

		# object_count += 1

	# print("Loaded ", object_count, " objects.")
