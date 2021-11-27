extends Node

var threads = []

var NUM_THREADS = OS.get_processor_count()
const DO_THREADING = true
func _ready():
	var Boid = load("res://src/boid/Boid.tscn")
	for _i in range(70):
		var boid = Boid.instance()
		boid.position = Vector2(rand_range(0, 1000),rand_range(0,600))
		add_child(boid)

func run_physics_threads(args):
	var batch = args[0]
	var delta = args[1]
	for boid in batch:
		boid.physics_thread(delta)

func _physics_process(delta):
	# Run every physics process of the boids on a seperate thread

	# Divide boids into different arrays
	var children = get_children()
	
	if not DO_THREADING:
		run_physics_threads([children, delta])
		return

	var boid_batch_size = floor(children.size() / 12)
	var boid_batches = []

	for batch_idx in range(NUM_THREADS):
		# Put rest of batches in final thing
		if batch_idx == (NUM_THREADS-1):
			boid_batches.push_back(children)

		var batch = []
		for _i in range(boid_batch_size):
			batch.push_back(children.pop_front())

		boid_batches.push_back(batch)
			
	
	for batch in boid_batches:
		var thread = Thread.new()
		thread.start(self, "run_physics_threads", [batch, delta])
		threads.push_back(thread)
	
	for thread in threads:
		thread.wait_to_finish()

	threads = []


func _on_HSlider_value_changed(value, variable):
	# Loop trough children and set each variable and label
	for boid in get_children():
		boid.set(variable, value)
	get_node('../CheckBox/Speed/Label4').text = str(get_node('../CheckBox/Speed').value)
	get_node('../CheckBox/VisualRange/Label4').text = str(get_node('../CheckBox/VisualRange').value)
	get_node('../CheckBox/AvoidDistance/Label4').text = str(get_node('../CheckBox/AvoidDistance').value)
	get_node('../CheckBox/Alignment/Label4').text = str(get_node('../CheckBox/Alignment').value)
	get_node('../CheckBox/Cohesion/Label4').text = str(get_node('../CheckBox/Cohesion').value)


# Hide sliders
func _on_CheckBox_pressed():
	for child in get_node('../CheckBox').get_children():
		child.visible = !child.visible

func _on_Pause_pressed():
	get_tree().paused = not get_tree().paused
