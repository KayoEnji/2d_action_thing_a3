extends CharacterBody2D

@onready var sprite = $Sprite2D
@onready var anim = $AnimationPlayer
@onready var dash_time = $dash_time

@export var SPEED = 450
@export var air_speed = .00002

#movement variables
@export var jump_height : float
@export var time_to_peak : float
@export var time_to_descent : float

@export var dash_speed :float
var is_dashing = false

@export var acceleration = 50
@export var drag : float = 80

@onready var fall_gravity : float = ((-2 * jump_height) / (time_to_descent * time_to_descent)) *-1
@onready var jump_gravity : float = ((-2 * jump_height) / (time_to_peak * time_to_peak)) * -1
@onready var jump_velocity : float = ((2 * jump_height) / time_to_peak) * -1


var can_jump = false
var is_facing_right = true

#state machine
var main_sm: LimboHSM

#base fn
func _ready():
	init_state_machine()

func _physics_process(delta):
	print(main_sm.get_active_state())
	
	# Add the gravity & air drag.
	if not is_on_floor():
		velocity.y += _get_gravity() * delta
		

	# Handle jump.
	if Input.is_action_pressed("jump") and is_on_floor():
		main_sm.dispatch(&"to_jump")

	# Handle Dash
	if Input.is_action_just_pressed("dash"):
		main_sm.dispatch(&"to_dash")

	# Get the input direction and handle the movement/deceleration.
	##TODO: Acceleration
	var direction = get_direction()
	if direction and is_dashing:
		velocity.x = direction * dash_speed
	elif !is_on_floor:
		velocity.x = move_toward(velocity.x, 0, air_speed)
	elif direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, drag)
	
	##print(direction)
	
	flip_sprite(direction)
	move_and_slide()

func get_direction():
	var direction = Input.get_axis("left", "right")
	return direction

func _get_gravity():
	return jump_gravity if velocity.y < 0 else fall_gravity

func flip_sprite(direction):
	if direction == 1:
		sprite.flip_h = false
		is_facing_right = true
	elif direction == -1:
		sprite.flip_h = true
		is_facing_right = false
		
func _unhandeled_input(event):
	if event.is_action_pressed("jump"):
		main_sm.dispatch(&"to_jump")

func init_state_machine():
	main_sm = LimboHSM.new()
	add_child(main_sm)
	
	#define states
	var idle = LimboState.new().named("idle").call_on_enter(idle_start).call_on_update(idle_update)
	var move = LimboState.new().named("move").call_on_enter(move_start).call_on_update(move_update)
	var jump = LimboState.new().named("jump").call_on_enter(jump_start).call_on_update(jump_update)
	var dash = LimboState.new().named("dash").call_on_enter(dash_start).call_on_update(dash_update)
	
	main_sm.add_child(idle)
	main_sm.add_child(move)
	main_sm.add_child(jump)
	main_sm.add_child(dash)
	
	main_sm.initial_state = idle
	
	#transitions
	##TODO: theres gotta be a better way to do this
	main_sm.add_transition(idle, move, &"to_move")
	main_sm.add_transition(main_sm.ANYSTATE, idle, &"state_ended")
	main_sm.add_transition(idle, jump, &"to_jump")
	main_sm.add_transition(move, jump, &"to_jump")
	main_sm.add_transition(idle, dash, &"to_dash")
	main_sm.add_transition(move, dash, &"to_dash")
	main_sm.add_transition(jump, dash, &"to_dash")
	
	main_sm.initialize(self)
	main_sm.set_active(true)

#state fn
func idle_start():
	anim.play("Idle")
	if is_on_floor():
		can_jump = true
func idle_update(delta: float):
	if velocity.x != 0:
		main_sm.dispatch(&"to_move")

func move_start():
	anim.play("Move")
	if is_on_floor():
		can_jump = true
func move_update(delta: float):
	if velocity.x == 0:
		main_sm.dispatch(&"state_ended")

func jump_start():
	anim.play("Jump")
	velocity.y = jump_velocity
func jump_update(delta: float):
	#if Input.is_action_just_pressed("jump") and can_jump == false:
		#velocity.y += -JUMP_VELOCITY
	
	if is_on_floor():
		main_sm.dispatch(&"state_ended")

func dash_start():
	if is_on_floor:
		can_jump = true
		
	var direction = get_direction()
	if direction:
		anim.play("ForwardDash")
		
	is_dashing = true	
	$dash_time.start()
func dash_update(delta: float):
	pass
func _on_dash_time_timeout():
	is_dashing = false
	main_sm.dispatch(&"state_ended")
