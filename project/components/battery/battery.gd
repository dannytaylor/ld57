extends Node3D

@export var battery_type : String = 'static'
@onready var mesh = $mesh

@export var colour : Color
var mat : Material

@onready var sfx = $sfx

func _ready():
	mat = mesh.get_active_material(0).duplicate()
	mat.albedo_color = colour
	mesh.set_surface_override_material(0,mat)
	

func _on_area_3d_body_entered(body):
	if body.is_in_group("player"):
		var player = body
		sfx.play()
		player.batteries = [battery_type]
		player.camera_emission_material.emission = Color("#9DE64E")
		
		player.battery_ui.visible = true
		if battery_type == 'static': player.battery_ui.modulate = Color("#f3df5f")
		else: player.battery_ui.modulate = Color("#36c5f4")
