extends Reference
class_name BetterDatabase

# Emited when new document has been created using `set_doc` or `append_doc`
signal doc_created(id)

# Emited when document, that already exists, has been replaced using `set_doc`
signal doc_replaced(id)

# Emited when the document has been deleted
signal doc_deleted(id)

# Emited when one of the document param has chagned
signal param_changed(id, param)

# Emited when whatever has changed (useful for autosave feature)
signal something_changed


# Custom signal types
const DOC_CREATED := 1
const DOC_REPLACED := 2
const DOC_DELETED := 3

const PARAM_CHANGED := 1


# Constant for cleaner get_docs_sorted_by argument
const ASCENDING := true
const DESCENDING := false

#########################################################################################


class CustomListener:
	extends Reference
	
	var node_ref : WeakRef
	var callback_func : String
	var extra_args : Array
	var listeners_array : Array
	
	func _init(
		node:Node,
		callback_func:String,
		extra_args : Array,
		listeners_array : Array
	) -> void:
		
		self.node_ref = weakref(node)
		self.callback_func = callback_func
		self.extra_args = extra_args
		self.listeners_array = listeners_array
		
		node.connect("tree_exited", self,"remove_self")
	
	func remove_self() -> void:
		listeners_array.erase(self)


class CustomSorter:
	extends Reference
	
	var _sort_by : Array
	var _ascending : bool
	
	func _init(sort_by:Array, ascending:bool) -> void:
		_sort_by = sort_by
		_ascending = ascending
	
	func sort(doc1:BetterDocument, doc2:BetterDocument) -> bool:
		for key in _sort_by:
			if doc1[key] < doc2[key]:
				return _ascending
			if doc1[key] > doc2[key]:
				return not _ascending
			
			# For cases where the fields are equal, continue to next fields or return True
		
		return true


# {
# 	<signal-type>: {
#		<id>: [
#			CustomListener, ...
#		]
#	}
# }
var _doc_listeners := {}

# {
# 	<signal-type>: {
#		<id>: {
#			<param>: [
#				CustomListener, ...
#			]
#		}
#	}
# }
var _param_listeners := {}

var _DocumentType setget _set_document_type, get_document_type

var _docs : Dictionary = {} setget , get_all_docs
var _next_id : int = 1

var _notify_on_change : bool = true

const _DOCUMENTS_SAVE_KEY = "docs"
const _PROPERTIES_SAVE_KEY = "props"
const _NEXT_ID_SAVE_KEY = "next_id"


func _init(DocType) -> void:
	assert(DocType.is_class("Reference"), "DocType MUST inherit from BetterDocument reference")
	
	_DocumentType = DocType


func listen_doc(
	id:String, 
	signal_type:int, 
	node:Node, 
	func_name:String, 
	extra_args:=[]
) -> void:
	
	assert(signal_type in [
		DOC_CREATED,
		DOC_REPLACED,
		DOC_DELETED,
	])
	 
	if not _doc_listeners.has(signal_type):
		_doc_listeners[signal_type] = {}
	if not _doc_listeners[signal_type].has(id):
		_doc_listeners[signal_type][id] = []
	
	var custom_listener = CustomListener.new(
		node,
		func_name,
		extra_args,
		_doc_listeners[signal_type][id]
	)
	
	_doc_listeners[signal_type][id].append(custom_listener)


func listen_param(
	id:String, 
	param:String, 
	signal_type:int, 
	node:Node, 
	func_name:String, 
	extra_args:=[]
) -> void:
	
	assert(signal_type in [
		PARAM_CHANGED,
	])
	 
	if not _param_listeners.has(signal_type):
		_param_listeners[signal_type] = {}
	if not _param_listeners[signal_type].has(id):
		_param_listeners[signal_type][id] = []
	if not _param_listeners[signal_type][id].has(param):
		_param_listeners[signal_type][id][param] = []
	
	var custom_listener = CustomListener.new(
		node,
		func_name,
		extra_args,
		_param_listeners[signal_type][id][param]
	)
	
	_param_listeners[signal_type][id][param].append(custom_listener)


func set_doc(id:String, doc:Reference) -> void:
	assert(doc is _DocumentType)
	assert(doc is BetterDocument)
	
	doc.id = id
	_docs[id] = doc
	
	# Autoincrement
	var id_int = id.to_int()
	if id_int >= _next_id:
		_next_id = id_int + 1
	
	emit_signal("doc_created", id)
	_something_changed()


func append_doc(doc:Reference) -> String:
	var id = get_next_id()
	set_doc(id, doc)
	return id


func get_doc(id:String, default=null) -> Reference:
	var doc = _docs.get(id, default)
	return doc


func has_doc(id:String) -> bool:
	var has = _docs.has(id)
	return has


func delete_doc(id:String) -> void:
	_docs.erase(id)
	emit_signal("doc_deleted", id)
	_something_changed()


func delete_all_docs() -> void:
	_notify_on_change = false
	
	for id in _docs.keys():
		delete_doc(id)
	
	_notify_on_change = true
	_something_changed()


func set_param(id:String, param:String, value) -> void:
	var doc = get_doc(id)
	
	if not doc:
		return
	
	doc.set(param, value)
	
	emit_signal("param_changed", id, param)
	_something_changed()


func get_param(id:String, param:String):
	var doc = get_doc(id)
	
	if not doc:
		return null
	
	var value = doc.get(param)
	return value


func get_all_docs(duplicate:=false) -> Dictionary:
	if duplicate:
		return _docs.duplicate()
	
	return _docs


func get_docs_sorted_by(sorted_by, ascending:bool=true) -> Array:
	if sorted_by is String:
		sorted_by = [sorted_by]
	else:
		push_error("sorted_by argument must be String or Array")
		assert(sorted_by is Array or not sorted_by is PoolStringArray)
	
	var docs = _docs.values()
	
	var sorter = CustomSorter.new(sorted_by, ascending)
	
	docs.sort_custom(sorter, "sort")
	
	return docs


func _custom_sort_ids_ascending(id1:String, id2:String) -> bool:
	pass
	return false


func save_in_file(file_path:String) -> void:
	var file_dir = file_path.get_base_dir()
	if not Directory.new().dir_exists(file_dir):
		Directory.new().make_dir_recursive(file_dir)
	
	var f := File.new()
	var error := f.open(file_path, File.WRITE)
	
	if error != OK:
		push_error("Cannot save DB due to error: " + str(error))
		return
	
	var content = get_str_to_save()
	f.store_string(content)
	
	f.close()


func get_str_to_save() -> String:
	var save_dict = duplicate_to_save()
	var str_content = JSON.print(save_dict)
	return str_content


func duplicate_to_save() -> Dictionary:
	var saver = BetterDatabaseSaver.new()
	var save_dict = {
		_DOCUMENTS_SAVE_KEY: saver.parse_docs(_docs),
		_PROPERTIES_SAVE_KEY: {
			_NEXT_ID_SAVE_KEY: _next_id,
		}
	}
	return save_dict


func load_from_file(file_path:String) -> void:
	var f := File.new()
	var error := f.open(file_path, File.READ)
	
	if error != OK:
		push_error("Cannot load DB due to error: " + str(error))
		return
	
	var content = f.get_as_text()
	f.close()
	
	var save_dict = JSON.parse(content).result
	if save_dict is Dictionary:
		load_from_save_dict(save_dict)
	else:
		push_error("Cannot load, save_dict not a Dictionary. Type: " + str(typeof(save_dict)))


func load_from_save_dict(save_dict:Dictionary) -> void:
	var loader = BetterDatabaseLoader.new()
	
	var saved_docs = save_dict.get(_DOCUMENTS_SAVE_KEY, {})
	_docs = loader.load_docs_from_save_dict(saved_docs, _DocumentType)
	
	var properties = save_dict.get(_PROPERTIES_SAVE_KEY, {})
	_next_id = properties.get(_NEXT_ID_SAVE_KEY, _next_id)


func get_document_type():
	return _DocumentType


func _set_document_type(_t) -> void:
	assert(false, "One cannot override document type on runtime")


func get_next_id() -> String:
	var next_id = str(_next_id)
	return next_id


func _something_changed() -> void:
	if _notify_on_change:
		emit_signal("something_changed")
