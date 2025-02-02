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
	static_body.input_event.connect(_on_static_body_input_event)

func _on_static_body_input_event(_camera, event, _position, _normal, _shape_idx):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			print("Photo clicked:", name)  # Debug print
			toggle_inspect()

func _mouse_click_on_photo(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var camera = get_viewport().get_camera_3d()
		if camera:
			var from = camera.project_ray_origin(event.position)
			var to = from + camera.project_ray_normal(event.position) * 1000
			var space = get_world_3d().direct_space_state
			var query = PhysicsRayQueryParameters3D.create(from, to)
			var result = space.intersect_ray(query)
			if result and (result.collider == $StaticBody3D/MeshInstance3D or result.collider == self):
				print("Clicked on photo:", name)
				return true
			return false
	
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
	else:
		# Tween back to initial state
		var tween = create_tween()
		tween.set_parallel(true)
		tween.tween_property(self, "position", initial_position, 0.5)
		tween.tween_property(self, "rotation", initial_rotation, 0.5)
