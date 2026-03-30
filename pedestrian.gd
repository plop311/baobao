extends Area2D

# This function runs whenever something enters the Pedestrian's area
func _on_body_entered(body: Node2D) -> void:
	# 1. Check if the thing that hit us is the Player (Tuktuk)
	if body.name == "Player":
		
		# 2. Look for the 'World' node (the parent)
		var world_node = get_parent()
		
		# 3. If the World has the 'add_point' function, run it!
		if world_node.has_method("add_point"):
			world_node.add_point()
		
		# 4. Remove the pedestrian from the game
		print("Tanduay Point Secured!")
		queue_free()
