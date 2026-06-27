extends Node
class_name NavmeshManager

static var Instance: NavmeshManager:
	get:
		return NavmeshManagerInstance

func RebakeNavmeshForActor(actor: Actor) -> void:
	rebakeNavmesh([actor])

func rebakeNavmesh(exceptions: Array) -> void:
	var total_start := Time.get_ticks_usec()

	var characters := get_tree().current_scene.find_children("*", "Actor", true, false)
	var regions := get_tree().current_scene.find_children("*", "NavigationRegion3D", true, false)

	for region: NavigationRegion3D in regions:
		var nav_mesh := region.navigation_mesh
		if nav_mesh == null:
			continue

		var region_start := Time.get_ticks_usec()

		var source := NavigationMeshSourceGeometryData3D.new()

		var parse_start := Time.get_ticks_usec()
		NavigationServer3D.parse_source_geometry_data(nav_mesh, source, region)
		var parse_us := Time.get_ticks_usec() - parse_start

		var inject_start := Time.get_ticks_usec()
		for c: Actor in characters:
			if exceptions.has(c):
				continue
			var col: CollisionShape3D = c.get_node_or_null("CollisionShape3D")
			if col and col.shape:
				var faces := col.shape.get_debug_mesh().get_faces()
				source.add_faces(faces, col.global_transform)
		var inject_us := Time.get_ticks_usec() - inject_start

		var bake_start := Time.get_ticks_usec()
		NavigationServer3D.bake_from_source_geometry_data_async(nav_mesh, source)
		var bake_us := Time.get_ticks_usec() - bake_start

		var region_us := Time.get_ticks_usec() - region_start
		print("[navbake] %s: parse %.2f ms | inject %.2f ms | bake %.2f ms | total %.2f ms" % [
			region.name,
			parse_us / 1000.0,
			inject_us / 1000.0,
			bake_us / 1000.0,
			region_us / 1000.0,
		])

	var total_ms := (Time.get_ticks_usec() - total_start) / 1000.0
	print("[navbake] all regions done in %.2f ms" % total_ms)
