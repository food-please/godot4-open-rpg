## The GamepieceRegistry keeps track of each [Gamepiece] that is currently placed on the board.
##
## Since player movement is locked to gameboard cells (rather than physics-based movement), this
## allows UI elements, cutscenes, and other systems to quickly lookup gamepieces by name or
## location. Additionally, it allows pathfinders to see which cells are occupied or unoccupied.
class_name GamepieceRegistry extends RefCounted

# Store all registered gamepeices by the cell they occupy.
var _gamepieces: Dictionary[Vector2i, Gamepiece] = {}


func register(gamepiece: Gamepiece, cell: Vector2i) -> bool:
	# Don't register a gamepiece if it's cell is already occupied...
	if _gamepieces.has(cell):
		return false
	
	#...or if it has already been registered, for some reason.
	if gamepiece in _gamepieces.values():
		return false
	
	# We want to know when the gamepiece leaves the scene tree, as it is no longer on the gameboard.
	# This probably means that the gamepiece has been freed.
	gamepiece.tree_exiting.connect(_on_gamepiece_tree_exiting.bind(gamepiece))
	
	_gamepieces[cell] = gamepiece
	return true


## Update a gamepiece's position within the registry.
## Note that animation/position will need to be updated in response to the
## [signal Events.gamepiece_moved] signal.
func move_gamepiece(gp: Gamepiece, new_cell: Vector2i) -> bool:
	# Don't move a gamepiece to an occupied cell.
	if _gamepieces.has(new_cell):
		print("Cell %s is already occupied, cannot move gamepiece '%s'!" % [str(new_cell), gp.name])
		return false
	
	var old_cell: = get_cell(gp)
	if old_cell == new_cell:
		print("Cells are the same, cnnot move gp")
		return false
	
	print("Moved %s to %s" % [gp.name, str(new_cell)])
	_gamepieces.erase(old_cell)
	_gamepieces[new_cell] = gp
	
	#Events.gamepiece_moved.emit(gp, old_cell, new_cell)
	return true


## Return the gamepiece, if any,that is found at a given cell.
func get_gamepiece(cell: Vector2i) -> Gamepiece:
	return _gamepieces.get(cell) as Gamepiece


## Return the gamepiece, if any, that has a given name.
func get_gamepiece_by_name(gp_name: String) -> Gamepiece:
	for gp: Gamepiece in _gamepieces.values():
		if gp.name == gp_name:
			return gp
	return null


## Return the cell occupied by a given gamepiece.
func get_cell(gp: Gamepiece) -> Vector2i:
	var cell: = _gamepieces.find_key(gp) as Vector2i
	if _gamepieces.has(cell):
		return cell
	return Gameboard.INVALID_CELL


func get_occupied_cells() -> Array[Vector2i]:
	return _gamepieces.keys()


func get_gamepieces() -> Array[Gamepiece]:
	return _gamepieces.values()


# Remove all traces of the gamepiece from the registry.
func _on_gamepiece_tree_exiting(gp: Gamepiece) -> void:
	var cell = _gamepieces.find_key(gp)
	if _gamepieces.has(cell):
		_gamepieces.erase(cell)
	
	#if cell != null:
		#Events.gamepiece_exiting_tree.emit(gp, cell)


func _to_string() -> String:
	var msg: = "\nGamepieceRegistry:"
	for entry in _gamepieces:
		msg += ("\n%s %s" % [entry, str(_gamepieces[entry])])
	return msg
