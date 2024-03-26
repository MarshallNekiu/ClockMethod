extends Node2D

@onready var clock:Clock = $Clock
@onready var clock2:Clock = $Clock2
@onready var clock3:Clock = $Clock3

func _ready():
	clock.black_box.input = Callable(func (): return clock.get_alarm_list().size() < 3)
	
	clock2.black_box.input = Callable(func (): return clock2.get_alarm_list().size() < 5)


func _on_clock_alarm_created(alarm: Clock.Alarm):
	var label = alarm.get_node("Label")
	if label.text == "Rotate":
		alarm.black_box.connect("state_toggled", func (toggle: bool):
			label.text = "ROTATE"
			if toggle:
				$Sprite2D/Animation.play("rotate"))


func _on_button_always_true_pressed():
	clock.black_box.input = Callable(func (): return true)
	clock.black_box.propagate_input(Callable(func (): return true))


func _on_button_propagate_unique_pressed():
	clock2.black_box.propagate_input(func (): return clock2.get_alarm_list().size() == 1)
	clock3.black_box.propagate_input(func (): return clock3.get_alarm_list().size() == 1)


func _on_clock_event_created(event: Clock.Alarm.Event):
	await get_tree().create_timer(0.1).timeout
	if event.get_parent().get_node("Label").text == "ROTATE" and event.text == "skew":
		event.black_box.input = func (): return true
		event.black_box.output = $Sprite2D/Animation.play.bind("rotateskew")


func _on_clock_2_alarm_created(alarm):
	var label = alarm.get_node("Label")
	if label.text == "offset":
		alarm.black_box.connect("state_toggled", func (toggle: bool):
			if toggle:
				$Sprite2D2/Animation.stop()
				$Sprite2D2/Animation.play("offset"))


func _on_clock_2_event_created(event):
	await get_tree().create_timer(0.1).timeout
	if event.get_parent().get_node("Label").text == "offset" and event.text == "scale":
		event.black_box.input = func (): return true
		event.black_box.output = func (): $Sprite2D2.scale *= 1.05


func _on_clock_3_event_created(event: Clock.Alarm.Event):
	if event.get_parent().get_node("Label").text == "Move":
		event.black_box.input = Callable(func (): return true)
		event.black_box.output = func ():
			if event.text.find("x"):
				$Sprite2D3.position.y += event.text.erase(0, 1).to_float()
			elif event.text.find("y"):
				$Sprite2D3.position.x += event.text.erase(0, 1).to_float()


func _process(delta):
	$Label.text = str($Clock3/VBox/Control/CurrentTime/Animation.current_animation_position, "\n", 60 - $Timer.time_left)


func _on_clock_3_started():
	$Timer.start()


















