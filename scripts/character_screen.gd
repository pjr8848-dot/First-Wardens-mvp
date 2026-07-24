extends PopupPanel

@onready var portrait_rect = $character_frame/character_background/portrait_texture
@onready var exit_panel = $character_frame/character_background/exit
@onready var health_panel = $character_frame/character_background/AttributesPanel/Health
@onready var strength_panel = $character_frame/character_background/AttributesPanel/Strength
@onready var defense_panel = $character_frame/character_background/AttributesPanel/Defense
@onready var speed_panel = $character_frame/character_background/AttributesPanel/Speed
@onready var xp_bar = $character_frame/character_background/AttributesPanel/XPBar
@onready var xp_panel = $character_frame/character_background/AttributesPanel/XPLabel
@onready var gold_panel = $character_frame/character_background/AttributesPanel/Gold

@onready var ability1_name = $character_frame/character_background/AbilitiesPanel/LeftColumn/Ability1Name
@onready var ability1_text = $character_frame/character_background/AbilitiesPanel/LeftColumn/Ability1Text
@onready var ability2_name = $character_frame/character_background/AbilitiesPanel/LeftColumn/Ability2Name
@onready var ability2_text = $character_frame/character_background/AbilitiesPanel/LeftColumn/Ability2Text
@onready var ability3_name = $character_frame/character_background/AbilitiesPanel/LeftColumn/Ability3Name
@onready var ability3_text = $character_frame/character_background/AbilitiesPanel/LeftColumn/Ability3Text
@onready var ability4_name = $character_frame/character_background/AbilitiesPanel/RightColumn/Ability4Name
@onready var ability4_text = $character_frame/character_background/AbilitiesPanel/RightColumn/Ability4Text
@onready var ability5_name = $character_frame/character_background/AbilitiesPanel/RightColumn/Ability5Name
@onready var ability5_text = $character_frame/character_background/AbilitiesPanel/RightColumn/Ability5Text
@onready var ability6_name = $character_frame/character_background/AbilitiesPanel/RightColumn/Ability6Name
@onready var ability6_text = $character_frame/character_background/AbilitiesPanel/RightColumn/Ability6Text

var inventory_slots: Array = []
var equipped_slots: Array = []

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
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
		
	popup_hide.connect(_on_popup_closed)
	update_attributes()
	generate_portrait()
	update_equipped_abilities()
	collect_slots()
	setup_slot_interactions()
	update_inventory_ui()

func _on_exit_pressed():
	PlayerData.emit_signal("health_changed", PlayerData.current_health)
	PlayerData.allow_equipping = false
	CombatManager.update_ui()
	update_attributes()
	queue_free()

func _on_popup_closed():
	PlayerData.emit_signal("health_changed", PlayerData.current_health)
	CombatManager.update_ui()
	update_attributes()
	PlayerData.allow_equipping = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func generate_portrait():
	if portrait_rect and PlayerData.portrait_path != "":
		var texture = load(PlayerData.portrait_path)
		if texture:
			portrait_rect.texture = texture
		else:
			print("Warning: Could not load portrait: ", PlayerData.portrait_path)

func setup_slot_interactions():
	for slot in inventory_slots:
		setup_single_slot(slot, true)   # inventory slots always active
	
	for slot in equipped_slots:
		setup_single_slot(slot, PlayerData.allow_equipping)

func setup_single_slot(slot: Control, enabled: bool):
	if not slot:
		return
	
	# Hover
	slot.mouse_entered.connect(func():
		if enabled:
			slot.modulate = Color(1.3, 1.2, 0.8)
	)
	slot.mouse_exited.connect(func():
		if enabled:
			slot.modulate = Color(1.0, 1.0, 1.0)
	)
	
	# Enable / disable interaction
	slot.mouse_filter = Control.MOUSE_FILTER_STOP if enabled else Control.MOUSE_FILTER_PASS
	
	#Enable click/drag/drop
	if enabled:
		slot.set_drag_forwarding(
			_get_drag_data.bind(slot),
			_can_drop_data.bind(slot),
			_drop_data.bind(slot)
		)
	
	#Enable right click
		slot.gui_input.connect(func(event):
			if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
				use_item(slot)
			)
	else:
		# Make trinkets look grayed out when locked
		var gray_style = StyleBoxFlat.new()
		gray_style.bg_color = Color(0.2, 0.2, 0.2, 0.8)
		slot.add_theme_stylebox_override("panel", gray_style)

func collect_slots():
	# Adjust the paths if your node names are slightly different
	for i in range(1, 25):
		var slot = get_node_or_null("character_frame/character_background/InventoryPanel/Inv_Row" + str((i-1)/8 + 1) + "/Item" + str(i))
		if slot:
			inventory_slots.append(slot)
	
	for i in range(1, 5):
		var slot = get_node_or_null("character_frame/character_background/EquippedPanel/Equipped" + str(i))
		if slot:
			equipped_slots.append(slot)

func update_attributes():
	health_panel.text = "Health: %d / %d" % [PlayerData.current_health, PlayerData.max_health]
	strength_panel.text = "Strength: %d" % PlayerData.strength
	defense_panel.text = "Defense: %d" % PlayerData.defense  
	speed_panel.text = "Speed: %d" % PlayerData.speed
	gold_panel.text = "Gold: %d" % PlayerData.gold
	
	# XP Progress
	var progress = float(PlayerData.current_xp) / PlayerData.get_xp_to_next_level() * 100.0
	xp_bar.value = progress
	xp_panel.text = "XP: %d / %d" % [PlayerData.current_xp, PlayerData.get_xp_to_next_level()]

# 1. Start dragging
func _get_drag_data(_at_position: Vector2, slot: Control):
	#var index = get_slot_index(slot)
	var item_id = ""
	
	if inventory_slots.has(slot):
		var i = inventory_slots.find(slot)
		item_id = PlayerData.full_inventory[i]
	elif equipped_slots.has(slot):
		var i = equipped_slots.find(slot)
		item_id = PlayerData.equipped_trinkets[i]
	
	if item_id == "":
		return null
	
	# Extract texture from StyleBoxTexture
	var texture = null
	var style = slot.get_theme_stylebox("panel")
	if style is StyleBoxTexture:
		texture = style.texture

	# Create preview
	var preview = TextureRect.new()
	if texture:
		preview.texture = texture
	preview.custom_minimum_size = Vector2(64, 64)  # adjust to your slot size
	preview.modulate.a = 0.9
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

	slot.set_drag_preview(preview)   # This should now work
	return {"source_slot": slot, "item_id": item_id}

# 2. Check if drop is valid
func _can_drop_data(_at_position: Vector2, data, _target_slot):
	return data is Dictionary and data.has("item_id") and data.item_id != ""

# 3. Perform the drop / swap
func _drop_data(_at_position: Vector2, data, target_slot):
	if not data is Dictionary:
		return
	
	var source_slot = data.source_slot
	var item_id = data.item_id
	
	var source_index = get_slot_index(source_slot)
	var target_index = get_slot_index(target_slot)
	
	# Swap logic
	if inventory_slots.has(source_slot) and inventory_slots.has(target_slot):
		# Inventory <-> Inventory
		var temp = PlayerData.full_inventory[target_index]
		PlayerData.full_inventory[target_index] = item_id
		PlayerData.full_inventory[source_index] = temp
	elif equipped_slots.has(source_slot) and equipped_slots.has(target_slot):
		# Trinket <-> Trinket
		var temp = PlayerData.equipped_trinkets[target_index]
		PlayerData.equipped_trinkets[target_index] = item_id
		PlayerData.equipped_trinkets[source_index] = temp
		PlayerData.apply_all_trinket_effects()
		update_attributes()
	elif inventory_slots.has(source_slot) and equipped_slots.has(target_slot):
		# Cross drag: Inventory <-> Trinket
		var source_idx = inventory_slots.find(source_slot)
		var target_idx = equipped_slots.find(target_slot)
		var temp = PlayerData.equipped_trinkets[target_idx]
		PlayerData.equipped_trinkets[target_idx] = item_id
		PlayerData.full_inventory[source_idx] = temp
		PlayerData.apply_all_trinket_effects()
		update_attributes()
	elif equipped_slots.has(source_slot) and inventory_slots.has(target_slot):
		# Cross drag: Trinket <-> Inventory
		var source_idx = equipped_slots.find(source_slot)
		var target_idx = inventory_slots.find(target_slot)
		var temp = PlayerData.full_inventory[target_idx]
		PlayerData.full_inventory[target_idx] = item_id
		PlayerData.equipped_trinkets[source_idx] = temp
		PlayerData.apply_all_trinket_effects()
		update_attributes()
	
	if data.source_slot:
		var empty_style = StyleBoxFlat.new()
		empty_style.bg_color = Color(0, 0, 0, 0)  # fully transparent
		data.source_slot.add_theme_stylebox_override("panel", empty_style)
	
	update_attributes()
	update_inventory_ui()

func get_slot_index(slot) -> int:
	if inventory_slots.has(slot):
		return inventory_slots.find(slot)
	elif equipped_slots.has(slot):
		return equipped_slots.find(slot)
	return -1

func use_item(slot: Control):
	# Find which slot this is and what item it has
	var item_id = ""
	var idx = -1
	
	if inventory_slots.has(slot):
		idx = inventory_slots.find(slot)
		item_id = PlayerData.full_inventory[idx]
	
	if item_id == "":
		return
	
	var item = Inventory.get_item_by_id(item_id)
	if item.is_empty():
		return
	
	# Example: Consumable
	if item.type == "Consumable" || item.subtype == "Consumable":
		if Inventory.use_consumable(item_id):
			# Remove the item after use
			if Inventory.was_not_consumed:
				print("Item was not used")
				Inventory.was_not_consumed = false
			elif inventory_slots.has(slot):
				PlayerData.full_inventory[idx] = ""
			
			var combat_manager = get_tree().get_first_node_in_group("combat_manager")
			if combat_manager and combat_manager.has_method("update_ui"):
				combat_manager.update_ui()
			
			update_inventory_ui()
			update_attributes()
			print("Used: ", item.name)
	else:
		print(item.name, " cannot be used this way.")
	update_attributes()

func update_equipped_abilities():
	var equipped = PlayerData.get_equipped_abilities()
	
	# Prepare all name + text label pairs
	var ability_slots = [
		[ability1_name, ability1_text],
		[ability4_name, ability4_text],
		[ability2_name, ability2_text],
		[ability5_name, ability5_text],
		[ability3_name, ability3_text],
		[ability6_name, ability6_text]
	]
	
	for i in range(6):
		var name_label = ability_slots[i][0]
		var text_label = ability_slots[i][1]
		
		if i < equipped.size():
			var ability = equipped[i]
			name_label.text = ability.get("name", "Unknown")
			text_label.text = ability.get("description", "No description available")
		else:
			name_label.text = ""
			text_label.text = ""

func update_inventory_ui():
	var empty_style = StyleBoxFlat.new()
	empty_style.bg_color = Color(0, 0, 0, 0)
	
	# === Inventory Slots (24) ===
	for i in range(24):
		var slot = inventory_slots[i]
		var item_id = PlayerData.full_inventory[i]
		
		if item_id != "":
			var item = Inventory.get_item_by_id(item_id)
			if not item.is_empty():
				slot.tooltip_text = item.get("name", "Unknown") + "\n" + item.get("description", "")
				
				var texture_path = item.get("image", "")
				if texture_path != "":
					var texture = load(texture_path)
					if texture:
						var style = StyleBoxTexture.new()
						style.texture = texture
						slot.add_theme_stylebox_override("panel", style)
					else:
						print("Failed to load image: ", texture_path)
				else:
					slot.add_theme_stylebox_override("panel", empty_style)
			else:
				slot.add_theme_stylebox_override("panel", empty_style)
		else:
			slot.add_theme_stylebox_override("panel", empty_style)
	
	# === Trinket Slots (4) ===
	for i in range(4):
		var slot = equipped_slots[i]
		var item_id = PlayerData.equipped_trinkets[i]

		if item_id != "":
			var item = Inventory.get_item_by_id(item_id)
			if not item.is_empty():
				slot.tooltip_text = item.get("name", "Unknown") + "\n" + item.get("description", "")
				slot.modulate = Color(0.2, 0.2, 0.2, .9)
				var texture_path = item.get("image", "")
				if texture_path != "":
					var texture = load(texture_path)
					if texture:
						var style = StyleBoxTexture.new()
						style.texture = texture
						slot.add_theme_stylebox_override("panel", style)
						if PlayerData.allow_equipping:
							slot.modulate = Color(1, 1, 1, 1)
					else:
						print("Failed to load image: ", texture_path)
				else:
					slot.remove_theme_stylebox_override("panel")
			else:
				slot.remove_theme_stylebox_override("panel")
		else:
			if PlayerData.allow_equipping:
				slot.add_theme_stylebox_override("panel", empty_style)
