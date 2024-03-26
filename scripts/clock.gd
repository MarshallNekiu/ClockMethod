class_name Clock
extends Panel

signal started
signal alarm(time: float)
signal alarm_created(alarm: Alarm)
signal event_created(event: Alarm.Event)

class BlackBox:
	signal state_toggled(state: bool)
	
	var input: Callable
	var output: Callable
	var propagation: Callable
	
	
	func run():
		if input:
			if await input.call():
				state_toggled.emit(true)
				if output:
					output.call()
					return
		state_toggled.emit(false)
	
	
	func propagate_input(new_input := input):
		if propagation:
			var propagated:Array = propagation.call().map(func (x): return x.black_box)
			for i in propagated:
				i.propagate_input(new_input)
				i.input = new_input
	
	
	func propagate_output(new_output := output):
		if propagation:
			var propagated:Array = propagation.call().map(func (x): return x.black_box)
			for i in propagated as Array[BlackBox]:
				i.propagate_output(new_output)
				i.output = new_output

class Alarm:
	extends HBoxContainer
	
	class Event:
		extends Button
		
		var black_box := BlackBox.new()
		
		
		func _init():
			name = "Event"
		
		
		func ready():
			if text == "":
				text = name
			(owner as Clock).emit_signal("alarm_created", self)
	
	
	var black_box := BlackBox.new()
	
	
	func _init(label := "!"):
		black_box.propagation = get_event_list
		name = "Alarm"
		
		var new_label := Button.new()
		new_label.name = "Label"
		new_label.text = label
		new_label.custom_minimum_size.x = 32
		
		var new_time := SpinBox.new()
		new_time.name = "Time"
		new_time.alignment = HORIZONTAL_ALIGNMENT_CENTER
		new_time.select_all_on_focus = true
		new_time.max_value = 600
		new_time.step = 0.01
		new_time.value = 1.0
		
		var new_add_event := LineEdit.new()
		new_add_event.name = "AddEvent"
		new_add_event.placeholder_text = "Event"
		new_add_event.expand_to_text_length = true
		
		add_child(new_label)
		add_child(new_time)
		add_child(new_add_event)
		
		new_label.connect("button_down", _on_button_down.bind(new_label, self))
		new_add_event.connect("text_submitted", add_event)
	
	
	func add_event(event_text: String):
		if not get_children().filter(func (x): return x.is_in_group("Event") and x.text == event_text).is_empty():
			return
		var new_event := Event.new()
		new_event.text = event_text
		new_event.add_to_group("Event")
		if black_box.input:
			new_event.black_box.input = black_box.input
		if black_box.output:
			new_event.black_box.output = black_box.output
		add_child(new_event, true)
		move_child(new_event, -2)
		new_event.owner = owner as Clock
		owner.emit_signal("event_created", new_event)
		
		new_event.connect("button_down", _on_button_down.bind(new_event))
		new_event.black_box.connect("state_toggled", Callable(func (toggle: bool): new_event.modulate = Color.WHITE if toggle else Color.RED))
	
	
	func get_event_list() -> Array[Event]:
		var list: Array[Event]
		list.append_array(get_children().filter(func (x): return x.is_in_group("Event")))
		return list
	
	
	func _on_button_down(button: Button, modulated = button, freed = modulated):
		var time := button.get_tree().create_timer(0.3)
		if is_instance_valid(button) and button.is_pressed():
			modulated.modulate = Color.WHITE if modulated.modulate == Color.DIM_GRAY else Color.DIM_GRAY
		else:
			return
		
		await button.get_tree().create_timer(0.5).timeout
		if is_instance_valid(button) and button.is_pressed():
			freed.queue_free()


var black_box := BlackBox.new()


func _ready():
	black_box.propagation = $VBox/Connected/VBox.get_children


func add_alarm(label := ""):
	var new_alarm := Alarm.new(label)
	
	new_alarm.get_node("Time").value = $VBox/Control/Time.value
	new_alarm.get_node("Label").text = label if not label == "" else "!"
	if black_box.input:
		new_alarm.black_box.input = black_box.input
	if black_box.output:
		new_alarm.black_box.output = black_box.output
	new_alarm.add_to_group("Alarm")
	
	$VBox/Connected/VBox.add_child(new_alarm, true)
	new_alarm.owner = self
	emit_signal("alarm_created", new_alarm)


func get_alarm_list() -> Dictionary:
	var list: Dictionary
	
	for i in $VBox/Connected/VBox.get_children():
		list.merge({i: [i.get_node("Label").text, i.get_node("Time").value]})
	
	return list


func sort_by_time():
	var node_list := $VBox/Connected/VBox.get_children()
	node_list.sort_custom(func (a:Alarm, b:Alarm): return a.get_node("Time").value < b.get_node("Time").value)
	
	for i in node_list:
		$VBox/Connected/VBox.move_child(i, -1)


func start():
	var time_end:float = $VBox/Control/EndTime.value
	var alarm_list := get_alarm_list()
	var event_list: Dictionary

	var time_list := [0]
	for i in alarm_list.keys().filter(func (x: Alarm): return x.modulate == Color.WHITE) as Array[Alarm]:
		if not time_list.has(alarm_list[i][1]):
			time_list.append(alarm_list[i][1])
			event_list.merge({alarm_list[i][1]: []})
		
		for j in [i] + i.get_event_list().filter(func (x: Alarm.Event): return not x.modulate == Color.DIM_GRAY) as Array[Alarm]:
			if j.black_box:
				event_list[alarm_list[i][1]].append(j.black_box)
	time_list.sort()

	var _time := $VBox/Control/CurrentTime/Animation as AnimationPlayer
	var animation := _time.get_animation("start")
	_time.stop()
	emit_signal("started")
	for i in range(1, time_list.size()):
		animation.length = time_list[i]
		if animation.length > time_end:
			GlobalScript.get_Debugger(self).text += "\nStopped\n"
			return
		animation.track_set_key_value(0, 1, time_list[i])
		animation.track_set_key_time(0, 1, time_list[i])
		_time.play("start")
		await _time.animation_finished
		for j in event_list[time_list[i]] as Array[BlackBox]:
			j.run()
		emit_signal("alarm", time_list[i])
	GlobalScript.get_Debugger(self).text += "\nFinished\n"















