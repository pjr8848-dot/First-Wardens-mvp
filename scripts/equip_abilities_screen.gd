extends Node

@onready var exit_panel = $AbilityFrame/Exit

var known_abilities: Array = []
var equipped_abilities: Array = []
var gold_style = StyleBoxFlat.new()

func _ready():
	print("equip_abilities_screen ready!")
	if exit_panel:
		exit_panel.mouse_entered.connect(func():
			exit_panel.modulate = Color(1.2, 1.1, 0.8)
	)
	exit_panel.mouse_exited.connect(func():
			exit_panel.modulate = Color(1.0, 1.0, 1.0)
	)
	exit_panel.gui_input.connect(func(event):
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_on_exit_pressed()
	)
	

	gold_style.bg_color = Color(0.18, 0.12, 0.06, 0.45)
	gold_style.border_blend = true
	gold_style.border_color = Color (0.85, 0.65, 0.25)
	gold_style.border_width_bottom = 4
	gold_style.border_width_top = 4
	gold_style.border_width_right = 4
	gold_style.border_width_left = 4
	gold_style.corner_radius_bottom_left = 12
	gold_style.corner_radius_bottom_right = 12
	gold_style.corner_radius_top_left = 12
	gold_style.corner_radius_top_right = 12
	
	
	collect_slots()
	update_known_abilities_ui()
	update_equipped_abilities_ui()
	setup_slot_interactions()

func collect_slots():
	# Adjust the paths if your node names are slightly different
	for i in range(1, 31):
		var slot = get_node_or_null("AbilityFrame/Abilities_Known_Panel/Column" + str((i-1)/10 + 1) + "/Known" + str(i))
		if slot:
			known_abilities.append(slot)
	
	for i in range(1, 7):
		var slot = get_node_or_null("AbilityFrame/Abilities_Equipped_Panel/Equipped" + str(i))
		if slot:
			equipped_abilities.append(slot)
	print("Known abilities size: " + str(known_abilities.size()))
	print("Known abilities size: " + str(equipped_abilities.size()))

func update_known_abilities_ui():
	var known = PlayerData.abilities_known
	var all_known_slots = []  # collect all Known1, Known2... labels from columns
	
	for column in [$AbilityFrame/Abilities_Known_Panel/Column1, $AbilityFrame/Abilities_Known_Panel/Column2, $AbilityFrame/Abilities_Known_Panel/Column3]:
		for child in column.get_children():
			if child.name.begins_with("Known"):
				all_known_slots.append(child)
	
	for i in range(all_known_slots.size()):
		var label = all_known_slots[i]
		if i < known.size():
			label.text = known[i].get("name", "Unknown")
			label.tooltip_text = known[i].get("description", "")
			label.add_theme_stylebox_override("normal", gold_style)
		else:
			label.text = ""
			label.tooltip_text = ""

func update_equipped_abilities_ui():
	var equipped = PlayerData.abilities_equipped
	for i in range(6):
		var slot = equipped_abilities[i]
		if i == 0:
			var gray_style = StyleBoxFlat.new()
			gray_style.bg_color = Color(0.25, 0.25, 0.25, 0.7)   # gray background
			gray_style.border_blend = true
			gray_style.border_color = Color (0.1, 0.1, 0.1, 0.7)
			gray_style.border_width_bottom = 4
			gray_style.border_width_top = 4
			gray_style.border_width_right = 4
			gray_style.border_width_left = 4
			gray_style.corner_radius_bottom_left = 12
			gray_style.corner_radius_bottom_right = 12
			gray_style.corner_radius_top_left = 12
			gray_style.corner_radius_top_right = 12
			slot.add_theme_stylebox_override("normal", gray_style)
			slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
			slot.text = equipped[i].get("name", "Empty")
		elif i < equipped.size() and equipped[i] != null:
			slot.text = equipped[i].get("name", "Empty")
			slot.add_theme_stylebox_override("normal", gold_style)
		else:
			slot.text = "Empty"
			slot.add_theme_stylebox_override("normal", gold_style)

func setup_slot_interactions():
	# Known abilities (left side) - always draggable
	for slot in known_abilities:
		if slot:
			setup_single_slot(slot, true)
	
	for i in range(equipped_abilities.size()):
		var slot = equipped_abilities[i]
		if slot and i != 0:        
			setup_single_slot(slot, true)

func setup_single_slot(slot: Control, enabled: bool):
	if not slot:
		return
	
	# Hover effect
	slot.mouse_entered.connect(func():
		if enabled:
			slot.modulate = Color(1.3, 1.2, 0.8)
	)
	slot.mouse_exited.connect(func():
		slot.modulate = Color(1.0, 1.0, 1.0)
	)
	
	slot.mouse_filter = Control.MOUSE_FILTER_STOP if enabled else Control.MOUSE_FILTER_IGNORE
	
	if enabled:
		slot.set_drag_forwarding(
			_get_drag_data.bind(slot),
			_can_drop_data.bind(slot),
			_drop_data.bind(slot)
		)

func _get_drag_data(at_position: Vector2, slot: Control):
	var ability = null
	
	# If dragging from Known abilities (left side)
	if known_abilities.has(slot):
		var idx = known_abilities.find(slot)
		ability = PlayerData.abilities_known[idx]
	# If dragging from Equipped slots (right side) - for unequipping
	elif equipped_abilities.has(slot):
		var idx = equipped_abilities.find(slot)
		if idx >= 0 and idx < PlayerData.abilities_equipped.size():
			ability = PlayerData.abilities_equipped[idx]
		else:
			return null
	
	# Create preview
	var preview = slot.duplicate()
	preview.modulate.a = 0.7
	slot.set_drag_preview(preview)
	
	return {"source_slot": slot, "ability": ability}

func _can_drop_data(at_position: Vector2, data, target_slot):
	return data is Dictionary and data.has("ability")

func _drop_data(at_position: Vector2, data, target_slot):
	if not data is Dictionary or not data.has("ability"):
		return
	
	var ability = data.ability
	var source_slot = data.source_slot
	
	# Dragging from Known → Equipped slot
	if known_abilities.has(source_slot) and equipped_abilities.has(target_slot):
		var target_idx = equipped_abilities.find(target_slot)
		
		# Prevent equipping the same ability twice
		if PlayerData.abilities_equipped.has(ability):
			print("This ability is already equipped!")
			return
		
		PlayerData.abilities_equipped[target_idx] = ability
		update_equipped_abilities_ui()
	
	# Dragging from Equipped → anywhere (unequip)
	elif equipped_abilities.has(source_slot):
		var source_idx = equipped_abilities.find(source_slot)
		PlayerData.abilities_equipped[source_idx] = null
		update_equipped_abilities_ui()

func _on_exit_pressed():
	PlayerData.emit_signal("health_changed", PlayerData.current_health)
	queue_free()
