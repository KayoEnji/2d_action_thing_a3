extends RigidBody2D

const threshold_angle = 45.0

var is_knocked_over : float:
	get:
		return abs(rotation_degrees) > threshold_angle

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if is_knocked_over and $KnockTimer.is_stopped():
		$KnockTimer.start()


func _on_knock_timer_timeout():
	position.y -= 80.0
	rotation_degrees = 0.0
