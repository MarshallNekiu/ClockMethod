extends Node2D


func _on_button_toggled(toggled_on):
	for i in $Clock/VBox/Connected/VBox.get_children().filter(func (x): return x.is_in_group("Connection")) as Array[HBoxContainer]:
		for j in i.get_children().filter(func (x): return x.is_in_group("Event")) as Array[Button]:
			if toggled_on:
				j.set_meta("condition", no_number.bind(j.text))
			else:
				j.set_meta("condition", no_number)


func no_number(text := ""):
	for i in text:
		if i.is_valid_int():
			return false
	return true


func _on_button_3_toggled(toggled_on):
	for i in $Clock/VBox/Connected/VBox.get_children().filter(func (x): return x.is_in_group("Connection")) as Array[HBoxContainer]:
		for j in i.get_children().filter(func (x): return x.is_in_group("Event")) as Array[Button]:
			if toggled_on:
				j.set_meta("condition", Callable(func (): return j.text == j.text.to_upper()))
				OS.alert(j.text + str(j.get_meta("condition").call()))
			else:
				j.set_meta("condition", Callable(func (): return true))


func _on_button_2_toggled(toggled_on):
	for i in $Clock/VBox/Connected/VBox.get_children().filter(func (x): return x.is_in_group("Connection")) as Array[HBoxContainer]:
		for j in i.get_children().filter(func (x): return x.is_in_group("Event")) as Array[Button]:
			if toggled_on:
				j.set_meta("condition", Callable(func (): return j.text == j.text.to_lower() and no_number(j.text)))
			else:
				j.set_meta("condition", Callable(func (): return true))










