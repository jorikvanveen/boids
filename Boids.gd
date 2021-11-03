extends Node

func _ready():
	var Boid = load("res://src/boid/Boid.tscn")
	for i in range(50):
		var boid = Boid.instance()
		boid.position = Vector2(rand_range(0, 1000),rand_range(0,600))
		add_child(boid)
