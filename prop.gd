extends Area2D

@export var required_speed: float = 200.0
@export var score_value: int = 25

func _ready():
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D):
	if body.name == "Player":
		if body.velocity.length() > required_speed:
			var world = get_parent()
			if world and world.has_method("update_ui"):
				world.total_score += score_value
				world.update_ui()

			# Add explosion effect here if you want
			queue_free()
