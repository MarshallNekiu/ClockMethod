extends Node2D


func _ready():
	var clock:Clock = $Clock as Clock
	clock.end_time = 3
	clock.add_alarm("Test")
	
	clock.add_alarm("Test2")
	var test2:Clock.Alarm = clock.get_alarm_list().back()
	test2.add_event("Test3")
	
	clock.add_alarm("Move")
	var move:Clock.Alarm = clock.get_alarm_list().back()
	move.time = 0.1
	move.add_event("Right")
	move.add_event("Jump")
	
	clock.add_alarm("Move")
	move = clock.get_alarm_list().back() as Clock.Alarm
	move.time = 0.3
	move.add_event("Jump")
	
	clock.add_alarm("Move")
	move = clock.get_alarm_list().back() as Clock.Alarm
	move.time = 1.3
	move.add_event("Left")
	
	clock.add_alarm("Force stop")
	var stop:Clock.Alarm = clock.get_alarm_list().back()
	stop.time = 3.01
	
	clock.add_alarm("End")
	var end:Clock.Alarm = clock.get_alarm_list().back()
	end.time = 2.9
	
	


func _on_clock_alarm_created(alarm: Clock.Alarm):
	match alarm.label:
		"Test":
			alarm.black_box.input = func (): return get_tree().get_frame() % 2 == 0
			
			alarm.black_box.connect("state_toggled", func (toggled: bool): GlobalScript.get_Debugger(self).insert_line_at(0, str("TEST: ODD FRAME: ", get_tree().get_frame(), ": ", str(not toggled)).to_upper()))
		"Test2":
			alarm.black_box.output = func (): GlobalScript.get_Debugger(self).insert_line_at(0, str(alarm.label, ": NO INPUT, OUTPUT PRINT THIS."))


func _on_clock_event_created(event: Clock.Alarm.Event):
	match event.text:
		"Test3":
			event.black_box.output = func (): GlobalScript.get_Debugger(self).insert_line_at(0, str("TEST3: ", event.get_path()))
	
	match (event.owner as Clock.Alarm).label:
		"Move":
			event.black_box.input = func(): return get_tree().get_frame() % 2 == 0
			match event.text:
				"Jump":
					event.black_box.input = ($CharacterBody2D as CharacterBody2D).is_on_floor
					event.black_box.output = Input.action_press.bind("ui_accept")
				"Left":
					event.black_box.input = func (): return $CharacterBody2D.position.x > 400
					event.black_box.output = func ():
						Input.action_release("ui_right")
						Input.action_press("ui_left")
				"Right":
					event.black_box.input = func (): return $CharacterBody2D.position.x < 1600
					event.black_box.output = func ():
						Input.action_release("ui_left")
						Input.action_press("ui_right")


func _on_clock_finished():
	GlobalScript.get_Debugger(self).insert_line_at(0, "FINISHED")
	Input.action_release("ui_accept")
	Input.action_release("ui_left")
	Input.action_release("ui_right")


func _on_clock_stopped(time):
	GlobalScript.get_Debugger(self).insert_line_at(0, str("STOPPED", time))
	Input.action_release("ui_accept")
	Input.action_release("ui_left")
	Input.action_release("ui_right")













