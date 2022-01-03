class_name Circle
extends Piece # inherits from the game piece class

export var max_move_dist: int = 2 # stores the maximum distance away from the start it can move

func _ready() -> void:
	shape = "Circle"


func _rule(start: Vector2, end: Vector2, _occupied: Array) -> bool: # called when determining where the circle can move to
	return start.distance_to(end) < max_move_dist # like the king in chess
