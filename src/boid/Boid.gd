extends StaticBody2D

export var VISUAL_RANGE = 50.0
export var SPEED = 300

export var WRAPAROUND_Y = 600.0
export var WRAPAROUND_X = 1024.0

export var AVOID_MIN_DIST = 30

export var AVOID_FAC = 12000
export var COHESION_FAC = 10
export var ALIGNMENT_FAC = 10
export var NOISE_FAC = 1000

export var OUT_OF_BOUNDS_DIST = 100

var velocity = Vector2(1, 1) * SPEED
var middle_indicator = Circle.new()
var nearby = []

var rng = RandomNumberGenerator.new()

func _ready():
	input_pickable = true
	if Engine.editor_hint:
		var circle = Circle.new()
		circle.RADIUS = VISUAL_RANGE
		add_child(circle)
		return

	middle_indicator.RADIUS = 10
	middle_indicator.COLOR = Color.red
	# Spawn circle
#	var circle = Circle.new()
#	circle.RADIUS = VISUAL_RANGE
#	add_child(circle)
#	add_child(middle_indicator)
#	add_to_group("boids")

	# Rotate random
	rng.randomize()
	var angle = rng.randf_range(-PI, PI)
	velocity = Vector2(sin(angle), cos(angle)) * SPEED
	
func get_nearby_boids():
	nearby = []
	var dist_squared = VISUAL_RANGE * VISUAL_RANGE
	for boid in get_parent().get_children():
		if boid == self:
			continue
		
		# Squared so it doesn't have to take the square root every frame and we save some cpu power
		var distance = position.distance_squared_to(boid.position)

		if distance < dist_squared:
			nearby.push_back(boid)

func average_pos_nearby() -> Vector2:
	var average_position = Vector2.ZERO

	for boid in nearby:
		average_position += boid.position
	
	if not average_position:
		return position

	average_position /= nearby.size()

	return average_position

func avoidance_bias() -> Vector2:
	var ideal_vec = Vector2.ZERO

	for boid in nearby:
		var dist = position.distance_to(boid.position)
		if dist < AVOID_MIN_DIST:
			ideal_vec += (position - boid.position) * (1/dist)

	if not ideal_vec:
		return velocity
	
	return ideal_vec / nearby.size() * AVOID_FAC

func anti_out_of_bounds() -> Vector2:
	var ideal_vec = Vector2.ZERO
	if WRAPAROUND_Y - position.y < OUT_OF_BOUNDS_DIST:
		ideal_vec.y = -1
	
	if position.y < OUT_OF_BOUNDS_DIST:
		ideal_vec.y = 1

	if WRAPAROUND_X - position.x < OUT_OF_BOUNDS_DIST:
		ideal_vec.x = -1

	if position.x < OUT_OF_BOUNDS_DIST:
		ideal_vec.x = 1

	return ideal_vec

func cohesion_bias() -> Vector2:
	var ideal_vec = (average_pos_nearby() - position)
	return ideal_vec * COHESION_FAC

func alignment_bias() -> Vector2:
	# Get average velocity
	var average_velocity = Vector2.ZERO

	for boid in nearby:
		average_velocity += boid.velocity

	if not average_velocity:
		return velocity

	average_velocity /= nearby.size()
	return average_velocity * ALIGNMENT_FAC
	
func physics_thread(delta):
	get_nearby_boids()
	# Every bias function returns the optimal vector that they want to be in.
	# That is multiplied by the factor of each of those biases
	# Calculate the new velocity
	var alignment = alignment_bias()
	var cohesion = cohesion_bias()
	var avoidance = avoidance_bias()

	# The average of this vector
	var ideal_velocity = (alignment + cohesion + avoidance) / 3

	# If we are almost or already out of bounds, pretty much take over the ideal velocity
	var out_of_bounds_vec = anti_out_of_bounds()
	if out_of_bounds_vec:
		ideal_velocity = (ideal_velocity.normalized() * 0.3 + out_of_bounds_vec.normalized() * 0.7) * SPEED * 5

	# Interpolate our velocity to the ideal velocity
	velocity = velocity.linear_interpolate(ideal_velocity, SPEED/100 * delta)

	# Scale new velocity to speed
	velocity = velocity.normalized() * SPEED

	# Render rotation
	rotation = velocity.angle() + 0.5*PI

	# Move boid with wraparound
	var next_pos = position + (velocity * delta)
	#next_pos = Vector2(fposmod(next_pos.x, WRAPAROUND_X), fposmod(next_pos.y, WRAPAROUND_Y))
	set_deferred("position", next_pos)


func _on_Boid_input_event(viewport:Node, event:InputEvent, shape_idx:int):
	if event is InputEventMouseButton:
		print("Click")
