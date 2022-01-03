class_name Square
extends Piece # inherits from the game piece class

func _ready() -> void:
	shape = "Square"


func _rule(start: Vector2, end: Vector2, occupied: Array) -> bool: # called when determining where the circle can move to
	if start.x == end.x or start.y == end.y: # if the space is on the same x or y as the square piece
		if end.x > start.x and end.y == start.y: # when the piece is being moved to the right
			for tile in occupied:
				if tile.y == start.y and tile.x < end.x and tile.x > start.x: # if there is an occupied tile in the way it won't let you go any further
					return false
		elif end.x < start.x and start.y == end.y: # when the piece is being moved to the left
			for tile in occupied:
				if tile.y == start.y and tile.x > end.x and tile.x < start.x: # if there is an occupied tile in the way it won't let you go any further
					return false
		elif end.y > start.y: # when the piece is being moved down
			for tile in occupied:
				if tile.x == end.x and tile.y < end.y and tile.y > start.y: # if there is an occupied tile in the way it won't let you go any further
					return false
		elif end.y < start.y: # when the piece is being moved up
			for tile in occupied:
				if tile.x == end.x and tile.y > end.y and tile.y < start.y: # if there is an occupied tile in the way it won't let you go any further
					return false
		return true # by default just assume it's fine to move if there are no obstacles
	return false
