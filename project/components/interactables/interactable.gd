extends Node3D

@onready var notifier = $VisibleOnScreenNotifier3D
@onready var mesh = $MeshInstance3D

var mat_dither : Material = preload("res://assets/materials/mat_dither.tres")
const MAT_ALPHA = preload("res://assets/materials/mat_alpha.tres")
const MAT_STATIC = preload("res://assets/materials/mat_static.tres")
const MAT_GRAVITY = preload("res://assets/materials/mat_gravity.tres")
const MAT_RIPPLES = preload("res://assets/materials/mat_ripples.tres")
const MAT_RIGID = preload("res://assets/materials/mat_rigid.tres")

@onready var area = $Area3D
@onready var stat = $StaticBody3D
#@onready var rigd = $RigidBody3D
@onready var fog = $FogVolume


@export var active_threshold : float = 0.6
@export var default_active : bool = false
@export var default_type : String = 'static'

func _ready():
	#mat_dither = mesh.get_active_material(0).duplicate()
	#rigd.mass = 4.0 * scale.length()
	
	if default_active:
		if default_type == 'static':
			mesh.set_surface_override_material(0,MAT_STATIC)
			stat.set_collision_layer_value(1,default_active)
		elif default_type == 'gravity':
			mesh.set_surface_override_material(0,MAT_RIPPLES)
			area.monitoring = default_active
			fog.visible = true
		elif default_type == 'gravity':
			mesh.set_surface_override_material(0,MAT_RIGID)
			#rigd.set_collision_layer_value(1,default_active)
	else:
		mesh.set_surface_override_material(0,MAT_ALPHA)


func set_interactive(depth,zoom,battery_type):
	print(depth," ",zoom," ",battery_type)
	if !battery_type: return
	
	var check = depth/zoom
	if check < active_threshold:
		disable_active()
		if battery_type == 'static':
			stat.set_collision_layer_value(1,true)
			mesh.set_surface_override_material(0,MAT_STATIC)
		elif battery_type == 'gravity':
			area.monitoring = true
			fog.visible = true
			mesh.set_surface_override_material(0,MAT_RIPPLES)
		elif battery_type == 'rigid':
			#rigd.set_collision_layer_value(1,true)
			mesh.set_surface_override_material(0,MAT_RIGID)
	else:
		disable(depth,zoom)

func disable_active():
	stat.set_collision_layer_value(1,false)
	area.monitoring = false
	fog.visible = false
	#rigd.set_collision_layer_value(1,false)

func disable(_depth,_zoom):
	disable_active()
	#var alp = clamp(1/depth/zoom,0.1,0.5)
	#if default_active: alp = 1.0
	mesh.set_surface_override_material(0,MAT_ALPHA)
	#var new_color = Color(1.0,1.0,1.0, alp)
	#mat_dither.set_shader_parameter("color",new_color)
	


func _on_area_3d_body_entered(body):
	if body.is_in_group("player"):
		var player = body
		if area.monitoring:
			player.in_water = true

func _on_area_3d_body_exited(body):
	if body.is_in_group("player"):
		var player = body
		if area.monitoring:
			player.in_water = false
