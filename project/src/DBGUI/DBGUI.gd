extends Control

export var DocDisplayer : PackedScene

onready var docs_container = find_node("DocsContainer")


func _ready() -> void:
	_fill_with_current_state()


func _fill_with_current_state() -> void:
	var doc_name = "testDB"
	var db = DB.get(doc_name)
	
	if not db is BetterDatabase:
		return


func _fill_from_db(db:BetterDatabase) -> void:
	for id in db.get_all_docs().keys():
		_show_doc(db, id)


func _show_doc(db:BetterDatabase, id:String) -> void:
	var doc = db.get_doc(id)
	var doc_displayer = DocDisplayer.instance()
	docs_container.add_child(doc_displayer)
	
	doc_displayer.setup(db, id)
