extends ImageTexture
class_name SaveableTexture

var texture_path: String

const _SAVE_FIX = "===SaveableTexture==="


func _init(tex=null):
	if tex is Texture:
		create_from_image(tex.get_data(), FLAG_FILTER)
		texture_path = tex.resource_path


func create_from_png_buffer(buffer:PoolByteArray, file_path:String="") -> int:
	var image = Image.new()
	
	var error = image.load_png_from_buffer(buffer)
	
	if error != OK:
		return error
	
	image.generate_mipmaps()
	
	create_from_image(image, FLAG_FILTER)
	
	texture_path = file_path
	
	return OK


func load_png_from_path(png_path:String, print_errors:bool=true) -> int:
	var file := File.new()
	
	var error = file.open(png_path, File.READ)
	if error != OK:
		if print_errors:
			push_error("Couldn't open png file from path: %s" % png_path)
		
		file.close()
		return error
	
	var buffer := file.get_buffer(file.get_len())
	
	file.close()
	
	error = create_from_png_buffer(buffer)
	if error != OK:
		if print_errors:
			push_error("Loader.gd: Couldn't load png from buffer. Buffer size: %d" % buffer.size())
		
		return error
	
	texture_path = png_path
	
	return OK


func save_to_string() -> String:
	var s = _SAVE_FIX + texture_path + _SAVE_FIX
	return s


func load_from_save_string(save_string:String, print_errors:bool=true) -> void:
	var path = save_string.trim_prefix(_SAVE_FIX).trim_suffix(_SAVE_FIX)
	load_png_from_path(path, print_errors)
