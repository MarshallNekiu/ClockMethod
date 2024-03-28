##Clock.
class_name Clock
extends Panel

signal alarm(time: float)
signal stopped(time: float)
signal finished
signal alarm_created(alarm: Alarm)
signal event_created(event: Alarm.Event)


##BlackBox.
class BlackBox:
	
	##Emits the return of [code]run()[/code].
	signal state_toggled(state: bool)
	
	var input: Callable
	var output: Callable
	
	##Verify the return of [code]input[/code] and emit it at [code]state_toggle[/code].
	##In case of input returned [code]true[/code] or input is [code]null[/code], the [code]output[/code] is called if setted.
	func run():
		if input:
			if not await input.call():
				state_toggled.emit(false)
				return
			else:
				state_toggled.emit(true)
		if output:
			output.call()


##Alarm.
class Alarm:
	extends HBoxContainer
	
	##Event.
	class Event:
		extends Button
		
		var black_box := BlackBox.new()
		
		
		func _init():
			name = "Event"
		
		
		func _ready():
			if text == "":
				text = name
	
	
	var black_box := BlackBox.new()
	var label := "!":
		set(x):
			get_node("Label").set_text(x)
		get:
			return get_node("Label").get_text()
	var time := 1.0:
		set(x):
			get_node("Time").set_value(x)
		get:
			return get_node("Time").get_value()
	
	
	func _init():
		name = "Alarm"
		
		var new_label := Button.new()
		new_label.name = "Label"
		new_label.custom_minimum_size.x = 32
		
		var new_time := SpinBox.new()
		new_time.name = "Time"
		new_time.alignment = HORIZONTAL_ALIGNMENT_CENTER
		new_time.select_all_on_focus = true
		new_time.max_value = 600
		new_time.step = 0.01
		
		var new_add_event := LineEdit.new()
		new_add_event.name = "AddEvent"
		new_add_event.placeholder_text = "Event"
		new_add_event.expand_to_text_length = true
		
		add_child(new_label, true, Node.INTERNAL_MODE_FRONT)
		add_child(new_time, true, Node.INTERNAL_MODE_FRONT)
		add_child(new_add_event, true, Node.INTERNAL_MODE_BACK)
		
		new_label.connect("button_down", _on_button_down.bind(new_label, self))
		new_add_event.connect("text_submitted", add_event)
	
	
	func add_event(event_text := ""):
		var new_event := Event.new()
		new_event.text = event_text if not event_text == "" else "Event"
		new_event.add_to_group("Event")
		
		add_child(new_event, true)
		new_event.owner = self
		
		new_event.connect("button_down", _on_button_down.bind(new_event))
		new_event.black_box.connect("state_toggled", func (toggle: bool): new_event.modulate = Color.WHITE if new_event.modulate == Color.RED and toggle else Color.RED if not toggle and new_event.modulate == Color.WHITE else new_event.modulate)
		
		owner.emit_signal("event_created", new_event)
	
	
	func get_event_list() -> Array[Event]:
		var list: Array[Event]
		list.append_array(get_children().filter(func (x): return x.is_in_group("Event")))
		return list
	
	
	func _on_button_down(button: Button, modulated = button, freed = modulated):
		await button.get_tree().create_timer(0.3)
		if is_instance_valid(button) and button.is_pressed():
			modulated.modulate = Color.WHITE if modulated.modulate == Color.DIM_GRAY else Color.DIM_GRAY if modulated.modulate == Color.WHITE else modulated.modulate
		else: return
		
		await button.get_tree().create_timer(0.5).timeout
		if is_instance_valid(button) and button.is_pressed():
			freed.queue_free()


var black_box := BlackBox.new()
var current_time:float = 0:
	set(x):
		$VBox/Control/CurrentTime/Animation.track_set_key_value(0, 0, x)
	get:
		return $VBox/Control/CurrentTime/Animation.track_get_key_value(0, 0)
var end_time := 1.0:
	set(x):
		$VBox/Control/EndTime.set_value(x)
	get:
		return $VBox/Control/EndTime.get_value()


func add_alarm(label := ""):
	var new_alarm := Alarm.new()
	new_alarm.label = label if not label == "" else "!"
	new_alarm.add_to_group("Alarm")
	
	$VBox/AlarmContainer/VBox.add_child(new_alarm, true)
	new_alarm.owner = self
	
	emit_signal("alarm_created", new_alarm)


func get_alarm_list() -> Array[Alarm]:
	var list: Array[Alarm]
	list.append_array($VBox/AlarmContainer/VBox.get_children().filter(func (x): return x.is_in_group("Alarm")))
	return list


func sort_by_time():
	var list := get_alarm_list()
	list.sort_custom(func (a, b): return a.time < b.time)
	for i in list:
		$VBox/AlarmContainer/VBox.move_child(i, -1)


func start():
	var alarm_list := get_alarm_list()
	var event_list: Dictionary
	var time_list := [0]
	
	for i in alarm_list.filter(func (x): return x.modulate == Color.WHITE):
		if not time_list.has(i.time):
			time_list.append(i.time)
			event_list.merge({i.time: []})
			
		for j in [i] + i.get_event_list().filter(func (x): return not x.modulate == Color.DIM_GRAY):
			event_list[i.time].append(j.black_box)
	time_list.sort()
	
	var animator := $VBox/Control/CurrentTime/Animation as AnimationPlayer
	var animation := animator.get_animation("start")
	animator.stop()
	
	for i in range(1, time_list.size()):
		animation.length = time_list[i]
		if time_list[i] > end_time:
			emit_signal("stopped", time_list[i - 1])
			return
		animation.track_set_key_value(0, 1, animation.length)
		animation.track_set_key_time(0, 1, animation.length)
		animator.play("start")
		await animator.animation_finished
		emit_signal("alarm", time_list[i])
		for j in event_list[time_list[i]] as Array[BlackBox]:
			j.run()
	emit_signal("finished")









