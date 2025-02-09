extends Node3D

var initial_position: Vector3
var initial_rotation: Vector3
var is_inspecting = false

func _ready():
	# Store initial position and rotation
	initial_position = position
	initial_rotation = rotation
	_load_image_texture()
	# Connect to the input_event signal of the StaticBody3D
	var static_body = get_node("StaticBody3D")
	
func is_click_on_photo(event: InputEvent) -> bool:
	if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		return false
	
	var camera = get_viewport().get_camera_3d()
	if not camera:
		return false
	
	# Perform a raycast from the mouse position
	var mouse_pos = get_viewport().get_mouse_position()
	var from = camera.project_ray_origin(mouse_pos)
	var to = from + camera.project_ray_normal(mouse_pos) * 1000.0
	var space_state = get_world_3d().direct_space_state
	var params = PhysicsRayQueryParameters3D.create(from, to)
	var result = space_state.intersect_ray(params)
	
	# Check if the hit collider is THIS photo's StaticBody3D
	if result and result.collider == get_node("StaticBody3D"):
		return true
	return false

func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if is_inspecting:
			# If inspecting, clicking anywhere (including other photos) toggles inspect off
			toggle_inspect()
		else:
			# If not inspecting, check if the click was on THIS photo
			if is_click_on_photo(event):
				print("Photo clicked:", name)
				toggle_inspect()

func _load_image_texture():
	var texture = null
	var extensions = ["png", "jpg"]
	# Since you named the instance with file_name.get_basename()
	# We just need to try loading with each extension using the instance's name
	for ext in extensions:
		var image_path = "res://images/" + name + "." + ext
		texture = load(image_path)
		if texture is Texture2D:
			print("Successfully loaded texture: ", image_path)
			break
	
	if texture is Texture2D:
		var soft_body = get_node("StaticBody3D/MeshInstance3D")
		if soft_body:
			var material = StandardMaterial3D.new()
			material.albedo_texture = texture
			soft_body.set_surface_override_material(0, material)
	else:
		push_error("Failed to load texture at runtime for: " + name)

func toggle_inspect():
	is_inspecting = !is_inspecting
	var light = get_node("OmniLight3D")
	
	if is_inspecting:
		var camera = get_viewport().get_camera_3d()
		if camera:
			# Calculate target global position
			var camera_forward = -camera.global_transform.basis.z
			var inspect_position = camera.global_position + camera_forward * 0.15
			
			# Save original transform
			var original_transform = global_transform
			
			# Temporarily move to inspection position in global space
			global_position = inspect_position
			# Reset rotation and align Y axis to face camera
			global_rotation = Vector3.ZERO
			look_at(camera.global_position) # Points -Z towards camera
			rotate_object_local(Vector3.LEFT, PI/2) # Face correctly
			rotate_object_local(Vector3.UP, PI) # Rotate so top if image is top
			var target_rot = rotation
			
			# Restore original transform before tweening
			global_transform = original_transform
			
			# Tween to target position and rotation
			var tween = create_tween()
			tween.set_parallel(true)
			tween.tween_property(self, "global_position", inspect_position, 0.5)
			tween.tween_property(self, "rotation", target_rot, 0.5)
			light.visible = true
	else:
		# Tween back to initial state
		var tween = create_tween()
		tween.set_parallel(true)
		tween.tween_property(self, "position", initial_position, 0.5)
		tween.tween_property(self, "rotation", initial_rotation, 0.5)
		light.visible = false
