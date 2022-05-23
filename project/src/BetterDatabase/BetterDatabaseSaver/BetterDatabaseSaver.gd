extends Reference
class_name BetterDatabaseSaver


func parse_docs(raw_docs:Dictionary) -> Dictionary:
	var save_docs := {}
	
	for id in raw_docs.keys():
		var raw_doc = raw_docs[id]
		
		if raw_doc is BetterDocument:
			save_docs[id] = raw_doc.dict()
		else:
			push_error("Trying to parse document, which is not BetterDocument instance: " + str(raw_doc))
	
	return save_docs
