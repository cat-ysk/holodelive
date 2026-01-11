extends Control


func _on_single_game_button_pressed() -> void:
	# TODO: シングルゲームシーンに遷移
	pass


func _on_multiplayer_button_pressed() -> void:
	# TODO: マルチプレイヤーシーンに遷移
	pass


func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/title/title_scene.tscn")
