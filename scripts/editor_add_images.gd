@tool
extends EditorScript

func _run():
	var current_scene = get_scene()
	var dir = DirAccess.open("res://images")
	
	if not dir:
		push_error("Failed to access res://images. Does the directory exist?")
		return
	
	var target_node = current_scene  # Ensure "Desk" exists
	if not target_node:
		push_error("Target node not found.")
		return
	
	dir.list_dir_begin()
	var file_name = dir.get_next()
	
	while file_name != "":
		if file_name.get_extension() in ["png", "jpg"]:
			var image_path = "res://images/" + file_name
			var texture = load(image_path) as Texture2D
			texture.resource_local_to_scene = true
			
			if texture is Texture2D:
				var scene = preload("res://scenes/photo.tscn")
				var instance = scene.instantiate()
				instance.name = file_name.get_basename()
				
				instance.position = Vector3(
					randf_range(-1.7, -1.1),
					randf_range(0.795, 0.8),
					randf_range(-0.8, 0.8)
				)
				instance.rotation = (Vector3(0, randf_range(0, 360), 0))
				
				var soft_body = instance.get_node("StaticBody3D/MeshInstance3D")  # Confirm node path
				if soft_body:
					var material = StandardMaterial3D.new()
					if material:
						material = material.duplicate()
						material.albedo_texture = texture  # Simplified for clarity
						material.resource_local_to_scene = true
						soft_body.set_surface_override_material(0, material)
						print("Applied texture to: ", instance.name)
					else:
						push_error("No material found on surface 0 of SoftBody3D.")
				else:
					push_error("SoftBody3D node not found in instance.")
				
				target_node.add_child(instance)
				instance.owner = current_scene  # Ensures persistence
			else:
				push_error("Failed to load texture: ", image_path)
		
		file_name = dir.get_next()
	
	dir.list_dir_end()
