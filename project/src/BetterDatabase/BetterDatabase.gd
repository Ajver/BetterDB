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
const DOC_CREATED = 1
const DOC_REPLACED = 2
const DOC_DELETED = 3

const PARAM_CHANGED = 1


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
	
	_docs[id] = doc
	
	# Autoincrement
	var id_int = id.to_int()
	if id_int >= _next_id:
		_next_id = id_int + 1
	
	emit_signal("doc_created", id)


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


func set_param(id:String, param:String, value) -> void:
	var doc = get_doc(id)
	
	if not doc:
		return
	
	doc.set(param, value)
	
	emit_signal("param_changed", id, param)


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


func duplicate_to_save() -> Dictionary:
	var saver = BetterDatabaseSaver.new()
	var save_dict = {
		_DOCUMENTS_SAVE_KEY: saver.parse_docs(_docs),
		_PROPERTIES_SAVE_KEY: {
			_NEXT_ID_SAVE_KEY: 1,
		}
	}
	return save_dict


func load_from_save_dict(save_dict:Dictionary) -> void:
	var loader = BetterDatabaseLoader.new()
	
	_docs = loader.load_docs_from_save_dict(save_dict.get(_DOCUMENTS_SAVE_KEY, {}), _DocumentType)
	
	var properties = save_dict.get(_PROPERTIES_SAVE_KEY, {})
	_next_id = properties.get(_NEXT_ID_SAVE_KEY, _next_id)


func get_document_type():
	return _DocumentType


func _set_document_type(_t) -> void:
	assert(false, "One cannot override document type on runtime")


func get_next_id() -> String:
	var next_id = str(_next_id)
	return next_id
