extends KinematicBody

const GRAVITY = -24.8
const MAX_SPEED = 7
const ACCEL = 3.5

onready var collider = $Collider
onready var camera = $CameraPivot/Camera
onready var footsteps = $Footsteps
onready var fader = $Fader

signal orb_collected

var vel = Vector3()
var dir = Vector3()
var collected_orbs = 0
var shake_amount = 0.01
var is_dying = false

const DEACCEL= 16
const MAX_SLOPE_ANGLE = 40

var rotation_helper
var walking = false

var MOUSE_SENSITIVITY = 0.05

func _ready():
	randomize()
	rotation_helper = $CameraPivot
	collider.connect("area_entered", self, "on_area_entered")
	fader.connect("fade_finished", self, "on_fade_finished")
	
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _physics_process(delta):
	
	if is_dying:
		shake_amount += 0.02 * delta
		camera.h_offset = rand_range(-1, 1) * shake_amount
		camera.v_offset = rand_range(-1, 1) * shake_amount
		return
	
	process_input(delta)
	process_movement(delta)
	

func process_input(delta):

	# ----------------------------------
	# Walking
	dir = Vector3()
	var cam_xform = camera.get_global_transform()

	var input_movement_vector = Vector2()

	if Input.is_action_pressed("movement_forward"):
		input_movement_vector.y += 1
	if Input.is_action_pressed("movement_backward"):
		input_movement_vector.y -= 1
	if Input.is_action_pressed("movement_left"):
		input_movement_vector.x -= 1
	if Input.is_action_pressed("movement_right"):
		input_movement_vector.x += 1
	if Input.is_action_just_pressed("toggle_flashlight"):
		$CameraPivot/SpotLight.visible = not $CameraPivot/SpotLight.visible

		
	input_movement_vector = input_movement_vector.normalized()
	
	if input_movement_vector.x != 0 or input_movement_vector.y != 0:
		walking = true
	else:
		walking = false
		
	if walking and !footsteps.playing:
		footsteps.play()
	if not walking and footsteps.playing:
		footsteps.stop()
	

	dir += -cam_xform.basis.z.normalized() * input_movement_vector.y
	dir += cam_xform.basis.x.normalized() * input_movement_vector.x
	# ----------------------------------


	# ----------------------------------
	# Capturing/Freeing the cursor
	if Input.is_action_just_pressed("ui_cancel"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_VISIBLE:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	# ----------------------------------

func process_movement(delta):
	dir.y = 0
	dir = dir.normalized()

	

	var hvel = vel
	hvel.y = 0

	var target = dir
	target *= MAX_SPEED

	var accel
	if dir.dot(hvel) > 0:
		accel = ACCEL
	else:
		accel = DEACCEL

	hvel = hvel.linear_interpolate(target, accel * delta)
	vel.x = hvel.x
	vel.z = hvel.z

	vel = move_and_slide(vel, Vector3(0, 1, 0), 0.05, 4, deg2rad(MAX_SLOPE_ANGLE))

func _input(event):
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		rotation_helper.rotate_x(deg2rad(event.relative.y * MOUSE_SENSITIVITY * -1))
		self.rotate_y(deg2rad(event.relative.x * MOUSE_SENSITIVITY * -1))

		var camera_rot = rotation_helper.rotation_degrees
		camera_rot.x = clamp(camera_rot.x, -90, 90)
		rotation_helper.rotation_degrees = camera_rot
		
	
func die():
	is_dying = true
	fader.set_playback_speed(0.15)
	fader.fade_out()
	


func on_area_entered(area):
	if area.is_in_group("Orb"):
		area.queue_free()
		emit_signal("orb_collected")
	

	
func on_fade_finished():
	get_tree().change_scene("res://src/menu_components/MainMenu.tscn")
