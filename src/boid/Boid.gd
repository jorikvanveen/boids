extends KinematicBody2D

const E = 2.71828

export var VISUAL_RANGE = 100.0
export var SPEED = 50

export var WRAPAROUND_Y = 600.0
export var WRAPAROUND_X = 1024.0

var velocity = Vector2(1, 1) * SPEED
var middle_indicator = Circle.new()

func _ready():
	if Engine.editor_hint:
		var circle = Circle.new()
		circle.RADIUS = VISUAL_RANGE
		add_child(circle)
		return

	middle_indicator.RADIUS = 10
	middle_indicator.COLOR = Color.red
	# Spawn circle
	var circle = Circle.new()
	circle.RADIUS = VISUAL_RANGE
	add_child(circle)
	add_child(middle_indicator)
	add_to_group("boids")

	print("ANGLES")
	print(rad2deg(Vector2(1, 1).angle_to(Vector2(1, 0))))
	velocity = velocity.rotated(deg2rad(rand_range(0, 360)))

	

	

func to_orientation(vec: Vector2):
	return asin(vec.y/sqrt(pow(vec.x, 2) + pow(vec.y, 2)))

func get_other_boids() -> Array:
	var all_boids = get_parent().get_children()
	var own_idx = all_boids.find(self)
	all_boids.remove(own_idx)
	return all_boids

func get_close_boids() -> Array:
	var other_boids = get_other_boids()
	var close_boids = []

	for boid in other_boids:
		# Get distance to other boid
		var distance = (self.position - boid.position).length()
		if distance < VISUAL_RANGE:
			close_boids.push_back(boid)

	return close_boids

func _physics_process(delta):
	if Engine.editor_hint:
		return
	# Get boids close to us
	var close_boids = get_close_boids()	

	# Get best vector for cohesion, (the average of all boids around us)
#	var average_velocity = self.velocity
	var average_velocity = Vector2.ZERO
	var average_position = self.position
	for boid in close_boids:
		average_velocity += boid.velocity
		average_position += boid.position

	average_velocity = average_velocity / (close_boids.size())
	average_position = average_position / (close_boids.size()+1)
	middle_indicator.POSITION = to_local(average_position)
	middle_indicator.update()

	var center_distance = self.position.distance_to(average_position)
	# Angle between the vector of our velocity, and the vector from our position to average_position
	# If you add this to the current rotation, you will be facing the average_position exactly
	var angle_to_center = velocity.angle_to(average_position - self.position)
	# Value between -1 to 1 which determines how much correction is needed
	var wrongness = (angle_to_center/PI) * (center_distance/VISUAL_RANGE)
	var cohesion_angle_correction = wrongness * deg2rad(10)

	# Get best vector for seperation
	# Get best vector for alignment
	# Average out all these vectors
	
	velocity = velocity.rotated(cohesion_angle_correction)
#	velocity = velocity.linear_interpolate(average_velocity, 0)
	velocity = velocity + (average_velocity - velocity) * 0.05
	translate(velocity * delta)
	# Change rotation based on velocity
	rotation = velocity.angle() + deg2rad(90)
	# Wraparound
	position = Vector2(fposmod(position.x, WRAPAROUND_X), fposmod(position.y, WRAPAROUND_Y))
