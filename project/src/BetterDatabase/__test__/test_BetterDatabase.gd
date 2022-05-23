extends GutTest

class TestDocType:
	extends BetterDocument
	
	var test_a : String
	var test_b : int = 7
	var test_c : int = 8
	var test_d : int = 9


class AnotherDocType:
	extends BetterDocument
	
	var vec3D : Vector3
	var vec2D : Vector2
	var col : Color
	
	var nested_dict := {}
	var nested_arr := []


var db : BetterDatabase


func before_each() -> void:
	db = BetterDatabase.new(TestDocType)


func test_get_document_type() -> void:
	assert_eq(db.get_document_type(), TestDocType, "Document type should be the same")
	
	var another_db = BetterDatabase.new(AnotherDocType)
	assert_eq(another_db.get_document_type(), AnotherDocType, "Document type should be the same")


func test_set_get_doc() -> void:
	var doc = TestDocType.new() 
	db.set_doc("test-id", doc)
	
	assert_eq(db.get_doc("test-id"), doc, "Doc should be the same")


func test_set_doc_emits_doc_created_signal() -> void:
	var doc = TestDocType.new()
	var id = "foo"
	
	watch_signals(db)
	db.set_doc(id, doc)
	assert_signal_emitted_with_parameters(db, "doc_created", [id])


func test_set_param_emits_param_changed_signal() -> void:
	watch_signals(db)
	
	var doc = TestDocType.new()
	var id = "test-id"
	db.set_doc(id, doc)
	
	db.set_param(id, "test_a", "test-content")
	assert_signal_emitted_with_parameters(db, "param_changed", [id, "test_a"])


func test_append_doc() -> void:
	var doc = TestDocType.new()
	
	var id = db.append_doc(doc)
	assert_eq(id, "1", "Returned ID should be right")
	assert_eq(db.get_doc(id), doc, "Doc should be the same")
	
	var doc2 = TestDocType.new()
	id = db.append_doc(doc2)
	assert_eq(id, "2", "Returned ID should autoincrement")
	assert_eq(db.get_doc(id), doc2, "Doc should be the same")
	
	var doc3 = TestDocType.new()
	id = db.append_doc(doc3)
	assert_eq(id, "3", "Returned ID should autoincrement")
	assert_eq(db.get_doc(id), doc3, "Doc should be the same")


func test_set_doc_autoincrements_next_id() -> void:
	var doc = TestDocType.new()
	
	assert_eq(db.get_next_id(), "1", "Next ID should be one by default")
	
	db.set_doc("5", doc)
	assert_eq(db.get_next_id(), "6", "Next ID should be incremented")
	
	db.set_doc("6", doc)
	assert_eq(db.get_next_id(), "7", "Next ID should be incremented")
	
	db.set_doc("14", doc)
	assert_eq(db.get_next_id(), "15", "Next ID should be incremented")
	
	db.set_doc("3", doc)
	assert_eq(db.get_next_id(), "15", "Next ID should NOT incremented after setting to lower than before")


func test_returns_default_when_no_such_doc() -> void:
	var default = TestDocType.new()
	assert_eq(db.get_doc("invalid-id", default), default, "Should return default")


func test_returns_null_when_no_such_doc() -> void:
	var default = TestDocType.new()
	assert_null(db.get_doc("invalid-id"), "Should return null by default")


func test_override_doc() -> void:
	var old = TestDocType.new()
	db.set_doc("test-id", old)
	
	var new = TestDocType.new()
	db.set_doc("test-id", new)
	
	assert_eq(db.get_doc("test-id"), new, "Should return new doc")


func test_delete_doc() -> void:
	watch_signals(db)
	
	var doc = TestDocType.new() 
	db.set_doc("test-id", doc)
	assert_eq(db.get_doc("test-id"), doc, "Doc should be the same")
	
	db.delete_doc("test-id")
	assert_null(db.get_doc("test-id"), "Doc should be null")
	assert_signal_emitted_with_parameters(db, "doc_deleted", ["test-id"])


func test_doesnt_crash_when_deleting_unexisting_doc() -> void:
	assert_false(db.has_doc("invalid-id"), "Should not have the doc")
	db.delete_doc("invalid-id")
	assert_false(db.has_doc("invalid-id"), "Should not have the doc")


func test_has_doc() -> void:
	assert_false(db.has_doc("test-id"), "Should not have the doc by default")
	
	var doc = TestDocType.new()
	db.set_doc("test-id", doc)
	assert_true(db.has_doc("test-id"), "Should have the doc after set")


func test_has_no_doc_after_deleting() -> void:
	assert_false(db.has_doc("test-id"), "Should not have the doc by default")
	
	var doc = TestDocType.new()
	db.set_doc("test-id", doc)
	assert_true(db.has_doc("test-id"), "Should have the doc after set")
	
	db.delete_doc("test-id")
	assert_false(db.has_doc("test-id"), "Should not have the doc anymore")


func test_set_get_param() -> void:
	var doc = TestDocType.new()
	doc.test_a = "foo"
	
	db.set_doc("id", doc)
	
	assert_eq(doc.test_a, "foo", "Param should be right")
	assert_eq(db.get_param("id", "test_a"), "foo", "Should return right param value")
	
	db.set_param("id", "test_a", "bla")
	assert_eq(doc.test_a, "bla", "Param should be updated")
	assert_eq(db.get_param("id", "test_a"), "bla", "Should return right param value")


func test_set_param_doesnt_crash_for_invalid_input() -> void:
	db.set_param("wrong-id", "test_a", "bla")
	
	var doc = TestDocType.new()
	db.set_doc("id", doc)
	db.set_param("id", "invalid-param-name", "bla")
	
	assert_true(true, "Should not crash")


func test_get_param_returns_null_for_invalid_input() -> void:
	db.get_param("wrong-id", "test_a")
	assert_null(db.get_param("id", "invalid-param-name"), "Should return null")
	
	var doc = TestDocType.new()
	db.set_doc("id", doc)
	assert_null(db.get_param("id", "invalid-param-name"), "Should return null")


func test_empty_duplicate_to_save() -> void:
	var save_dict := db.duplicate_to_save()
	
	assert_eq(save_dict.size(), 2, "Should have two fields")
	
	var properties = save_dict.get(db._PROPERTIES_SAVE_KEY)
	assert_true(properties is Dictionary, "Properties should be dict")
	
	var documents = save_dict.get(db._DOCUMENTS_SAVE_KEY)
	assert_true(documents is Dictionary, "Documents should be dict")
	
	if not properties is Dictionary or not documents is Dictionary:
		return
	
	assert_eq(properties.get(db._NEXT_ID_SAVE_KEY), 1, "Next id should be set to 1")
	assert_true(documents.empty(), "Documents dict should be empty")


func test_one_doc_duplicate_to_save() -> void:
	var doc = TestDocType.new()
	doc.test_a = "test-a-value"
	doc.test_b = 13
	db.set_doc("test-id", doc)
	
	var save_dict := db.duplicate_to_save()
	
	assert_eq(save_dict.size(), 2, "Should have two fields")
	
	var properties = save_dict.get(db._PROPERTIES_SAVE_KEY)
	assert_true(properties is Dictionary, "Properties should be dict")
	
	var documents = save_dict.get(db._DOCUMENTS_SAVE_KEY)
	assert_true(documents is Dictionary, "Documents should be dict")
	
	if not properties is Dictionary or not documents is Dictionary:
		return
	
	assert_eq(properties.get(db._NEXT_ID_SAVE_KEY), 1, "Next id should be set to 1")
	
	var saved_doc = documents.get("test-id")
	assert_true(saved_doc is Dictionary, "Saved doc should be dict")
	
	if not saved_doc is Dictionary:
		return
	
	assert_eq(saved_doc.get("test_a"), "test-a-value", "Test A should be the same")
	assert_eq(saved_doc.get("test_b"), 13, "Test B should be the same")


func test_parse_doc_vectors_and_colors() -> void:
	# Re-create with AnotherDocType, so we can use nested fields
	db = BetterDatabase.new(AnotherDocType)
	
	var doc = _create_doc_with_nested_vec_and_colors()
	
	db.set_doc("test-id", doc)
	
	var save_dict := db.duplicate_to_save()
	
	var documents = save_dict.get(db._DOCUMENTS_SAVE_KEY, {})
	var saved_doc = documents.get("test-id", {})
	
	print(JSON.print(saved_doc, "\t"))
	
	_assert_saved_vec3D(saved_doc.get("vec3D"), doc.vec3D)
	_assert_saved_vec2D(saved_doc.get("vec2D"), doc.vec2D)
	_assert_saved_col(saved_doc.get("col"), doc.col)
	
	var nested_dict = saved_doc.get("nested_dict", {})
	_assert_saved_vec3D(nested_dict.get("a"), doc.nested_dict.a)
	_assert_saved_col(nested_dict.get("nested_dict", {}).get("col"), doc.nested_dict.nested_dict.col)
	_assert_saved_vec2D(nested_dict.get("nested_dict", {}).get("arr", [])[0], doc.nested_dict.nested_dict.arr[0])
	_assert_saved_vec3D(nested_dict.get("nested_dict", {}).get("arr", [])[1], doc.nested_dict.nested_dict.arr[1])
	
	var nested_arr = saved_doc.get("nested_arr", [])
	_assert_saved_vec3D(nested_arr[0], doc.nested_arr[0])
	_assert_saved_vec2D(nested_arr[1], doc.nested_arr[1])
	_assert_saved_col(nested_arr[2].get("col"), doc.nested_arr[2].col)
	_assert_saved_vec2D(nested_arr[2].get("vec2"), doc.nested_arr[2].vec2)
	_assert_saved_vec3D(nested_arr[2].get("arr")[0], doc.nested_arr[2].arr[0])


func test_loads_from_save_dict() -> void:
	# Re-create with AnotherDocType, so we can use nested fields
	db = BetterDatabase.new(AnotherDocType)
	
	var doc = _create_doc_with_nested_vec_and_colors()
	
	db.set_doc("test-id", doc)
	
	var save_dict := db.duplicate_to_save()
	
	var another_db = BetterDatabase.new(AnotherDocType)
	
	another_db.load_from_save_dict(save_dict)
	
	assert_eq(another_db._next_id, db._next_id, "Next id should be the same")
	
	var loaded_doc : AnotherDocType = another_db.get_doc("test-id")
	assert_not_null(loaded_doc, "Should load another doc")
	
	if not loaded_doc is AnotherDocType:
		return
	
	assert_eq(loaded_doc.vec2D, doc.vec2D, "Vec2 should be the same")
	assert_eq(loaded_doc.vec3D, doc.vec3D, "Vec3 should be the same")
	assert_eq(loaded_doc.col, doc.col, "Col should be the same")
	assert_eq(loaded_doc.nested_dict.a, doc.nested_dict.a)
	assert_eq(loaded_doc.nested_dict.nested_dict.col, doc.nested_dict.nested_dict.col)
	assert_eq(loaded_doc.nested_dict.nested_dict.arr[0], doc.nested_dict.nested_dict.arr[0])
	assert_eq(loaded_doc.nested_dict.nested_dict.arr[1], doc.nested_dict.nested_dict.arr[1])
	
	assert_eq(loaded_doc.nested_arr[0], doc.nested_arr[0])
	assert_eq(loaded_doc.nested_arr[1], doc.nested_arr[1])
	assert_eq(loaded_doc.nested_arr[2].col, doc.nested_arr[2].col)
	assert_eq(loaded_doc.nested_arr[2].vec2, doc.nested_arr[2].vec2)
	assert_eq(loaded_doc.nested_arr[2].arr[0], doc.nested_arr[2].arr[0])


func test_delete_all_deletes_all() -> void:
	db.append_doc(TestDocType.new())
	db.append_doc(TestDocType.new())
	db.append_doc(TestDocType.new())
	
	assert_eq(db.get_all_docs().size(), 3, "Should have 3 docs")
	
	db.delete_all_docs()
	assert_eq(db.get_all_docs().size(), 0, "Should have no docs")


func test_delete_all_emits_something_changed_signal_once() -> void:
	db.append_doc(TestDocType.new())
	db.append_doc(TestDocType.new())
	db.append_doc(TestDocType.new())
	
	watch_signals(db)
	
	db.delete_all_docs()
	assert_signal_emit_count(db, "something_changed", 1, "Should emit something_changed signal once")


func test_get_docs_sorted_by_ascending_descending() -> void:
	var doc1 = TestDocType.new()
	doc1.test_b = 1
	db.append_doc(doc1)
	
	var doc2 = TestDocType.new()
	doc2.test_b = 4
	db.append_doc(doc2)
	
	var doc3 = TestDocType.new()
	doc3.test_b = 3
	db.append_doc(doc3)
	
	var sorted_ascending = db.get_docs_sorted_by("test_b", db.ASCENDING)
	assert_eq(sorted_ascending, [doc1, doc3, doc2])
	
	var sorted_descending = db.get_docs_sorted_by("test_b", db.DESCENDING)
	assert_eq(sorted_descending, [doc2, doc3, doc1])


func test_get_docs_sorted_by_multiple_fields() -> void:
	var doc1 = TestDocType.new()
	doc1.test_b = 1
	doc1.test_c = 2
	doc1.test_d = 3
	db.append_doc(doc1)
	
	var doc2 = TestDocType.new()
	doc2.test_b = 3
	doc2.test_c = 2
	doc2.test_d = 3
	db.append_doc(doc2)
	
	var doc3 = TestDocType.new()
	doc3.test_b = 3
	doc3.test_c = 6
	doc3.test_d = 3
	db.append_doc(doc3)
	
	var doc4 = TestDocType.new()
	doc4.test_b = 3
	doc4.test_c = 6
	doc4.test_d = -5
	db.append_doc(doc4)
	
	var sort_keys = [
		"test_b",
		"test_c",
		"test_d",
	]
	
	var sorted_ascending = db.get_docs_sorted_by(sort_keys, db.ASCENDING)
	assert_eq(sorted_ascending, [doc1, doc2, doc4, doc3])
	
	var sorted_descending = db.get_docs_sorted_by(sort_keys, db.DESCENDING)
	assert_eq(sorted_descending, [doc3, doc4, doc2, doc1])


func _create_doc_with_nested_vec_and_colors() -> AnotherDocType:
	var doc = AnotherDocType.new()
	
	doc.vec3D = Vector3(1, 2, 3) 
	doc.vec2D = Vector2(-1, -2) 
	doc.col = Color(0.1, 0.2, 0.3, 0.4)
	
	doc.nested_dict = {
		"a": Vector3(5, 6, 7),
		"nested_dict": {
			"col": Color(1.0, 0.5, 0.0, 0.3),
			"arr": [
				Vector2(0.4, 0.6),
				Vector3(0.9, 0.8, 0.7),
			],
		}
	}
	
	doc.nested_arr = [
		Vector3(3, 2, 1),
		Vector2(2, 2),
		{
			"col": Color(1, 1, 1, 0),
			"vec2": Vector2(-10, -25),
			"arr": [
				Vector3(-5, -6, -7),
			],
		}
	]
	
	return doc


func _assert_saved_vec3D(saved_vec, expected_vec:Vector3) -> void:
	assert_true(saved_vec is Dictionary, "Saved vec should be dict")
	
	if not saved_vec is Dictionary:
		return
	
	assert_eq(saved_vec.size(), 3, "Saved dict shoud has exactly 3 fields")
	assert_eq(saved_vec.get("x"), expected_vec.x, "X should be the same")
	assert_eq(saved_vec.get("y"), expected_vec.y, "Y should be the same")
	assert_eq(saved_vec.get("z"), expected_vec.z, "Z should be the same")


func _assert_saved_vec2D(saved_vec, expected_vec:Vector2) -> void:
	assert_true(saved_vec is Dictionary, "Saved vec should be dict")
	
	if not saved_vec is Dictionary:
		return
	
	assert_eq(saved_vec.size(), 2, "Saved dict shoud has exactly 2 fields")
	assert_eq(saved_vec.get("x"), expected_vec.x, "X should be the same")
	assert_eq(saved_vec.get("y"), expected_vec.y, "Y should be the same")


func _assert_saved_col(saved_col, expected_col:Color) -> void:
	assert_true(saved_col is Dictionary, "Saved vec should be dict")
	
	if not saved_col is Dictionary:
		return
	
	assert_eq(saved_col.size(), 4, "Saved dict shoud has exactly 4 fields")
	assert_eq(saved_col.get("r"), expected_col.r, "R should be the same")
	assert_eq(saved_col.get("g"), expected_col.g, "G should be the same")
	assert_eq(saved_col.get("b"), expected_col.b, "B should be the same")
	assert_eq(saved_col.get("a"), expected_col.a, "A should be the same")
