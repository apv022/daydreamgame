extends VBoxContainer
const WORLD = preload("res://world.tscn")


func _on_new_game_pressed():
	get_tree().change_scene_to_packed(WORLD)




func _on_quit_pressed():
	get_tree().quit()
