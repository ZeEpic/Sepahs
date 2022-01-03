class_name CameraController
extends Camera2D

const SPEED:    float = 0.1 # the speed at which you zoom
const MAX_ZOOM: float = 2.0 # the maximum distance you can zoom out
const MIN_ZOOM: float = 0.1 # the minimum distance yuo can doom in

var dragging: bool       = false # if you are moving the camera
var change:   Vector2 # the location on the screen you clicked relitive to the camera
var start:    Vector2 # the place where the camera was when you start dragging

const BORDER: int = 300 # the distance you can move the camera away from the origin

var shake_amount:   int     = 0
var default_offset: Vector2 = offset
var shaking:        bool    = false
var timer:          Timer   = Timer.new()
var tween:          Tween   = Tween.new()

func _input(event: InputEvent) -> void: # triggered on any input; the event parameter is for the type of event and event info
	if event is InputEventMouseButton and not g.game_over: # only do stuff when there is a mouse button event
		match event.button_index: # finds which button on the mouse you clicked
			1, 2, 3: # left, right, and middle clicks
				if not dragging: # if you aren't already dragging, start doing it
					start = get_global_mouse_position() # save it's starting position
					change = position
				dragging = event.pressed # dragging or not we are going to flip it from dragging to not dragging or vice versa
			4: # scroll wheel zoom in
				if event.pressed and zoom.x > MIN_ZOOM: # if it's more than the minimum
					zoom -= Vector2.ONE * SPEED # zoom in
			5: # scroll wheel zoom out
				if event.pressed and zoom.x < MAX_ZOOM: # if it's less than the maximum
					zoom += Vector2.ONE * SPEED # zoom out

	elif event is InputEventMouseMotion and dragging and not g.currently_drag and not g.game_over: # if you are moving the mouse and not trying to drag a game piece around
		var new_pos: Vector2 = lerp(position, (start - get_global_mouse_position()) + change, 0.5) # gradually move the camera towards the mouse's position
		position = Vector2(clamp(new_pos.x, -BORDER, BORDER), clamp(new_pos.y, -BORDER, BORDER)) # make sure we don't go too far from the origin


func _ready() -> void:
# warning-ignore:return_value_discarded
	timer.connect("timeout", self, "_on_Timer_timeout")
	add_child(timer)
	add_child(tween)


func _process(delta: float) -> void:
	if shaking:
		offset = Vector2(rand_range(-shake_amount, shake_amount), rand_range(-shake_amount, shake_amount)) * delta + default_offset


func shake(new_shake: int, shake_time: float = 0.4, shake_limit: int = 100) -> void:
	shake_amount += new_shake
	if shake_amount > shake_limit:
		shake_amount = shake_limit
	timer.wait_time = shake_time
	
# warning-ignore:return_value_discarded
	tween.stop_all()
	shaking = true
	timer.start()


func _on_Timer_timeout() -> void:
	shake_amount = 0
	shaking = false
# warning-ignore:return_value_discarded
	tween.interpolate_property(self, "offset", offset, default_offset, 0.1, Tween.TRANS_QUAD, Tween.EASE_IN_OUT)
# warning-ignore:return_value_discarded
	tween.start()
