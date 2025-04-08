extends Node3D

@onready var w1 = preload("res://assets/levels/world1.tscn")
@onready var w2 = preload("res://assets/levels/world2.tscn")
@onready var w3 = preload("res://assets/levels/world3.tscn")
@onready var w4 = preload("res://assets/levels/world4.tscn")
@onready var w5 = preload("res://assets/levels/world5.tscn")
@onready var w6 = preload("res://assets/levels/world6.tscn")
@onready var w7 = preload("res://assets/levels/world7.tscn")
@onready var w8 = preload("res://assets/levels/world8.tscn")

var worlds = []
var current_world

func _ready():
	worlds = [w1,w2,w3,w4,w5,w6,w7,w8]
	current_world = w1.instantiate()
	add_child(current_world)

func new_world(scene_number):
	current_world.queue_free()
	current_world = worlds[scene_number].instantiate()
	add_child(current_world)
