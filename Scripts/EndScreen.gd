extends Control


func _ready():
	if g.winner:
		$VBoxContainer/Title.text = "You Win!"
	else:
		$VBoxContainer/Title.text = "You Lost"
	$VBoxContainer/Info.text = "The game finished after %d turns\nand %d total moves." % [g.total_turns, g.total_moves]
