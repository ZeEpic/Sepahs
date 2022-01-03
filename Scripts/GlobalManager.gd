class_name GlobalManager
extends Node

var currently_drag: bool  = false # a variable for whether a shape is being dragged right now
var current_color:  Color = Color.transparent # a variable for the turn's color, eg. green
var total_turns:    int   = 0 # a variable that stores the number of turns played in the game
var total_moves:    int   = 0
var newest_moves:   int   = 0
const tile_size:    int   = 100 # a constant for the size of a tile
var my_turn:        bool  = true
var singleplayer:   bool  = false
var game_over:      bool  = false
var winner:         bool = false

onready var end_screen: PackedScene = preload("res://Scenes/EndScreen.tscn")

const UI_label:  String = "Turn | %s \n%s Turn" # the template used for the UI/Label text
const GAME_PATH: String = "/root/Game/" # used when running get_node()


func refresh_text() -> void: # for changing the total turns in the label
	if my_turn:
		get_node(GAME_PATH + "UI/Label").text = UI_label % [total_turns, "Your"]
	else:
		get_node(GAME_PATH + "UI/Label").text = UI_label % [total_turns, "Opponent's"]
	if singleplayer:
		get_node(GAME_PATH + "UI/Label").text = "Turn | " + str(total_turns)


func refresh_color() -> void: # for changing the turn's color displayed in the long rectangle at the top of the screen
	get_node(GAME_PATH + "UI/TextureRect").modulate = current_color


func get_occupied_tiles() -> Array: # for finding every tile that contains a game piece
	var occupied: Array = [] # a temporary list
	for piece in get_pieces(): # looks at every piece
		occupied.append(piece.get_grid_position(piece.position)) # adds the piece's grid position
	return occupied # gives the list of locations


func get_tiles() -> Array: # returns every tile on the board
	return get_node(GAME_PATH + "Board").get_children()


func get_pieces() -> Array: # returns every piece still alive
	return get_node(GAME_PATH + "Pieces").get_children()


func rand_int(from: int, to: int) -> int: # returns a random number in between "from" and "to"
	randomize() # changes the random seed
	return (randi() % (to + 1 - from)) + from # does a calculation to find the random number


func list_files_in_directory(path) -> Array: # code from "https://godotengine.org/qa/5175/how-to-get-all-the-files-inside-a-folder"
	var files: Array = []
	var dir: Directory = Directory.new()
# warning-ignore:return_value_discarded
	dir.open(path)
# warning-ignore:return_value_discarded
	dir.list_dir_begin()

	while true:
		var file = dir.get_next()
		if file == "":
			break
		elif not file.begins_with("."):
			files.append(file)

	dir.list_dir_end()

	return files


func end_game(who: bool) -> void:
	winner = who
	var new_end_screen: Control = end_screen.instance()
	get_node(GAME_PATH + "UI").add_child(new_end_screen)
	game_over = true
