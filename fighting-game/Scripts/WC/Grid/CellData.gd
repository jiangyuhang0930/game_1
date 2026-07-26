extends RefCounted

class_name CellData

# Grid coordinates.
var row: int
var col: int

# Terrain on this cell.
var terrain: TerrainData

# Object placed on this cell.
var object: ObjectData

# Unit currently standing on this cell.
var unit
