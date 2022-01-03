class_name Game
extends Node2D

export var tile:  PackedScene # this is the scene for the tiles of the game board
export var grass: PackedScene # this is the scene for the grass that is randomly places
const PIECES_PATH = "res://Scenes/Pieces/"

const COLORS:    Dictionary  = { # a list of colors
	"TILE_DARK": Color("6D5458"), # this is for the colors of the board tiles
	"TILE_LIGHT": Color("8C5B5E"),
	"BG_DARK": Color("594D47"), # these are for the background changing colors
	"BG_LIGHT": Color("FFDDCA")
}

var bg_lightness: int  = 0 # the changing level of brightness of the background
var bg_l_or_d:    bool = true # decides if we are making the background lighter or darker
const BG_COLOR_SPEED: float = 0.01 # the speed at which the background color is changed

var pieces:       Dictionary = {}
var move_history: String     = ""

var messages_size: float = 400

func _ready() -> void: # gets run at the start of the game
	g.total_turns = 0
	var other: bool = true # for every other tile changing; it makes a checker board pattern.
	for x in range(-3,4): # 7 in width
		for y in range(-3,4): # 7 in height
			var tl: Tile = tile.instance() # creates a tile instance
			tl.position = Vector2(x*g.tile_size, y*g.tile_size) # changes the tile's position to the correct place
			
			if other: # changes it's color depending on where it is
				tl.modulate = COLORS["TILE_LIGHT"]
				tl.origin_color = COLORS["TILE_LIGHT"]
				tl.dark = false
			else:
				tl.modulate = COLORS["TILE_DARK"]
				tl.origin_color = COLORS["TILE_DARK"]
				tl.dark = true
			
			other = not other # flips the color for the next tile
			$Board.add_child(tl) # adds it to the scene tree
	g.refresh_text() # makes sure the text of the UI/Label node is displaying the correct info at the start
	if OS.get_name() == "HTML5": # when run in the browser it shouldn't show a button for exiting the game
		$"UI/Close Button".hide()
	var border: int = 1000 # the max distance from the center that a bit of grass can spawn at
	for _i in range(50): # tries to spawn 50 grass
		var new_grass: Node2D = grass.instance() # creates an instance
		new_grass.position = Vector2(g.rand_int(-border, border), g.rand_int(-border, border)) # creates a random position for it that is within the border
		if not abs(new_grass.position.x) < 375 and not abs(new_grass.position.y) < 375: # if it's not inside the game board, add it to the scene tree
			$Grasses.add_child(new_grass)
	for scene in g.list_files_in_directory(PIECES_PATH):
		pieces[scene.replace(".tscn", "")] = load(PIECES_PATH + scene)
	messages_size = $UI/Messages/MessageLog.rect_size.y
	if g.singleplayer:
		$UI/Messages.hide()
	else:
		$UI/ResetButton.disabled = true
		$UI/ResetButton.hide()
		if net.is_server:
			net.send_piece_data()


func _process(delta) -> void: # gets run every frame
	if bg_l_or_d: # if we're making the background lighter
		if $BG.modulate.to_html() == COLORS["BG_LIGHT"].to_html(): # if the background is at it's lightest, start making it darker
			bg_l_or_d = false
		$BG.modulate = lerp($BG.modulate, COLORS["BG_LIGHT"], BG_COLOR_SPEED * delta) # make it lighter by a tiny bit
	else:
		if $BG.modulate.to_html() == COLORS["BG_DARK"].to_html(): # when it gets to it's darkest, make it lighter
			bg_l_or_d = true 
		$BG.modulate = lerp($BG.modulate, COLORS["BG_DARK"], BG_COLOR_SPEED * delta)

func _unhandled_key_input(event: InputEventKey) -> void: # run whenever it finds a key input from the user
	if event.scancode == KEY_ESCAPE: # pressing the escape key?
		if OS.get_name() in ["Windows", "OSX"]: # if this is being run on windows or a mac
			get_tree().quit() # exit the game


func _on_Close_Button_pressed() -> void: # run when you click the X button
	get_tree().quit() # exit the game


func _on_Close_Button_button_down() -> void: # run when you first click down on the button
	g.currently_drag = true # tell the game to not let you drag any shapes


func _on_Close_Button_button_up() -> void: # run when you finish clicking on the button
	g.currently_drag = false # this is to make sure you can continue playing the game if you decide to not close it


func _on_LineEdit_text_entered(new_text: String) -> void:
	if not g.singleplayer:
		$UI/Messages/LineEdit.text = ""
		$UI/Messages/MessageLog.text += "\nYou | " + new_text
		net.send_message(new_text)
		yield(get_tree().create_timer(10.0), "timeout")
		var split_text: PoolStringArray = $UI/Messages/MessageLog.text.split("\n")
		split_text.remove(1)
		$UI/Messages/MessageLog.text = split_text.join("\n")


func _on_TextureButton_toggled(button_pressed: bool) -> void:
	if not g.singleplayer:
		if button_pressed:
			$UI/Tween.interpolate_property($UI/Messages, "rect_position", $UI/Messages.rect_position, $UI/Messages.rect_position + Vector2.LEFT * $UI/Messages.rect_size.x, 0.15)
			$UI/Tween.start()
		else:
			$UI/Tween.interpolate_property($UI/Messages, "rect_position", $UI/Messages.rect_position, $UI/Messages.rect_position + Vector2.RIGHT * $UI/Messages.rect_size.x, 0.15)
			$UI/Tween.start()


func _on_ResetButton_pressed():
# warning-ignore:return_value_discarded
	get_tree().reload_current_scene()
	move_history = ""
	g.current_color = Color.transparent
	g.total_turns = 0


func _on_CopyMovesButton_pressed():
	OS.clipboard = move_history
