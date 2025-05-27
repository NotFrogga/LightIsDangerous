extends RigidBody2D
class_name Player

enum PlayerState { MOVE, CARRY, PULLED_BY_LIGHT }

@export var speed_curve : Curve
@export var damping_curve : Curve
var timer_input_speed_pressed: float = 0
var timer_input_damping_pressed : float = 0

var object_attached_path : NodePath = NodePath("")

#@onready var CAMERA_2D = $Camera2D
@export var offset_curve : Curve
var timer_input_camera_offset : float = 0

var additional_velocity : Vector2 = Vector2.ZERO
var current_state : PlayerState = PlayerState.MOVE

@onready var ANIMATION_PLAYER = $AnimationPlayer
@onready var SPRITE_2D = $Sprite2D

func set_state(new_state : PlayerState) -> void:
	current_state = new_state

func get_input() -> Vector2:
	return Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")

func _ready() -> void:
	ANIMATION_PLAYER.play("fly")

func _process(delta: float) -> void:
	set_flip_sprite_2d()
	
	set_speed_domain(delta)
	set_damping_domain(delta)
	set_damping()
	
	grab_object()
	
	#set_camera_offset_domain(delta)
	#offset_camera()

func set_flip_sprite_2d() :
	if linear_velocity.x > 0 :
		SPRITE_2D.flip_h = false
	else :
		SPRITE_2D.flip_h = true

func set_speed_domain(delta) -> void:
	if get_input() == Vector2.ZERO:
		timer_input_speed_pressed -= delta
	else:
		timer_input_speed_pressed += delta
	
	timer_input_speed_pressed = clampf(timer_input_speed_pressed, 0.0, speed_curve.max_domain)

func set_damping_domain(delta) -> void:
	if get_input() == Vector2.ZERO:
		timer_input_damping_pressed -= delta
	else:
		timer_input_damping_pressed += delta
	
	timer_input_damping_pressed = clampf(timer_input_damping_pressed, 0.0, damping_curve.max_domain)

func set_camera_offset_domain(delta) -> void:
	if linear_velocity.x > 20:
		timer_input_camera_offset += delta
	elif linear_velocity.x < -20:
		timer_input_camera_offset -= delta
	else :
		timer_input_camera_offset -= timer_input_camera_offset/50
		if abs(timer_input_camera_offset) < 0.05:
			timer_input_camera_offset = 0
	timer_input_camera_offset = clampf(timer_input_camera_offset, offset_curve.min_domain, offset_curve.max_domain)

func get_speed() -> float :
	return speed_curve.sample(timer_input_speed_pressed)

func set_damping() -> void:
	linear_damp = damping_curve.sample(timer_input_damping_pressed)

func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	state.linear_velocity += (get_input() * get_speed()) + additional_velocity

func offset_camera() -> void:
	pass
	#CAMERA_2D.offset.x = offset_curve.sample(timer_input_camera_offset)

func grab_object() -> void:
	if Input.is_action_pressed("Grab"):
		if $PinJoint2D.node_b == NodePath(""):
			var overlapping_areas = $GrabDetectionArea.get_overlapping_areas()
			if overlapping_areas.is_empty() == false:
				object_attached_path = overlapping_areas[0].get_parent().get_path()
		else:
			object_attached_path = NodePath("")
		$PinJoint2D.node_b = object_attached_path

func light_attract(gravity_center : Vector2, pulling_force : float) :
	additional_velocity = (gravity_center - global_position).normalized() * pulling_force / sqrt(global_position.distance_to(gravity_center))
