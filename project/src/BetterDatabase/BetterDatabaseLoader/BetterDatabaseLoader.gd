extends Resource
class_name BetterDatabaseLoader


func load_docs_from_save_dict(saved_docs:Dictionary, DocType) -> Dictionary:
	assert(DocType.is_class("Reference"))
	
	var parsed_docs := {}
	
	for key in saved_docs.keys():
		parsed_docs[key] = _parse_one_doc(saved_docs[key], DocType)
	
	return parsed_docs


func _parse_one_doc(doc_dict:Dictionary, DocType) -> Reference:
	var doc = DocType.new()
	
	for key in doc_dict.keys():
		var value = _parse_value(doc_dict[key])
		doc.set(key, value)
	
	return doc


func _parse_value(value):
	match typeof(value):
		TYPE_ARRAY:
			return _parse_array(value)
		TYPE_DICTIONARY:
			return _parse_dict(value)
		_:
			return value


func _parse_array(arr:Array) -> Array:
	var parsed = []
	parsed.resize(arr.size())
	
	for i in range(arr.size()):
		parsed[i] = _parse_value(arr[i])
	
	return parsed


func _parse_dict(dict:Dictionary):
	if _is_dict_color(dict):
		return _parse_dict_to_color(dict)
	if _is_dict_vec3(dict):
		return _parse_dict_to_vec3(dict)
	if _is_dict_vec2(dict):
		return _parse_dict_to_vec2(dict)
	
	var parsed = {}
	
	for key in dict.keys():
		parsed[key] = _parse_value(dict[key])
	
	return parsed


func _is_dict_color(dict:Dictionary) -> bool:
	var is_color = (
		dict.size() == 4
		and dict.has("r")
		and dict.has("g")
		and dict.has("b")
		and dict.has("a")
	)
	return is_color


func _is_dict_vec3(dict:Dictionary) -> bool:
	var is_vec3 = (
		dict.size() == 3
		and dict.has("x")
		and dict.has("y")
		and dict.has("z")
	)
	return is_vec3


func _is_dict_vec2(dict:Dictionary) -> bool:
	var is_vec2 = (
		dict.size() == 2
		and dict.has("x")
		and dict.has("y")
	)
	return is_vec2


func _parse_dict_to_color(col_dict:Dictionary) -> Color:
	var col = Color(
		col_dict.r,
		col_dict.g,
		col_dict.b,
		col_dict.a
	)
	return col


func _parse_dict_to_vec3(vec_dict:Dictionary) -> Vector3:
	var vec = Vector3(
		vec_dict.x,
		vec_dict.y,
		vec_dict.z
	)
	return vec


func _parse_dict_to_vec2(vec_dict:Dictionary) -> Vector2:
	var vec = Vector2(
		vec_dict.x,
		vec_dict.y
	)
	return vec
