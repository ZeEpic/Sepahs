class_name Grass
extends Node2D


const MAX_ROTATION: float = 0.6 # the maximum distance it can turn left or right
const MAX_SIZE: int = 5 # the maximum size it can randomly be
var wind_speed: float = 0.5 # the speed at which it rotates
var wind_direction: Array = [] # the directions for each blade of grass

func _ready() -> void: # called at the start of the game
	_regen() # create the blades of grass
	for sprite in get_children(): # give them all random directions to go in
		var new_direct: float = g.rand_int(-6, 4) / 10.0
		if new_direct == 0: new_direct = 0.1 # make sure they aren't stationary
		wind_direction.append(new_direct) # add it to the list


func _process(delta) -> void: # called every frame
	var i: int = 0
	for sprite in get_children(): # look at each blade of grass
		sprite.rotation = clamp(lerp(sprite.rotation, sprite.rotation + wind_direction[i], wind_speed * delta), -MAX_ROTATION, MAX_ROTATION) # rotate it slightly in it's random direction and make sure it doesn't go too far
		if sprite.rotation >= MAX_ROTATION or sprite.rotation <= -MAX_ROTATION: # if it's gone too far, start moving it in the opposite direction
			wind_direction[i] = g.rand_int(-6, 4) / 10.0
		i += 1


func _regen() -> void: # called when wanting to make new blades of grass
	for sprite in get_children():
		if sprite.name != "Sprite":
			sprite.queue_free() # delete all extra blades of grass
	for i in range(g.rand_int(-12, -3), g.rand_int(3, 12)): # for a random amount of times
		var new_sprite: Sprite = $Sprite.duplicate() # create a new instance of the blade of grass
		new_sprite.rotation += 0.075 * i # rotate it based on it's order in the plant
		new_sprite.scale *= g.rand_int(1, MAX_SIZE) / 10.0 # change it's size randomly
		new_sprite.modulate = new_sprite.modulate.darkened(0.025 * -i) # darken/ lighten it randomly
		add_child(new_sprite) # and finally add it to the finished plant
	$Sprite.scale *= g.rand_int(1, MAX_SIZE) / 10.0 # make sure to re-size the original blade of grass
