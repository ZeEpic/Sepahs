class_name Network
extends Node

const CLIENT_IP: String = "127.0.0.1" # the local host IP because Gotm handles the rest
const PORT: int = 8070 # some random port
const MAX_CLIENTS: int = 2 # only 2 players allowed

var client_joined: bool = false
var is_server: bool = false


func _ready() -> void: # called at the start of the game
# warning-ignore:return_value_discarded
	get_tree().connect("connected_to_server", self, "_connected_ok") # connect network signals for later use
# warning-ignore:return_value_discarded
	get_tree().connect("connection_failed", self, "_connected_fail")
# warning-ignore:return_value_discarded
	get_tree().connect("server_disconnected", self, "_server_disconnected")
# warning-ignore:return_value_discarded
	get_tree().connect("network_peer_disconnected", self, "_player_disconnected")


func create_server() -> void: # for creating a game server
	var peer: NetworkedMultiplayerENet = NetworkedMultiplayerENet.new() # a class for handling high level multiplayer
# warning-ignore:return_value_discarded
	peer.create_server(PORT, MAX_CLIENTS) # make the server and pass in the constants
	get_tree().set_network_peer(peer) # call this method to set up the network
	is_server = true
	$"/root/Lobby/LoadingScreen".show()
	for button in $"/root/Lobby/Buttons".get_children():
		button.disabled = true


func join_server() -> void:
	var peer: NetworkedMultiplayerENet = NetworkedMultiplayerENet.new() # a class for handling high level multiplayer
# warning-ignore:return_value_discarded
	peer.create_client(CLIENT_IP, PORT) # same as the server but to make a client we need to specify the ip
	get_tree().set_network_peer(peer)
	$"/root/Lobby/LoadingScreen".show()
	for button in $"/root/Lobby/Buttons".get_children():
		button.disabled = true


remote func joined_server() -> void: # for telling the server when the client has connected
	client_joined = true
	g.my_turn = false
# warning-ignore:return_value_discarded
	get_tree().change_scene("res://Scenes/Game.tscn") # change the scene to the main game one


func _connected_ok() -> void: # for when the client successfully connects to the server
	rpc("joined_server")
# warning-ignore:return_value_discarded
	get_tree().change_scene("res://Scenes/Game.tscn") # change the scene to the main game one


func _connected_fail() -> void: # could not connect to server
	if get_tree().current_scene.name == "Lobby":
		$"/root/Lobby/LoadingScreen".hide()
		for button in $"/root/Lobby/Buttons".get_children():
			button.disabled = false
	else:
# warning-ignore:return_value_discarded
		get_tree().change_scene("res://Scenes/Lobby.tscn") # change the scene back to the lobby


func _player_disconnected(_id: int) -> void:
	if is_server:
# warning-ignore:return_value_discarded
		get_tree().change_scene("res://Scenes/Lobby.tscn") # change the scene back to the lobby


func _server_disconnected() -> void:
	if not is_server:
# warning-ignore:return_value_discarded
		get_tree().change_scene("res://Scenes/Lobby.tscn") # change the scene back to the lobby


func send_piece_data() -> void: # to send every piece and its info to each other client
	if get_tree().get_network_peer() != null:
		var piece_data: Array = []
		for piece in g.get_pieces():
			if not piece.destroyed:
				piece_data.append({
					"position": piece.position,
					"color": piece.color,
					"shape": piece.shape,
					"whos": piece.opponents
				})
		rpc("receive_piece_data", piece_data, g.newest_moves)
		g.total_moves += g.newest_moves
		g.newest_moves = 0
		g.my_turn = not g.my_turn
		g.refresh_text()


remote func receive_piece_data(updated_pieces: Array, new_moves: int) -> void: # to receive the data that was sent by the other clients about the piece data
	for piece in get_node("/root/Game/Pieces").get_children(): # loop though each one and delete it
		piece.destroyed = true
		piece.queue_free()
	var new_shape: Piece
	for piece in updated_pieces:
		if piece.shape in $"/root/Game".pieces.keys():
			new_shape = $"/root/Game".pieces[piece.shape].instance()
			new_shape.position = piece.position
			new_shape.color = piece.color
			new_shape.opponents = not piece.whos
			get_node(g.GAME_PATH + "Pieces").add_child(new_shape)
	g.my_turn = not g.my_turn
	g.total_turns += 1
	g.refresh_text()
	g.total_moves += new_moves
	$"/root/Game".move_history += "%d moves received from opponent.\n" % new_moves


func send_message(new_message: String) -> void:
	if get_tree().get_network_peer() != null:
		rpc("receive_message", new_message)


remote func receive_message(incoming_message: String) -> void:
	$"/root/Game/UI/Messages/MessageLog".text += "\nOpponent | " + incoming_message
	yield(get_tree().create_timer(20.0), "timeout")
	var split_text: PoolStringArray = $"/root/Game/UI/Messages/MessageLog".text.split("\n")
	split_text.remove(1)
	$"/root/Game/UI/Messages/MessageLog".text = split_text.join("\n")


func send_end_game() -> void:
	if get_tree().get_network_peer() != null:
		rpc("receive_end_game")


remote func receive_end_game() -> void:
	g.end_game(false)
