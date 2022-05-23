extends Resource
class_name BetterDocument


const _PROPS_TO_IGNORE_ON_SAVE = [
	"Resource",
	"resource_local_to_scene",
	"resource_path",
	"Reference",
	"script",
	"Script Variables",
]

var id : String
"""ID of the document in database. Must not be modified!"""


func dict() -> Dictionary:
	var save_doc := {}
	var params_list = get_property_list()
	
	for param in params_list:
		if param.name in _PROPS_TO_IGNORE_ON_SAVE or param.name.begins_with("_"):
			continue
		
		var value = get(param.name)
		value = _parse_value(value)
		save_doc[param.name] = value
	
	return save_doc


func _parse_value(value):
	match typeof(value):
		TYPE_VECTOR2:
			return _parse_vec2(value)
		TYPE_VECTOR3:
			return _parse_vec3(value)
		TYPE_COLOR:
			return _parse_color(value)
		TYPE_DICTIONARY:
			return _parse_dict(value)
		TYPE_ARRAY:
			return _parse_array(value)
		TYPE_OBJECT:
			return _parse_object(value)
		_:
			return value


func _parse_vec2(vec:Vector2) -> Dictionary:
	var parsed = {
		"x": vec.x,
		"y": vec.y,
	}
	return parsed


func _parse_vec3(vec:Vector3) -> Dictionary:
	var parsed = {
		"x": vec.x,
		"y": vec.y,
		"z": vec.z,
	}
	return parsed


func _parse_color(col:Color) -> Dictionary:
	var parsed = {
		"r": col.r,
		"g": col.g,
		"b": col.b,
		"a": col.a,
	}
	return parsed


func _parse_dict(dict:Dictionary) -> Dictionary:
	var parsed = {}
	
	for key in dict.keys():
		parsed[key] = _parse_value(dict[key])
	
	return parsed


func _parse_array(arr:Array) -> Array:
	var parsed = []
	parsed.resize(arr.size())
	
	for i in range(arr.size()):
		parsed[i] = _parse_value(arr[i])
	
	return parsed


func _parse_object(obj:Object):
	if obj is SaveableTexture:
		var texture_save_dict = {
			"type": "SaveableTexture",
			"texture_path": obj.texture_path,
		}
		return texture_save_dict
	
	return str(obj)
