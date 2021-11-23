extends KinematicBody2D

const E = 2.71828

export var VISUAL_RANGE = 100.0
export var SPEED = 50

export var WRAPAROUND_Y = 600.0
export var WRAPAROUND_X = 1024.0

export var AVOID_FAC = 0.05

#var velocity = Vector2(1, 1) * SPEED
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
	
func to_center(close_boids, factor):
	var velocity = Vector2(0, 0)
	
	for boid in close_boids:
		velocity += boid.position

	velocity = velocity / close_boids.size()
	velocity = velocity - self.position
	return velocity * factor

func avoid_boids():
	var factor = AVOID_FAC
	var distance = 20
	var velocity = Vector2(0, 0)
	
	for boid in get_parent().get_children():
		if(boid != self):
			if(self.position.distance_to(boid.position) < distance):
				velocity = self.position - boid.position
	
	return velocity * factor

func _physics_process(delta):
	var close_boids = []
	for boid in get_parent().get_children():
		if(self.position.distance_to(boid.position) < VISUAL_RANGE):
			close_boids.push_back(boid)

	var velocity = Vector2.ZERO
	velocity += to_center(close_boids, 0.05)
	velocity += avoid_boids()

	velocity *= 10
	var angle = velocity.angle() + deg2rad(90)
	print(angle)
	self.rotation = angle
	translate(velocity * delta)
#	var angle = self.position.angle_to_point(velocity)
#	velocity = velocity.rotated(angle)
#	rotate(angle)
	

