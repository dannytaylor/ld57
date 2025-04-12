extends RigidBody3D

#debug
var DEBUG : bool = true
var has_camera : bool = true if DEBUG else false
var debug_world = 3

@onready var camera_tps_mesh = $VisualRoot/BoneAttachment3D/camera_tps
@onready var pause_menu = $UI/PauseMenu



@export var jump_height : float = 0.5
@export var jump_time_to_peak : float = 0.4
@export var jump_time_to_descent : float = 0.35
const COYOTE : float = 0.1
var coyote : float = COYOTE

@onready var jump_velocity : float = ((1.9 * jump_height) / jump_time_to_peak) * -1.0
@onready var jump_gravity : float = ((-2.0 * jump_height) / (jump_time_to_peak * jump_time_to_peak)) * -1.0
@onready var fall_gravity : float = ((-2.0 * jump_height) / (jump_time_to_descent * jump_time_to_descent)) * -1.0
var in_water : bool = false
@onready var bubbles = $Bubbles

@export var base_speed = 0.5
@export var run_speed = 10.0
@export var speed : float = 0.0
@export var speed_lerp : float = 0.06

@onready var visual_root = %VisualRoot
@onready var godot_plush_skin = $VisualRoot/GodotPlushSkin
@onready var movement_dust = %MovementDust

@onready var foot_step_audio = %FootStepAudio
@onready var impact_audio = %ImpactAudio
@onready var wave_audio = %WaveAudio
@onready var crank_audio = %CrankAudio
@onready var shutter_audio = %ShutterAudio
@onready var empty_audio = %EmptyAudio
@onready var jump_audio = %JumpAudio

@onready var collision_shape_3d = %CollisionShape3D
@onready var fps_pivot = $VisualRoot/fpsPivot
@onready var camera_tps = $OrbitView/Camera3D
@onready var orbit_view = $OrbitView
@onready var camera_fps = $VisualRoot/fpsPivot/CameraFPS
@onready var shutter_timer = %ShutterTimer
@onready var shutter_delay = %ShutterDelay
@onready var camera_anim = $VisualRoot/fpsPivot/CameraFPS/cameraMesh/cameraAnim

#@onready var quad_depth = $VisualRoot/fpsPivot/CameraFPS/QuadDepth
@onready var quad_depth = $VisualRoot/fpsPivot/CameraFPS/cameraMesh/camera
@onready var camera_mesh = $VisualRoot/fpsPivot/CameraFPS/cameraMesh
var camera_mesh_pos : Vector3
var quad_depth_material : Material
var camera_emission_material : Material


const JUMP_PARTICLES_SCENE = preload("./vfx/jump_particles.tscn")
const LAND_PARTICLES_SCENE = preload("./vfx/land_particles.tscn")

var movement_input : Vector2 = Vector2.ZERO
var target_angle : float = 0.0
var last_movement_input : Vector2 = Vector2.ZERO

var _is_on_floor : bool = false
var _was_on_floor : bool = false
var double_jump : bool = true
var fps_mode : bool = false

var fps_zoom : float = 24
var fps_zoom_STEP : float = 8
var fps_zoom_MIN : float = 8
var fps_zoom_MAX : float = 48
var fps_SENSE = 0.002
var fps_ROT_RESET : Vector3

var action_lock : bool = false
var door_enter : bool = false
var walk_target : Vector3
@onready var fade_out = $UI/FadeOut
@onready var level_switch = $UI/LevelSwitch
var next_level : int = 0

var batteries = []
@onready var battery_ui = $UI/tps/Battery
@onready var ui_tps = $UI/tps
@onready var ui_fps = $UI/fps

@onready var music = $Music

# The “_integrate_forces” method is a quick translation of the integration of the character's body movements.
# This code is not optimal; perhaps “move_and_collide” should be used to check is_on_floor.

func _ready():
	
	if DEBUG: 
		#music.play()
		camera_tps_mesh.visible = true
	
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	camera_tps.current = true
	fps_ROT_RESET = fps_pivot.rotation
	camera_mesh_pos = camera_mesh.position
	camera_mesh.position -= Vector3(0,0.3,0.0)
	
	godot_plush_skin.waved.connect(wave_audio.play)
	godot_plush_skin.footstep.connect(func(intensity : float = 1.0):
		foot_step_audio.volume_db = linear_to_db(intensity)
		foot_step_audio.play()
		)
		
	quad_depth.visible = true
	quad_depth_material = quad_depth.get_active_material(0)
	quad_depth_material.set_shader_parameter("depth_factor",fps_zoom)
	camera_emission_material = quad_depth.get_active_material(3)

func _unhandled_input(event):
	if pause_menu.visible:
		if event.is_action_pressed("e",true):
			pause_menu.visible = false
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		if event.is_action_pressed("esc",true):
			get_tree().quit()
	else:
		if event.is_action_pressed("esc",true):
			pause_menu.visible = true
		if !action_lock:
			if fps_mode:
				# this is not correct
				if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
					fps_pivot.rotate_y(-event.relative.x * fps_SENSE)
					camera_fps.rotate_x(event.relative.y * fps_SENSE)
					camera_fps.rotation.x = clamp(camera_fps.rotation.x, -0.8, 0.8)
					camera_fps.rotation.z = 0
					
				
				if event.is_action_pressed("e",true):
					if fps_zoom < fps_zoom_MAX:
						fps_zoom = min(fps_zoom+fps_zoom_STEP,fps_zoom_MAX)
						camera_anim.play("dialCCW")
						quad_depth_material.set_shader_parameter("depth_factor",fps_zoom)
						crank_audio.play()
					else:
						empty_audio.play()
					camera_zoom()
					#print(fps_zoom)
					
				if event.is_action_pressed("q",true):
					if fps_zoom > fps_zoom_MIN:
						fps_zoom = max(fps_zoom-fps_zoom_STEP,fps_zoom_MIN)
						camera_anim.play("dialCW")
						quad_depth_material.set_shader_parameter("depth_factor",fps_zoom)
						crank_audio.play()
					else:
						empty_audio.play()
					camera_zoom()
					#print(fps_zoom)
					
				if event.is_action_pressed("shoot",true):
					if len(batteries)>0:
						shutter_audio.play()
						camera_interact(batteries.pop_back())
						battery_ui.visible = false
						
						camera_emission_material.emission = Color("#EC273F")
						shutter_delay.start(0.4)
					else:
						empty_audio.play()
						camera_interact(null)
			
			if event.is_action_pressed("camera") and has_camera:
				if _is_on_floor:
					fps_mode = !fps_mode
					ui_fps.visible = fps_mode
					ui_tps.visible = !fps_mode
					# switching to 1st p
					
					#switching to 1st p
					if fps_mode:
						camera_zoom()
						camera_fps.current = fps_mode
						fps_pivot.rotation = Vector3.ZERO
						fps_pivot.global_rotation.y = orbit_view.global_rotation.y - PI
						camera_fps.rotation = Vector3.UP*PI
						#fps_pivot.rotation.y += orbit_view.rotation.y + PI/2
					
					#switching to 3rd p
					elif !camera_tps.current:
						shutter_timer.start(0.3)
			
			
func _process(delta):
	if fps_mode:
		camera_mesh.position = lerp(camera_mesh.position,camera_mesh_pos,0.04)
	else:
		camera_mesh.position = lerp(camera_mesh.position,camera_mesh_pos-Vector3(0.06,0.35,0.6),0.016)
		
	if fade_out.visible:
		if door_enter:
			fade_out.modulate = lerp(fade_out.modulate,Color(0,0,0, 1.0),0.016)
		else:
			fade_out.modulate = lerp(fade_out.modulate,Color(0,0,0, 0.0),0.016)
			if fade_out.modulate.a == 0.0:
				fade_out.visible = false
	
	if !_is_on_floor and coyote > 0.0:
		coyote -= delta

	if DEBUG and debug_world:
		get_parent().new_world(debug_world)
		debug_world = false
			

func _integrate_forces(state : PhysicsDirectBodyState3D):
	if !pause_menu.visible:
		var camera : Camera3D = get_viewport().get_camera_3d()
		if camera == null: return
		#var is_waving : bool = godot_plush_skin.is_waving()
		if !fps_mode and !action_lock:
			movement_input = Input.get_vector("left", "right", "up", "down").rotated(-camera.global_rotation.y)		
		else:
			movement_input = Vector2.ZERO
		#var is_running : bool = Input.is_action_pressed("run")
		var is_running : bool = true # no walk sRandomNumberGenerator
		if door_enter:
			is_running = false
			speed = base_speed
			var walk_dir = position.direction_to(walk_target)
			movement_input = Vector2(walk_dir.x,walk_dir.z)
		var vel_2d = Vector2(state.linear_velocity.x, state.linear_velocity.z)
		var is_moving : bool = movement_input != Vector2.ZERO

		if is_moving and !fps_mode:
			godot_plush_skin.set_state("run" if is_running else "walk")
			speed = lerp(speed,run_speed,speed_lerp)
			vel_2d += movement_input * speed * 8.0 * state.step
			vel_2d = vel_2d.limit_length(speed)
			state.linear_velocity.x = vel_2d.x
			state.linear_velocity.z = vel_2d.y
			target_angle = -movement_input.orthogonal().angle()
		else:
			godot_plush_skin.set_state("idle")
			speed = lerp(speed,0.0,speed_lerp)

		visual_root.rotation.y = rotate_toward(visual_root.rotation.y, target_angle, 6.0 * state.step)
		var angle_diff = angle_difference(visual_root.rotation.y, target_angle)
		godot_plush_skin.tilt = move_toward(godot_plush_skin.tilt, angle_diff, 2.0 * state.step)

		_is_on_floor = _get_is_on_floor(state)

		movement_dust.emitting = is_moving && is_running && _is_on_floor

		# Check jump and fall 
		if _is_on_floor or double_jump:
			if Input.is_action_just_pressed("space"):
				var jump_particles = JUMP_PARTICLES_SCENE.instantiate()
				add_sibling(jump_particles)
				jump_particles.global_transform = global_transform
				jump_audio.play()
				
				
				# use up double jump (maybe use int instead lol)
				if !_is_on_floor && double_jump:
					if !(coyote > 0):
						double_jump = false
						godot_plush_skin.set_state("jump",true)
						state.linear_velocity.y = -jump_velocity
					
				else:
					godot_plush_skin.set_state("jump")
					state.linear_velocity.y = -jump_velocity

				do_squash_and_stretch(1.2, 0.1)
				
		else:
			godot_plush_skin.set_state("fall")

		# Add ground friction
		physics_material_override.friction = 0.0 if is_moving else 0.8

		# Add air damp when not moving
		#if !_is_on_floor && !is_moving:
			#vel_2d = vel_2d.move_toward(Vector2.ZERO, base_speed * state.step)
			#linear_velocity.x = lerp(linear_velocity.x,vel_2d.x,0.01)
			#linear_velocity.z = lerp(linear_velocity.z,vel_2d.y,0.01)

		# Add gravity
		var gravity = jump_gravity if state.linear_velocity.y > 0.0 else fall_gravity
		if in_water: 
			gravity = gravity/2.5
			bubbles.visible = true
		else:
			bubbles.visible = false
		state.linear_velocity.y -= gravity * state.step
		state.linear_velocity = state.linear_velocity.limit_length(fall_gravity)

		# Add ground collision feedback
		if !_was_on_floor && _is_on_floor:
			_on_hit_floor(state.linear_velocity.y)
			coyote = COYOTE
		_was_on_floor = _is_on_floor
	
func _get_is_on_floor(state : PhysicsDirectBodyState3D) -> bool:
	for col_idx in state.get_contact_count():
		var col_normal = state.get_contact_local_normal(col_idx)
		print(col_normal.y)
		if col_normal.y > 0.2: 
			return col_normal.dot(Vector3.UP) > -0.5  
	return false

func _on_hit_floor(y_vel : float):
	y_vel = clamp(abs(y_vel), 0.0, fall_gravity)
	var floor_impact_percent : float = y_vel / fall_gravity
	impact_audio.volume_db = linear_to_db(remap(floor_impact_percent, 0.0, 1.0, 0.5, 2.0))
	impact_audio.play()
	var land_particles = LAND_PARTICLES_SCENE.instantiate()
	add_sibling(land_particles)
	land_particles.global_transform = global_transform
	do_squash_and_stretch(0.7, 0.08)
	double_jump = true 

func do_squash_and_stretch(value : float, timing : float = 0.1):
	var t = create_tween()
	t.set_ease(Tween.EASE_OUT)
	t.tween_property(godot_plush_skin, "squash_and_stretch", value, timing)
	t.tween_property(godot_plush_skin, "squash_and_stretch", 1.0, timing * 1.8)

func camera_interact(battery_type):
	var interactables = get_tree().get_nodes_in_group("interactable")
	for i in interactables:
		var depth = position.distance_to(i.position)
		if i.notifier.is_on_screen():
			# calc distance from player on zoom scale
			# call iteractive function as needed
			i.set_interactive(depth,fps_zoom,battery_type)
		else:
			i.disable(depth,fps_zoom)

func camera_zoom():
	var interactables = get_tree().get_nodes_in_group("interactable")
	for i in interactables:
		var depth = position.distance_to(i.position)
		i.check_zoom(depth/fps_zoom)


func _on_shutter_timer_timeout():
	camera_tps.current = !fps_mode
	ui_fps.visible = fps_mode
	ui_tps.visible = !fps_mode
	
	orbit_view.rotation.x = -PI/6
	orbit_view.global_rotation.y = fps_pivot.global_rotation.y - PI

func _on_shutter_delay_timeout():
	fps_mode = false
	shutter_timer.start(0.3)

func _on_level_switch_timeout():
	door_enter = false
	action_lock = false
	position = Vector3.ZERO
	
	batteries = []
	battery_ui.visible = false
	camera_emission_material.emission = Color("#EC273F")
	fps_zoom = 24
	
	get_parent().new_world(next_level)	
	# reset to origin
	
