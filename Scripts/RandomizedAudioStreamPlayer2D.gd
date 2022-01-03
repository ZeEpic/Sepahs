class_name RandomizedAudioStreamPlayer2D
extends Node2D

export var clips_path: String

func _ready() -> void:
	for clip in g.list_files_in_directory("res://Sounds/" + clips_path):
		if not "import" in clip:
			var new_sound := AudioStreamPlayer2D.new()
			new_sound.stream = load("res://Sounds/" + clips_path + "/" + clip)
			add_child(new_sound)


func play_random_sound() -> void:
	var random: int = g.rand_int(0, get_child_count() - 1)
	print(random)
	print(get_child_count())
	get_child(random).play()
