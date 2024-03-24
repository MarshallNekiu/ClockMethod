extends Panel

signal on_time(event_list: Dictionary)


func _on_add_connection_pressed():
	var new_connection := HBoxContainer.new()
	new_connection.name = "Connection"
	new_connection.add_to_group("Connection")
	
	var new_id := Button.new()
	new_id.name = "ID"
	new_id.custom_minimum_size.x = 32
	
	var new_time := SpinBox.new()
	new_time.name = "Time"
	new_time.alignment = HORIZONTAL_ALIGNMENT_CENTER
	new_time.select_all_on_focus = true
	new_time.max_value = 10000
	new_time.step = 0.01
	new_time.value = $VBox/Control/Time.value
	
	var new_add_event := LineEdit.new()
	new_add_event.name = "AddEvent"
	new_add_event.placeholder_text = "Event"
	new_add_event.expand_to_text_length = true
	new_add_event.set_meta("condition", Callable(func (): return true))
	
	new_connection.add_child(new_id, true)
	new_connection.add_child(new_time, true)
	new_connection.add_child(new_add_event, true)
	$VBox/Connected/VBox.add_child(new_connection, true)
	
	new_id.connect("button_down", _on_button_down.bind(new_id, new_connection))
	new_add_event.connect("text_submitted", _on_add_event_text_submitted.bind(new_connection, new_add_event.get_meta("condition")))


func get_connected_list() -> Dictionary:
	var list: Dictionary
	for i in $VBox/Connected/VBox.get_children():
		list.merge({i.get_node("ID").text.to_int(): i.get_node("Time").value})
	return list


func _on_button_down(button: Button, modulated = button, freed = modulated):
	var time:SceneTreeTimer = get_tree().create_timer(0.3)
	if is_instance_valid(button) and button.is_pressed():
		modulated.modulate = Color.WHITE if modulated.modulate == Color.DIM_GRAY else Color.DIM_GRAY
	
	await get_tree().create_timer(0.5).timeout
	if is_instance_valid(button) and button.is_pressed():
		freed.queue_free()


func _on_add_event_text_submitted(new_text: String, parent: HBoxContainer, condition := Callable(func (): return true)):
	if not await condition.call() == true: return
	
	var new_event := Button.new()
	new_event.name = "Event"
	new_event.add_to_group("Event")
	new_event.text = new_text
	new_event.set_meta("condition", condition)
	
	parent.add_child(new_event)
	parent.move_child(new_event, -2)
	
	new_event.connect("button_down", _on_button_down.bind(new_event))


func get_connection_list(time: float) -> PackedStringArray:
	var connected_list:Array[Node] = $VBox/Connected/VBox.get_children().filter(func (x): return x.get_node("Time").value == time and x.modulate == Color.WHITE)
	if connected_list.is_empty(): return [] as PackedStringArray
	
	var connection: PackedStringArray = []
	for connected in connected_list:
		for event in connected.get_children().filter(func (x): return x.is_in_group("Event") and not x.modulate == Color.DIM_GRAY) as Array[Button]:
			if not await event.get_meta("condition").call() == true:
				event.modulate = Color.RED
				continue
			if event.modulate == Color.RED and await event.get_meta("condition").call() == true:
				event.modulate = Color.WHITE
			connection.append(event.text)
	
	return connection


func _on_v_box_child_order_changed():
	if not is_instance_valid($VBox/Connected/VBox): return
	for i in $VBox/Connected/VBox.get_children():
		i.get_node("ID").text = str($VBox/Connected/VBox.get_children().find(i))


func start(event_list := {}):
	if event_list.is_empty():
		for i in get_connected_list().values():
			if not event_list.has(i):
				event_list.merge({i: []})
			for j in await get_connection_list(i):
				if not event_list[i].has(j):
					event_list[i].append(j)
	var time:Array[float] = [0]
	for i in get_connected_list().values():
		if not time.has(i):
			time.append(i)
	time.sort()
	for i in range(1, time.size()):
		$Time.start(time[i] - time[i-1])
		start_time = time[i-1]
		await $Time.timeout
		emit_signal("on_time", event_list[time[i]])
		GlobalScript.get_Debugger(self).text += str(event_list[time[i]]) + "\n"


var start_time:float = 0
func _process(delta):
	$VBox/Control/Label.text = "%.2f" % (start_time + ($Time.wait_time - $Time.time_left))









