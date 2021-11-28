extends StaticBody2D

export var VISUAL_RANGE = 40.0
export var SPEED = 300

export var WRAPAROUND_Y = 600.0
export var WRAPAROUND_X = 1024.0

export var AVOID_MIN_DIST = 20

export var AVOID_FAC = 25
export var COHESION_FAC = 30
export var ALIGNMENT_FAC = 20
export var NOISE_FAC = 1000

export var OUT_OF_BOUNDS_DIST = 100

var velocity = Vector2(1, 1) * SPEED
var middle_indicator = Circle.new()
var nearby = []
var too_close = []
var closest_boid
var closest_distance = 0

var rng = RandomNumberGenerator.new()
var center

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
	#var circle = Circle.new()
	#circle.RADIUS = VISUAL_RANGE
	#add_child(circle)
	#add_child(middle_indicator)
	#add_to_group("boids")

	# Rotate random
	rng.randomize()
	var angle = rng.randf_range(-PI, PI)
	velocity = Vector2(sin(angle), cos(angle)) * SPEED
	center = Vector2(WRAPAROUND_X/2, WRAPAROUND_Y/2)
	
func get_nearby_boids():
	nearby = []
	too_close = []
	closest_distance = 1e20
	var dist_squared = VISUAL_RANGE * VISUAL_RANGE
	var too_close_squared = AVOID_MIN_DIST * AVOID_MIN_DIST
	for boid in get_parent().get_children():
		if boid == self:
			continue
		
		# Squared so it doesn't have to take the square root every frame and we save some cpu power
		var distance = position.distance_squared_to(boid.position)
		if distance < closest_distance:
			closest_distance = distance
			closest_boid = boid

		if distance < too_close_squared:
			too_close.push_back(boid)
		if distance < dist_squared:
			nearby.push_back(boid)
	
	closest_distance = sqrt(closest_distance)

func average_pos_nearby() -> Vector2:
	var average_position = Vector2.ZERO

	for boid in nearby:
		average_position += boid.position
	
	if not average_position:
		return position

	average_position /= nearby.size()

	return average_position

func avoidance_bias() -> Vector2:
	if closest_distance < AVOID_MIN_DIST:
		var ideal_vec = (position - closest_boid.position) 
		return ideal_vec / pow(ideal_vec.length(), 2) * AVOID_FAC * 1000

	return velocity

func anti_out_of_bounds() -> Vector2:
	var out_of_bounds = false
	if WRAPAROUND_Y - position.y < OUT_OF_BOUNDS_DIST or position.y < OUT_OF_BOUNDS_DIST:
		out_of_bounds = true

	if WRAPAROUND_X - position.x < OUT_OF_BOUNDS_DIST or position.x < OUT_OF_BOUNDS_DIST:
		out_of_bounds = true
	
	if out_of_bounds:
		return (center - position).normalized() * 10

	return velocity

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
		ideal_velocity = (ideal_velocity.normalized() * 0.7 + out_of_bounds_vec.normalized() * 0.3) * SPEED * 5

	# Interpolate our velocity to the ideal velocity
	velocity = velocity.linear_interpolate(ideal_velocity, SPEED/100 * delta)

	# Scale new velocity to speed
	if velocity.length() > SPEED:
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
