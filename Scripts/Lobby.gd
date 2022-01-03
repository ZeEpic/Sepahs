class_name Lobby
extends Control

var text_iter: int = 1

func _on_Create_pressed() -> void: # when you press the create server button
	net.create_server() # call the method in the autoload singleton


func _on_Join_pressed() -> void: # when the join server button is pressed
	net.join_server() # similarly, call the join server method in the autoload


func _on_Settings_pressed() -> void: # game settings
	$Buttons/Settings/Label.text = "WIP" # work in progress

func _unhandled_key_input(event: InputEventKey) -> void: # run whenever it finds a key input from the user
	if event.scancode == KEY_ESCAPE: # pressing the escape key?
		if OS.get_name() in ["Windows", "OSX"]: # if this is being run on windows or a mac
			get_tree().quit() # exit the game


func _on_Singleplayer_pressed() -> void:
	g.singleplayer = true
# warning-ignore:return_value_discarded
	get_tree().change_scene("res://Scenes/Game.tscn")


func _on_Timer_timeout() -> void:
	text_iter += 1
	if text_iter == 4:
		text_iter = 1
	$LoadingScreen/Label.text = "Waiting for opponent"
	for _i in range(text_iter):
		$LoadingScreen/Label.text += "."
