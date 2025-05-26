extends Area2D
class_name Light

@export var attraction_speed = 500
var start_attraction : bool = false

func _process(delta: float) -> void:
	if start_attraction:
		for body in get_overlapping_bodies():
			if body.has_method("light_attract"):
				body.light_attract(global_position, attraction_speed)

func _on_body_exited(body: Node2D) -> void:
	if body.has_method("light_attract"):
		body.light_attract(global_position, 0)
		start_attraction = false


func _on_body_entered(body: Node2D) -> void:
	$CooldownBeforeAttraction.start()


func _on_cooldown_before_attraction_timeout() -> void:
	start_attraction = true
