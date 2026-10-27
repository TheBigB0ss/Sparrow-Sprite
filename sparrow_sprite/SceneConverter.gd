class_name SceneHandler extends Node

func create_res_file(data_path, anim, have_loop, fps):
	var frames_data = _read_frames(data_path);
	
	if frames_data.is_empty():
		return;
		
	var texture_path = data_path.get_basename() + ".png";
	
	var anim_spriteFrames = SpriteFrames.new();
	anim_spriteFrames.remove_animation("default");
	
	for anim_name in frames_data:
		var frames = frames_data[anim_name];
		
		if frames.is_empty():
			continue;
			
		anim_spriteFrames.add_animation(anim_name);
		anim_spriteFrames.set_animation_loop(anim_name, have_loop);
		anim_spriteFrames.set_animation_speed(anim_name, maxf(fps, 0.001));
		
		for frame_data in frames:
			var frameTexture = AtlasTexture.new();
			frameTexture.atlas = load(texture_path);
			frameTexture.region = frame_data["region"];
			frameTexture.margin = frame_data["margin"];
			
			anim_spriteFrames.add_frame(anim_name, frameTexture);
			
	var sprite = AnimatedSprite2D.new();
	sprite.sprite_frames = anim_spriteFrames;
	sprite.name = "character";
	
	var node = Node2D.new();
	node.name = anim;
	node.add_child(sprite);
	
	sprite.owner = node;
	
	var packed_scene = PackedScene.new();
	packed_scene.pack(node);
	
	ResourceSaver.save(packed_scene, "res://%s.tscn"%[anim], ResourceSaver.FLAG_COMPRESS);
	ResourceSaver.save(anim_spriteFrames, "res://%s.res"%[anim], ResourceSaver.FLAG_COMPRESS);
	
func create_tscn_file(data_path, anim, have_loop, fps):
	var frames_data = _read_frames(data_path);
	
	if frames_data.is_empty():
		return;
		
	var texture_path = data_path.get_basename() + ".png";
	
	var node = Node2D.new();
	node.name = anim;
	node.set_script(preload("res://source/characters/characters_scripts/Character.gd"));
	
	var sprite = Sprite2D.new();
	sprite.name = "Character_Sprite";
	sprite.texture = load(texture_path);
	sprite.region_enabled = true;
	sprite.centered = true;
	node.add_child(sprite);
	
	var animPlayer = AnimationPlayer.new();
	animPlayer.name = "Character_Animation";
	node.add_child(animPlayer);
	
	sprite.owner = node;
	animPlayer.owner = node;
	
	var library = AnimationLibrary.new()
	var frame_time = 1.0 / maxf(fps, 0.001)
	
	for anim_name in frames_data:
		var frames = frames_data[anim_name];
		if frames.is_empty():
			continue;
			
		var new_anim = Animation.new();
		
		var region_track = new_anim.add_track(Animation.TYPE_VALUE);
		var offset_track = new_anim.add_track(Animation.TYPE_VALUE);
		var rotation_track = new_anim.add_track(Animation.TYPE_VALUE);
		
		var sprite_path = NodePath("../Character_Sprite");
		
		new_anim.track_set_interpolation_type(region_track, Animation.INTERPOLATION_NEAREST);
		new_anim.track_set_interpolation_type(offset_track, Animation.INTERPOLATION_NEAREST);
		new_anim.track_set_interpolation_type(rotation_track, Animation.INTERPOLATION_NEAREST);
		
		new_anim.track_set_path(region_track, "%s:region_rect"%[node.get_path_to(sprite)]);
		new_anim.track_set_path(offset_track, "%s:offset"%[node.get_path_to(sprite)]);
		new_anim.track_set_path(rotation_track, "%s:rotation_degrees"%[node.get_path_to(sprite)]);
		
		for i in range(frames.size()):
			var frame = frames[i];
			
			new_anim.track_insert_key(region_track, i * 0.03, frame["region"]);
			new_anim.track_insert_key(offset_track, i * 0.03, frame["offset"]);
			new_anim.track_insert_key(rotation_track, i * 0.03, frame["rotation"]);
			
			new_anim.length = i * 0.03;
			
		anim_name = anim_name.strip_edges().trim_suffix("/");
		library.add_animation(str(anim_name), new_anim);
		
	animPlayer.add_animation_library("", library);
	
	var packed_scene = PackedScene.new();
	packed_scene.pack(node);
	
	ResourceSaver.save(packed_scene, "res://%s.tscn"%[anim], ResourceSaver.FLAG_COMPRESS);
	
func _read_frames(data_path):
	if data_path.is_empty():
		return;
		
	if !FileAccess.file_exists(data_path):
		return;
		
	match data_path.get_extension().to_lower():
		"xml":
			return _read_xml(data_path);
		"json":
			return _read_json(data_path);
		_:
			return {};
			
func _read_xml(path):
	var fileParser = XMLParser.new()
	var err = fileParser.open(path)
	if err != OK:
		push_error("error in: " + path)
		return {};
		
	var result = {};
	
	while fileParser.read() == OK:
		if fileParser.get_node_type() != XMLParser.NODE_ELEMENT:
			continue;
			
		if fileParser.get_node_name() != "SubTexture":
			continue;
			
		if fileParser.get_named_attribute_value_safe("name") != "":
			var anim_name = fileParser.get_named_attribute_value_safe("name");
			if anim_name.length() > 4:
				anim_name = anim_name.substr(0, anim_name.length() - 4);
				
			var xmlList = {
				"animation": [],
				"x": fileParser.get_named_attribute_value_safe("x").to_int(),
				"y": fileParser.get_named_attribute_value_safe("y").to_int(),
				"width": fileParser.get_named_attribute_value_safe("width").to_int(),
				"height": fileParser.get_named_attribute_value_safe("height").to_int(),
				"frameX": fileParser.get_named_attribute_value_safe("frameX").to_int(),
				"frameY": fileParser.get_named_attribute_value_safe("frameY").to_int(),
				"frameWidth": fileParser.get_named_attribute_value_safe("frameWidth").to_int(),
				"frameHeight": fileParser.get_named_attribute_value_safe("frameHeight").to_int(),
				"rotated": fileParser.get_named_attribute_value_safe("rotated") == "true"
			};
			
			var fw = xmlList["frameWidth"] if xmlList["frameWidth"] > 0 else xmlList["width"];
			var fh = xmlList["frameHeight"] if xmlList["frameHeight"] > 0 else xmlList["height"];
			
			var rotation = -90.0 if xmlList["rotated"] else 0.0;
			
			var margin = Rect2(
				Vector2(-xmlList["frameX"], -xmlList["frameY"]),
				Vector2(maxi(fw - xmlList["width"], 0), maxi(fh - xmlList["height"], 0))
			);
			
			margin.size.x = maxf(margin.size.x, absf(margin.position.x));
			margin.size.y = maxf(margin.size.y, absf(margin.position.y));
			
			if !result.has(anim_name):
				result[anim_name] = [];
				
			result[anim_name].append({
				"region": Rect2(
					Vector2(xmlList["x"], xmlList["y"]),
					Vector2(xmlList["width"], xmlList["height"])
				),
				"margin": margin,
				"offset": Vector2(
					-xmlList["frameX"] - (fw - xmlList["width"]) / 2.0,
					-xmlList["frameY"] - (fh - xmlList["height"]) / 2.0
				) if !xmlList["rotated"] else Vector2(
					-xmlList["frameY"], 
					xmlList["frameX"]
				),
				"rotation": rotation
			});
			
	return result;
	
func _read_json(path):
	var file = FileAccess.open(path, FileAccess.READ);
	if file == null:
		return {};
		
	var data = JSON.parse_string(file.get_as_text());
	
	var all_frames = data.get("frames", data.get("animations", {}));
	var result = {};
	
	for tag in data.get("meta", {}).get("frameTags", []):
		var anim_name = str(tag.get("name", ""));
		var first = int(tag.get("from", 0));
		var last = int(tag.get("to", 0));
		
		if anim_name.is_empty():
			continue;
			
		var keys = all_frames.keys()
		if !result.has(anim_name):
			result[anim_name] = [];
			
		for i in range(first, last + 1):
			if i < 0 or i >= keys.size():
				continue;
				
			var rect = all_frames[keys[i]].get("frame", {});
			var source = all_frames[keys[i]].get("spriteSourceSize", {});
			var size = all_frames[keys[i]].get("sourceSize", {});
			
			var margin = Rect2(
				Vector2(
					-int(source.get("x", 0)), 
					-int(source.get("y", 0))
				),
				Vector2(
					maxi(int(size.get("w", int(rect.get("w", 0)))) - int(rect.get("w", 0)), 0),
					maxi(int(size.get("h", int(rect.get("h", 0)))) - int(rect.get("h", 0)), 0)
				)
			);
			
			margin.size.x = maxf(margin.size.x, absf(margin.position.x))
			margin.size.y = maxf(margin.size.y, absf(margin.position.y))
			
			result[anim_name].append({
				"region": Rect2(int(rect.get("x", 0)), int(rect.get("y", 0)), int(rect.get("w", 0)), int(rect.get("h", 0))),
				"margin": margin,
				"offset": Vector2(
					-int(source.get("x", 0)) - (int(size.get("w", int(rect.get("w", 0)))) - int(rect.get("w", 0))) / 2.0,
					-int(source.get("y", 0)) - (int(size.get("h", int(rect.get("h", 0)))) - int(rect.get("h", 0))) / 2.0),
				"rotation": 0.0
			});
			
	return result;
	
