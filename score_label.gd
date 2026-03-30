extends Label

# This script is the "Marker Guy" who writes the score on the screen.
# It makes the text big, yellow, and puts it right where you can see it.

func _ready():
	# 1. MAKE IT BRIGHT: Let's make it Yellow so it pops!
	add_theme_color_override("font_color", Color.YELLOW)
	
	# 2. MAKE IT BIG: No more tiny text for ants.
	add_theme_font_size_override("font_size", 50)
	
	# 3. POSITION: We're putting it 50 pixels from the left, 
	# and 350 pixels down (so it's under your GPS box).
	position = Vector2(50, 350)

func _process(_delta):
	# We look for the "Player" (the Bao-bao) to see how he's doing.
	var baobao = get_tree().root.find_child("Player", true, false)
	
	if baobao:
		# We check if the Bao-bao has a "score" number in his pockets.
		var current_points = baobao.get("score")
		
		if current_points != null:
			# If he has points, we write it down!
			text = "CHAOS: " + str(int(current_points))
		else:
			# If he doesn't have a 'score' variable yet, we show this:
			text = "CHAOS: 0"
	else:
		# If the game can't find the tricycle at all:
		text = "WHERE IS THE BAO-BAO?"
