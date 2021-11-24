extends KinematicBody2D

export var VISUAL_RANGE = 70.0
export var SPEED = 100

export var WRAPAROUND_Y = 600.0
export var WRAPAROUND_X = 1024.0

export var AVOID_MIN_DIST = 40

export var AVOID_FAC = 6000
export var COHESION_FAC = 10
export var ALIGNMENT_FAC = 10
export var NOISE_FAC = 1000

var velocity = Vector2(1, 1) * SPEED
var middle_indicator = Circle.new()
var nearby = []

var rng = RandomNumberGenerator.new()

func _ready():
	if Engine.editor_hint:
		var circle = Circle.new()
		circle.RADIUS = VISUAL_RANGE
		add_child(circle)
		return

	middle_indicator.RADIUS = 10
	middle_indicator.COLOR = Color.red
	# Spawn circle
	#var circle = Circle.new()
	#circle.RADIUS = VISUAL_RANGE
	#add_child(circle)
	#add_child(middle_indicator)
	add_to_group("boids")

	# Rotate random
	rng.randomize()
	var angle = rng.randf_range(-PI, PI)
	velocity = Vector2(sin(angle), cos(angle)) * SPEED

func get_nearby_boids():
	nearby = []
	for boid in get_parent().get_children():
		if boid == self:
			continue
		
		var distance = position.distance_to(boid.position)

		if distance < VISUAL_RANGE:
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

func noise_bias() -> Vector2:
	var random_angle = rng.randf_range(-PI, PI)
	return Vector2(sin(random_angle), cos(random_angle)) * NOISE_FAC

func _physics_process(delta):
	get_nearby_boids()

	# Every bias function returns the optimal vector that they want to be in.
	# That is multiplied by the factor of each of those biases
	# Calculate the new velocity
	var alignment = alignment_bias()
	var cohesion = cohesion_bias()
	var avoidance = avoidance_bias()
	var noise = noise_bias()

	# The average of this vector
	var ideal_velocity = (alignment + cohesion + avoidance + noise) / 4

	# Interpolate our velocity by the ideal velocity with an alpha of 0.5 * second
	velocity = velocity.linear_interpolate(ideal_velocity, 0.5 * delta)

	# Scale new velocity to speed
	velocity = velocity.normalized() * SPEED

	# Render rotation
	rotation = velocity.angle() + 0.5*PI

	# Move boid with wraparound
	var next_pos = position + (velocity * delta)
	next_pos = Vector2(fposmod(next_pos.x, WRAPAROUND_X), fposmod(next_pos.y, WRAPAROUND_Y))
	position = next_pos
	pass
