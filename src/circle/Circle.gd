tool
extends Node2D

class_name Circle

export var POSITION = Vector2.ZERO
export var RADIUS = 10
export var COLOR = Color(1, 1, 1, 0.5)

func _draw():
	draw_circle(POSITION, RADIUS, COLOR)