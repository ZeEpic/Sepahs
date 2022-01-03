class_name Piece # so it can be referenced/ inherited from in other classes
extends Area2D

var dragging:       bool    = false # for dragging the piece
var has_dragged:    bool    = false # if it has dragged yet this turn
var offset:         Vector2 # the offset from the start of the drag
var start:          Vector2 # the place at which it started dragging
var destroyed:      bool    = false # if it's about to be destroyed
var shape:          String # the type of shape it is
var blinking:       bool    = false
var blink_direct:   bool    = false
const BLINK_SPEED:  int     = 20
var blink_timer:    Timer   = Timer.new()
var turn_completed: bool    = false
var sounds:         Array   = [RandomizedAudioStreamPlayer2D.new(), RandomizedAudioStreamPlayer2D.new(), RandomizedAudioStreamPlayer2D.new()]

export var multi_piece_rule: bool  = true
export var color:            Color = Color.white # the color of the shape can be changed in the editor
export var opponents:        bool  = false

const MOVE: Dictionary = { # the colors the board tiles change to when showing the piece is allowed to move there
	"LIGHT": Color("AE423E"),
	"DARK": Color("9F3F3B")
}


func _rule(_begin: Vector2, _end: Vector2, _occupied: Array) -> bool: # the function called when determining where the piece should be allowed to move; by default it can move anywhere on the map that is not occupied
	return true


func _ready() -> void: # called at the start of the game
	position = get_grid_position(position) * g.tile_size # make sure it's snapped to the grid
	modulate = color # change it's color to the one stored in the variable
	if opponents and not g.singleplayer:
		get_node("Sprite").hide()
		get_node("OppSprite").show()
	add_child(blink_timer)

# warning-ignore:return_value_discarded
	blink_timer.connect("timeout", self, "_on_Timer_timeout")
	blink_timer.set_wait_time(2.0)
	blink_timer.one_shot = true

	sounds[0].clips_path = "PieceDestroyed"
	sounds[1].clips_path = "PieceMoved"
	sounds[2].clips_path = "PieceMoving"
	for sound in sounds:
		add_child(sound)
		sound.name = sound.clips_path


func _on_Timer_timeout() -> void:
	blinking = true


func _process(delta: float) -> void: # called every frame
	if dragging: # if we are dragging the shape
		position = lerp(position, get_global_mouse_position() + offset, 25 * delta) # quickly move it towards the mouse curser
	if blinking:
		if not turn_completed:
			if blink_direct:
				modulate = lerp(modulate, color, BLINK_SPEED * delta)
				if modulate == color:
					blink_direct = false
			else:
				modulate = lerp(modulate, color.lightened(0.4), BLINK_SPEED * delta)
				if modulate == color.lightened(0.4):
					blink_direct = true
	elif color != modulate:
		modulate = color


func _input(event: InputEvent) -> void: # called on any input
	if event is InputEventMouseButton: # if it's the mouse button
		if event.button_index == 1: # if it's the left mouse button
			if not event.pressed and dragging: # if we have already been dragging and now are releasing the mouse button
				dragging = false # we stop dragging
				g.currently_drag = false # make the other pieces know this as well
				var closest:  Area2D = get_closest_tile() # the closest tile on the board
				var did_move: bool   = true # if it even moved to a different tile at all
				for piece in g.get_pieces(): # look at each other game piece
					if piece.position == closest.position and piece != self and _rule(get_grid_position(start), get_grid_position(piece.position), g.get_occupied_tiles()): # if this piece is at the location of the closest tile and the rule still applies:
						if piece.opponents or g.singleplayer:
							piece.queue_free() # delete it, because it's been destroyed
							piece.destroyed = true
							position = get_grid_position(closest.position) * g.tile_size # to fix a bug where if the color's own piece just got destroyed, it will now snap to the tile like usual
							closest = self # to fix a bug where the turn would not end if you destroyed your own piece
							$"/root/Game/Camera2D".shake(50)
							$"/root/Game".move_history += "Piece is taken.\n"
						else:
							closest = null
							did_move = false
						break
				if closest == null: # meaning it didn't move at all
					position = start
				elif closest != self:
					if start == closest.position:
						did_move = false
					position = closest.position # snap the pieces position to it's closest tile
				if did_move:
					g.newest_moves += 1
					get_child(get_child_count() - 2).play_random_sound()
					$"/root/Game".move_history += str(get_grid_position(start)) + " -> " + str(get_grid_position(position)) + "\n"
					has_dragged    = true # meaning it has dragged for the turn
					blinking       = false
					turn_completed = true # by default it thinks the turn was finished
					if multi_piece_rule:
						for piece in g.get_pieces(): # to check if you've moved all of the required pieces
							if piece.color == g.current_color and not piece.has_dragged and not piece.destroyed: # looks at each piece to determine if it has moved already
								if not g.singleplayer and piece.opponents:
									continue
								turn_completed = false # if it didn't yet move then the turn must not be completed
								break
					if turn_completed: # but if it is completed
						$"/root/Game".move_history += "Turn #%s was completed.\n" % g.total_turns
						if closest != self:
							$"/root/Game/Camera2D".shake(45)
						g.total_turns += 1
						g.refresh_text() # refresh the label with the new turn count
						g.current_color = Color.transparent # reset the turn's color and update that display
						g.refresh_color()
						for piece in g.get_pieces():
							piece.has_dragged = false # reset all of the piece's variables for if they have dragged yet that turn
							piece.blinking = false
						if not g.singleplayer:
							net.send_piece_data()
							var win: bool = true
							for piece in g.get_pieces():
								if piece.opponents:
									win = false
							if win:
								net.send_end_game()
								g.end_game(true)
					else:
						if closest != self:
							$"/root/Game/Camera2D".shake(15, 0.2, 50)
						for piece in g.get_pieces():
							if piece.color == g.current_color and not piece.has_dragged and not piece.destroyed:
								if not g.singleplayer and piece.opponents:
									continue
								piece.blink_timer.start()
				else: # when the piece was not actually dragged
					for piece in g.get_pieces():
						if piece.has_dragged: # if one of the pieces has been moved this turn then ignore this section
							return
					g.current_color = Color.transparent # reset the turn's color and update the display
					# this is done because without it you could start dragging a piece, have the display show that pieces color, procede to not actually move the piece at all, and then the game would break
					g.refresh_color()


func drag() -> void: # called when the piece is started to be dragged
	if g.currently_drag == false and g.my_turn and not g.game_over: # if no other piece is being dragged in the game
		if net.is_server and not net.client_joined:
			return
		if not g.singleplayer and opponents:
			return
		dragging = true
		g.currently_drag = true
		offset = position - get_global_mouse_position() # keeps the offset from the mouse to the shape
		start = position # saves it's current position for later
		for tile in g.get_tiles():
			if _rule(get_grid_position(position), get_grid_position(tile.position), g.get_occupied_tiles()) and position != tile.position: # for all tile for which the rule applies,
				if tile.dark: # change their color to be tinted red
					tile.modulate = MOVE["DARK"]
				else:
					tile.modulate = MOVE["LIGHT"]
		get_parent().move_child(self, get_parent().get_child_count()) # move the currently dragged piece to the bottom of the list so it will be shown on *top* of every other shape
		g.current_color = color
		g.refresh_color() # refresh the display for the current turn's color


func get_closest_tile() -> Area2D: # to find the closest legal tile on the board
	var closest:  Area2D
	var min_dist: float  = INF # and create a minimum distance variable which is by default at infinite
	for tile in g.get_tiles(): # look at every board tile
		tile.modulate = tile.origin_color # change it's color back to the default
		if position.distance_to(tile.position) < min_dist and _rule(get_grid_position(start), get_grid_position(tile.position), g.get_occupied_tiles()): # if it's the closest tile yet and the previously mentioned rule applies, continue
			closest = tile
			min_dist = position.distance_to(tile.position) # save the closest one yet as this tile
	return closest


func _input_event(_viewport: Object, event: InputEvent, _shape_idx: int) -> void: # called on an event happening within this Area2D's collision shape
	if event is InputEventMouseButton:
		if event.pressed:
			if event.button_index == 1: # when you click the left mouse button
				if not has_dragged: # if this piece hasn't dragged yet this turn
					if g.current_color == Color.transparent: # and the turn hasn't started yet
						drag()
					else:
						if g.current_color == color: # if the turn has already started and this piece has the correct color then it's fine
							drag()


func get_grid_position(position: Vector2) -> Vector2: # finds it's place on the map, but snapped to the grid
	return Vector2( round(position.x / g.tile_size), round(position.y / g.tile_size) ) # some math for calculating the grid position
