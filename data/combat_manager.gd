extends CanvasLayer

@onready var current_character: Node = null

@onready var ap_label = get_node_or_null("/root/CombatUI/MainUI/AP_Label")
@onready var player_status_container = get_node_or_null("/root/CombatUI/MainUI/PlayerStatus")
@onready var initiative_container = get_node_or_null("/root/CombatUI/InitiativeBar")

@onready var btn_basic_attack = get_node_or_null("/root/CombatUI/MainUI/ActionButtons/Btn_Attack")
@onready var btn_abilities = get_node_or_null("/root/CombatUI/MainUI/ActionButtons/Btn_Abilities")
@onready var btn_end_turn = get_node_or_null("/root/CombatUI/MainUI/ActionButtons/Btn_EndTurn")

@onready var abilities_panel = get_node_or_null("/root/CombatUI/MainUI/AbilitiesPanel")
@onready var ability_grid = get_node_or_null("/root/CombatUI/MainUI/AbilitiesPanel/AbilityGrid")

@onready var character_sprite = get_node_or_null("/root/CombatUI/Background/CharacterSprite")

var initiative_ticks: Dictionary = {}
var enemies: Array = []
var initiative_queue: Array = []
var current_actor_index: int = 0
var current_target = null
var combat_state = "RUNNING"  # "RUNNING", "PLAYER_TURN"
var first_turn: bool = true

#MULTI TARGET
var multi_target_mode: bool = false
var multi_target_ability: Dictionary = {}
var multi_targets: Array = []
var max_multi_targets: int = 0

func _on_abilities_pressed():
	abilities_panel.visible = not abilities_panel.visible
	update_ui()

func _on_ap_changed(_new_ap: int):
	if ap_label:
		ap_label.text = "Action Points: " + str(current_character.ap)

func _on_end_turn_pressed():
	# === REAL SPEED / INITIATIVE SYSTEM ===
	# Give "ticks" to everyone based on their speed
	if combat_state == "PLAYER_TURN":
		current_character.end_turn()
		apply_status_effects(current_character)
		await get_tree().create_timer(.2).timeout
		combat_state = "RUNNING"     #Resume the loop
	update_ui()

func _on_basic_attack_pressed():
	if current_target == null:
		print("No target selected, please select a target!")
		return
	var result = await current_character.basic_attack(current_target)
	
	if result is bool and result == true:
		pass
	elif result is int and result > 0:
		deal_damage(current_target, result)
	
	check_if_target_killed(current_target)


func check_for_victory():
	if enemies.size() == 0:
	# After victory:
		PlayerData.is_in_combat = false
		PlayerData.strength = PlayerData.base_strength
		PlayerData.defense = PlayerData.base_defense
		PlayerData.speed = PlayerData.base_speed
		PlayerData.apply_all_trinket_effects()
		PlayerData.save_character(current_character)
		var victory_popup = preload("res://scenes/victory_screen.tscn").instantiate()
		add_child(victory_popup)

func handle_multi_target_click(enemy):
	if not multi_target_mode:
		return false
		
	multi_targets.append(enemy)
	print("Multi-target selected: ", enemy.name, " (", multi_targets.size(), "/", max_multi_targets, ")")
	
	if multi_targets.size() >= max_multi_targets:
		fire_multi_target_ability()
	
	return true

func fire_multi_target_ability():
	if not multi_target_ability or multi_targets.size() == 0:
		multi_target_mode = false
		return
	
	var damage = multi_target_ability.get("damage", current_character.strength)
	var is_true_damage = multi_target_ability.get("true_damage", false)
	
	for target in multi_targets:
		if is_instance_valid(target):
			if is_true_damage:
				deal_true_damage(target, damage)
			else:
				deal_damage(target, damage)
	
	# Reset everything
	multi_target_mode = false
	multi_targets.clear()
	update_ui()

func clear_enemies():
		# Clear any old enemies
	for e in enemies:
		e.queue_free()
	enemies.clear()

func create_enemies(enemy_type: GDScript):
	var enemy = enemy_type.new()
	enemy.name = enemy.get("Name") if enemy.get("Name") != null else "Enemy"
	# Force unique name to prevent Godot auto-renaming
	enemy.name = enemy.name + " " + str(enemies.size() + 1)
	add_child(enemy)
	enemies.append(enemy)
	
	# Set first enemy as default target
	if enemies.size() > 0:
		current_target = enemies[0]

func update_initiative_bar():
	for child in initiative_container.get_children():
		child.queue_free()
	
	# Background timeline bar
	var timeline = Panel.new()
	timeline.custom_minimum_size = Vector2(950, 12)
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.25, 0.25, 0.35)
	timeline.add_theme_stylebox_override("panel", style)
	initiative_container.add_child(timeline)
	
	# Create entities on the timeline
	var all_entities = [current_character] + enemies
	all_entities = all_entities.filter(func(e): return e.current_health > 0)
	
	for entity in all_entities:
		var container = VBoxContainer.new()
		container.custom_minimum_size = Vector2(60, 90)
		
		# Icon
		var icon = Label.new()
		icon.text = "🧍‍♂️" if entity == current_character else "👹"
		icon.add_theme_font_size_override("font_size", 36)
		icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		container.add_child(icon)
		
		# Name
		var name_lbl = Label.new()
		name_lbl.text = entity.name if "name" in entity else current_character.name
		name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		container.add_child(name_lbl)
		
		# Position based on progress toward 1000 ticks
		var current_tick = initiative_ticks.get(entity, 0)
		var position_ratio = clamp(current_tick / 1000.0, 0.0, 1.0)
		container.position = Vector2(position_ratio * 900, 10)  # wider bar
		
		timeline.add_child(container)

func _ready():
	PlayerData.is_in_combat = true
	PlayerData.xp_earned = 0
	add_to_group("combat_manager")
	
	var node = MapsData.current_node
	var group = node.enemy_group if node else "easy"
	CombatsData.spawn_group(group, self)
	
	#Select correct character node
	match PlayerData.character_name:
		"Thyros":
			PlayerData.set_active_character($Thyros)
			current_character = PlayerData.current_character
		"Caela":
			PlayerData.set_active_character($Caela)
			current_character = PlayerData.current_character
		"Valen":
			PlayerData.set_active_character($Valen)
			current_character = PlayerData.current_character
		#ADD MORE CHARACTERS HERE

	if current_character == null or not is_instance_valid(current_character):
		print("ERROR: No valid current_character in PlayerData!")
		return

	PlayerData.load_into_character(current_character)
	
	print("CURRENT CHARACTER ", PlayerData.current_character.name)
	
	current_character = PlayerData.current_character
	
	if current_character.has_signal("ap_changed"):
		current_character.ap_changed.connect(_on_ap_changed)
	
	await btn_basic_attack.pressed.connect(_on_basic_attack_pressed)
	btn_abilities.pressed.connect(_on_abilities_pressed)
	btn_end_turn.pressed.connect(_on_end_turn_pressed)

	initiative_ticks = {}
	for e in [current_character] + enemies:
		initiative_ticks[e] = 0
	
	var bar_timer = Timer.new()
	bar_timer.wait_time = 0.01   # Update ~20 times per second
	bar_timer.timeout.connect(update_initiative_bar)
	add_child(bar_timer)
	bar_timer.start()
	
	var timer = Timer.new()
	timer.wait_time = 0.1 #how fast the ticker runs
	timer.timeout.connect(advance_initiative)
	add_child(timer)
	timer.start()
	
	update_ui()

func enemy_turn(enemy: Node):
	print("================= ", enemy.name, "'s Turn (Speed ", enemy.speed, ") ======================")
	
	var action = enemy.take_turn()  # This calls the function in basic_enemy.gd
	
	# Handle different action types
	if action.type.contains("block"):
		enemy.block_this_turn = action.get("block", 0)
		print(enemy.name, " gained ", action.get("block", 0), " block")
		
	if action.type.contains("attack"):
		var dmg = action.value
		#check for if the enemy is weak, and reduce their damage if it is
		if enemy.weak > 0:
			dmg = dmg*.67
		var compare_health_1: int = current_character.current_health
		deal_damage(current_character, dmg)
		var compare_health_2: int = current_character.current_health
		if((current_character.parry_riposte)&&(compare_health_1==compare_health_2)):
			current_character.has_attacked_this_turn = false
			deal_damage(enemy, current_character.basic_attack())
			current_character.has_attacked_this_turn = false
	
	if action.type.contains("buff"):
		# Example: strength buff
		if action.has("buff"):
			enemy.strength += action.buff
			print(enemy.name, " gained +", action.buff, " Strength")
			
	if action.type.contains("debuff"):
		if action.has("vulnerable"):
			current_character.vulnerable += action.vulnerable
			print (current_character.name, " afflicted with ", action.vulnerable, " turns of Vulnerable")
		if action.has("weak"):
			current_character.weak += action.weak
			print (current_character.name, " afflicted with ", action.weak, " turns of Weak")
		if action.has("tripped"):
			current_character.tripped += action.tripped
			print (current_character.name, " afflicted with ", action.tripped, " turns of Tripped")
		if action.has("ensnared"):
			current_character.ensnared = action.ensnared
			print (current_character.name, " afflicted with ensnared, speed reduced by 50%")
		if action.has("bleed"):
			current_character.bleed += action.bleed
			print (current_character.name, " afflicted with ", action.bleed, " stacks of Bleed")
	
	if action.type.contains("multi_hit"):
		var dmg = action.value
		if enemy.weak > 0:
			dmg = dmg*.67
		var count = action.get("count", 1)
		for i in range(count):
			var compare_health_1: int = current_character.current_health
			deal_damage(current_character, dmg)
			var compare_health_2: int = current_character.current_health
			print(name, " hit for ", dmg, " (", i+1, "/", count, ")")
			if((current_character.parry_riposte)&&(compare_health_1==compare_health_2)):
				current_character.has_attacked_this_turn = false
				deal_damage(enemy, current_character.basic_attack())
				current_character.has_attacked_this_turn = false
			await get_tree().create_timer(0.2).timeout  # optional pause
	
	if action.type.contains("haste"):
		enemy.hasted += action.hasted
	
	apply_status_effects(enemy)
	update_ui()

func advance_initiative():
	if combat_state != "RUNNING":
		return # paused
	
	# Remove dead entities
	var to_remove = []
	for e in initiative_ticks.keys():
		if not is_instance_valid(e) or e.current_health <= 0:
			to_remove.append(e)
	for e in to_remove:
		initiative_ticks.erase(e)
	
	# Give ticks to everyone
	for e in initiative_ticks.keys():
		initiative_ticks[e] += e.speed
	
	# Find all actors who reached the threshold this cycle
	var actors_ready = []
	for e in initiative_ticks.keys():
		if e.current_health > 0 and initiative_ticks[e] >= 1000:
			actors_ready.append(e)
	
	if actors_ready.size() == 0:
		return  # No one ready yet
	
	# Sort by highest overflow (most ticks over 1000 first)
	actors_ready.sort_custom(func(a, b): 
		return initiative_ticks[a] > initiative_ticks[b]
	)
	
	# Process all ready actors in order
	for actor in actors_ready:
		initiative_ticks[actor] -= 1000  # Keep overflow
		
		if actor == current_character:
			combat_state = "PLAYER_TURN"
			current_character.start_new_turn()
			#Apply Rixas Blessing!
			if Inventory.has_rixas_blessing:
				var roll = randi() % 3
				if roll == 0:
					current_character.strength += 1
					PlayerData.strength += 1
					print("Rixas Blessing granted +1 Strength this turn")
				elif roll == 1:
					current_character.defense += 1
					PlayerData.defense += 1
					print("Rixas Blessing granted +1 Defense this turn")
				else:
					current_character.speed += 10
					PlayerData.speed += 10
					print("Rixas Blessing granted +10 Speed this turn")
			#End Rixas Blessing Application
			update_ui()
			if PlayerData.has_heavy_shield:
				current_character.block_this_turn = 2
			if current_character.stunned > 0:
				_on_end_turn_pressed()
			if first_turn:
				first_turn = false
				#Check for Energy Ring
				if PlayerData.equipped_trinkets.has("energy_ring"):
					current_character.ap += 1
					print("Energy Ring: +1 AP at start of combat!")
					update_ui()			
			break  # Player gets priority if both ready
		else:
			enemy_turn(actor)
	
	update_ui()
	
	for e in enemies.duplicate():
		if e.current_health <= 0:
			enemies.erase(e)
			e.queue_free()
		
	update_ui()


func update_status_for(entity, container: HBoxContainer):
	# Clear old statuses
	for child in container.get_children():
		child.queue_free()
	
	# Burn
	if "burn" in entity and entity.burn > 0:
		var lbl = Label.new()
		lbl.text = "🔥 Burn " + str(entity.burn)
		container.add_child(lbl)
	
	if "bleed" in entity and entity.bleed > 0:
		var lbl = Label.new()
		lbl.text = "🩸 Bleed " + str(entity.bleed)
		container.add_child(lbl)
	
	if "vulnerable" in entity and entity.vulnerable > 0:
		var lbl = Label.new()
		lbl.text = "💔 " + str(entity.vulnerable)
		container.add_child(lbl)
	
	if "weak" in entity and entity.weak > 0:
		var lbl = Label.new()
		lbl.text = "🦴 " + str(entity.weak)
		container.add_child(lbl)
	
	if "tripped" in entity and entity.tripped > 0:
		var lbl = Label.new()
		lbl.text = "🦶 Tripped " + str(entity.tripped)
		container.add_child(lbl)
		
	if "block_this_turn" in entity and entity.block_this_turn > 0:
		var lbl = Label.new()
		lbl.text = "🛡️ " + str(entity.block_this_turn)
		container.add_child(lbl)
		
	if "parry_riposte" in entity and entity.parry_riposte == true:
		var lbl = Label.new()
		lbl.text = "⚔️ Riposte"
		container.add_child(lbl)
		
	if "ensnared" in entity and entity.ensnared == true:
		var lbl = Label.new()
		lbl.text = "🪹 Ensnare"
		container.add_child(lbl)
		
	if "hasted" in entity and entity.hasted > 0:
		var lbl = Label.new()
		lbl.text = "❯❯❯❯" + str(entity.hasted)
		container.add_child(lbl)
	
	if "stunned" in entity and entity.stunned > 0:
		var lbl = Label.new()
		lbl.text = "💫 " + str(entity.stunned)
		container.add_child(lbl)

func update_enemy_ui():
	for child in $EnemiesContainer.get_children():
		child.queue_free()
	
	for e in enemies:
		#create enemy sprite/art
		var enemy_sprite = TextureRect.new()
		enemy_sprite.texture = load(e.sprite_path) if e.sprite_path else null
		enemy_sprite.scale = Vector2(0.6, 0.6)  # adjust size as needed
		enemy_sprite.position = Vector2(-75, -400)  # adjust position inside panel
		
		var panel = Panel.new()
		panel.custom_minimum_size = Vector2(200, 200)
		
		#Highlight selected target
		var style = StyleBoxFlat.new()
		if e == current_target:
			style.bg_color = Color(0.3, 0.6, 1.0, 0.4)  # Light blue highlight
		else:
			style.bg_color = Color(0.15, 0.15, 0.2, 0.9) # Dark background
		panel.add_theme_stylebox_override("panel", style)
		
		panel.add_child(enemy_sprite)
		
		# Make panel/sprite respond to hover and click
		panel.mouse_filter = Control.MOUSE_FILTER_STOP
		panel.mouse_entered.connect(func():
			panel.modulate = Color(1.3, 1.2, 0.8)  # highlight
		)
		panel.mouse_exited.connect(func():
			panel.modulate = Color(1, 1, 1)
		)
		
		# Make the whole panel clickable
		panel.mouse_filter = Control.MOUSE_FILTER_STOP  # Makes it clickable
		panel.gui_input.connect(func(event):
			
			if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
				if multi_target_mode:
					handle_multi_target_click(e)
				
				current_target = e
				print("Selected target: ", e.name)
				update_ui()  # Refresh to show highlight
		)
		
		var vbox = VBoxContainer.new()
		panel.add_child(vbox)
		
		var name_lbl = Label.new()
		name_lbl.text = e.name
		vbox.add_child(name_lbl)
		
		var intent_lbl = Label.new()
		intent_lbl.text = "Intent: " + e.get_current_intent()
		vbox.add_child(intent_lbl)
		
		var hp_bar = ProgressBar.new()
		hp_bar.max_value = e.max_health
		hp_bar.value = e.current_health
		hp_bar.custom_minimum_size = Vector2(160, 20)
		vbox.add_child(hp_bar)
		
		var hp_lbl = Label.new()
		hp_lbl.text = "HP: " + str(e.current_health) + "/" + str(e.max_health)
		vbox.add_child(hp_lbl)
		
		# Status
		var status_box = HBoxContainer.new()
		vbox.add_child(status_box)
		update_status_for(e, status_box)
		
		$EnemiesContainer.add_child(panel)

func check_player_damage_conditionals(_target, amount: int):
	if PlayerData.has_burnheart_charm && current_character.burn > 0:
		amount = amount +2
	
	if PlayerData.current_character.weak > 0:
		amount = int(amount*.67)
		
	return amount

func update_ui():
	# Player side
	if ap_label == null:
		return
	ap_label.text = "Action Points: " + str(current_character.ap)
	update_status_for(current_character, player_status_container)
	PlayerData.emit_signal("health_changed", PlayerData.current_health)

	if current_character and current_character.sprite_path != "":
		var texture = load(current_character.sprite_path)
		if texture:
			character_sprite.texture = texture

	# Enemy side
	update_enemy_ui()
	
	#refresh cooldowns
	setup_ability_buttons() 
	
	#initiative
	update_initiative_bar()

func calculate_damage_for_enemy_intent(attacker, amount: int) -> int:
	var damage = amount
	var target = PlayerData.current_character

	if "bleed" in target and target.bleed > 0:
		damage += target.bleed
	
	if "vulnerable" in target and target.vulnerable > 1:
		#Special caseL if it's player's turn and vulnerable is about to decay
		if combat_state == "PLAYER_TURN" and target.vulnerable <= 1:
			pass #ignore Vulnerable this turn
		else:
			damage = int(damage *1.5)
	
	if "weak" in attacker and attacker.weak > 0:
		damage = int(damage *0.67)
	
	return damage

func deal_damage(target, amount: int):
	if target == current_character:
		var dodged = false
		# Call the handler and check if damage was fully dodged
		if current_character.has_method("_on_before_damage_taken"):
			dodged = current_character._on_before_damage_taken(amount)
	
		if dodged:
			return  # Cancel the damage completely
	
	if target.bleed > 0:
		amount = amount + target.bleed
		target.bleed = 0
	
	var block = target.block_this_turn if "block_this_turn" in target else 0
	if(target.vulnerable > 0):
		amount = int(amount * 1.5)
	
	if target == current_character && target.block_this_turn <= 0:
		PlayerData.before_damage_taken.emit(amount)
	
	if amount > block:
		var actual_damage = max(0, amount - block)
		if target == current_character:
			PlayerData.before_damage_taken.emit(amount)
		target.current_health = max(0, target.current_health - actual_damage)
		target.block_this_turn = 0
		print(target.name, " blocked ", block, " damage! Took ", actual_damage, " damage")
		#Apply Venari Blessing!
		if target != current_character && Inventory.has_venari_blessing:
			var lifesteal = max(1, actual_damage/20)
			print("Venari Blessing Equipped: lifesteal " + str(lifesteal))
			current_character.current_health = min(current_character.current_health + lifesteal, current_character.max_health)
		#End Venari Blessing Application
	else:
		block = block - amount
		target.block_this_turn = block
		print(target.name, " blocked ", amount, " damage! Have ", block, " remaining")
		
	check_if_target_killed(target)

func deal_true_damage(target, amount: int):
	if target == current_character:
		var dodged = false
		# Call the handler and check if damage was fully dodged
		if current_character.has_method("_on_before_damage_taken"):
			dodged = current_character._on_before_damage_taken(amount)
	
		if dodged:
			return  # Cancel the damage completely
	
	if amount <= 0:
		return
	if(target.vulnerable > 0):
		amount = int(amount * 1.5)
	
	#Apply Venari Blessing
	if target != current_character && Inventory.has_venari_blessing:
		var lifesteal = max(1, amount/20)
		current_character.current_health = min(current_character.current_health + lifesteal, current_character.max_health)
	#End Venari Blessing Application
	
	target.current_health = max(0, target.current_health - amount)
	print(target.name, " took ", str(amount), " True Damage\nTrue Damage ignores block")
	
	check_if_target_killed(target)


func check_if_target_killed(target):
	if target == null or not is_instance_valid(target):
		return

	if target.current_health <= 0:
		#defeat logic
		if target == current_character:
			print(" === GAME OVER - ", current_character.name, " has fallen! ===")
			
			#Stop initiative ticker
			for child in get_children():
					if child is Timer:
						child.stop()
			
			await get_tree().create_timer(3.0).timeout
			get_tree().quit()
			#TODO: show defeat screen later
		else:
			PlayerData.current_xp += target.xp_value
			PlayerData.xp_earned += target.xp_value
			PlayerData.total_xp += target.xp_value
			
			var enemy_name = target.name
			
			#remove defeated enemy
			if target in enemies:
				if is_instance_valid(target) && current_character.name == "Valen":
					current_character.add_ap(1)
				#Check Venari Blessing (2nd aspect)
				elif is_instance_valid(target) && Inventory.has_venari_blessing:
					current_character.add_ap(1)
				#End Venari Blessing 2nd Check
				print(enemy_name, " has been defeated and removed from the battlefield")
				
				if target in enemies:
					enemies.erase(target)
					
				target.queue_free()
				
				check_for_victory()
				
	PlayerData.save_character(current_character)
	update_ui()


func apply_status_effects(target=null):
	if target == null or not is_instance_valid(target) or target.current_health <= 0:
		return
	
	# Apply to Current Character
	if target==current_character:
		if current_character.burn > 0:
			deal_damage(current_character, current_character.burn)
			print(current_character.name, " took ", current_character.burn, " burning damage")
		
		if current_character.vulnerable > 0:
			current_character.vulnerable = max(0, current_character.vulnerable -1)
		
		if current_character.stunned > 0:
			current_character.stunned = max(0, current_character.stunned -1)
		
		if current_character.stunned > 0:
			current_character.weak = max(0, current_character.weak -1)
		
		if current_character.tripped:
			current_character.tripped = max(0, current_character.tripped -1)
			current_character.speed = current_character.speed*.9
			if current_character.tripped <= 0:
				current_character.speed = PlayerData.base_speed
		
		if current_character.ensnared:
			current_character.ensnared = false
			current_character.speed = PlayerData.speed
			
		if current_character.weak > 0:
			current_character.weak = max(0, current_character.weak -1)
		
		if current_character.hasted > 0:
			current_character.speed = PlayerData.hasted_speed
			current_character.hasted = max(0, current_character.hasted - 1)
			if current_character.hasted <= 0:
				current_character.speed = PlayerData.base_speed
		return
		
	# Apply to enemy
	if target.burn > 0:
		print(target.name, " took ", target.burn, " burning damage")
		if (PlayerData.has_burnheart_charm):
			deal_damage(target, (target.burn -2))
		else:
			deal_damage(target, target.burn)
	if target.vulnerable > 0:
		target.vulnerable = max(0, target.vulnerable - 1)
	if target.bleed > 0:
		target.bleed = max(0, target.bleed - 1)
	if target.weak > 0:
		target.weak = max(0, target.weak -1)
	if target.ensnared:
		target.ensnared = false
		target.speed = target.base_speed
	if target.tripped:
		target.tripped = max(0, target.tripped -1)
		target.speed = target.speed*.9
		if target.tripped <= 0:
			target.speed = target.base_speed
	if target.hasted > 0:
		target.speed = target.hasted_speed
		target.hasted = max(0, target.hasted -1)
		if target.hasted <= 0:
			target.speed = target.base_speed

func setup_ability_buttons():
	btn_basic_attack.text = "Basic Attack" 
	btn_basic_attack.tooltip_text = current_character.get_basic_attack_info()
	btn_abilities.text = "Abilities ▼"
	btn_end_turn.text = "End Turn"
	
	for child in ability_grid.get_children():
		child.queue_free()
	
	var abilities = PlayerData.get_equipped_abilities()
	
	for ability in abilities:
		if ability == null:
			continue
		var btn = Button.new()
		
		# Dynamic cooldown display
		var cooldown = 0
		if ability.has("cooldown_var"):
			cooldown = current_character.get(ability.cooldown_var)

		var display_text = ability.name + " (" + str(ability.cost) + " AP)"
		if ability.has("dynamic_cost_func"):
				display_text = ability.name + " (" + str(current_character.call(ability.dynamic_cost_func, ability.name)) + " AP)"
		if cooldown > 0:
			display_text = ability.name + " (" + str(cooldown) + " CD)"
			btn.disabled = true
		elif ability.has("extra_text"):
			display_text += ability.extra_text
		
		if ability.has("description"):
			btn.tooltip_text = ability.description
		
		
		### SPECIAL CODE FOR VALEN'S SHADOW STEP!
		if ability.name == "Shadow Step":
			if current_character.shadow_step_active:
				btn.add_theme_color_override("font_color", Color(1.0, 0.8, 0.0))  # bright gold/orange
				btn.add_theme_font_size_override("font_size", 18)                # slightly bigger
				btn.text = "Shadow Step (ACTIVE)"
			else:
				btn.add_theme_color_override("font_color", Color(1, 1, 1))
				btn.text = "Shadow Step"
		
		### SPECIAL CODE FOR THYROS SPLIT BLADES!
		if ability.name == "Split Blades":
			if current_character.split_blade_active:
				btn.modulate = Color(0.3, 0.3, 0.3, 0.4)
				btn.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
		### SPECIAL CODE FOR THYROS BLAZING INFERNO
		if ability.name == "Blazing Inferno":
			if current_character.blazing_inferno_active:
				btn.modulate = Color(0.3, 0.3, 0.3, 0.4)
				btn.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
		btn.text = display_text
		
		# Button press logic
		btn.pressed.connect(func():
			if cooldown > 0:
				return  # Don't allow use while on cooldown
			var result = await current_character.call(ability.function, current_target)
			if result is bool:
				update_ui()
				return
			# NEW LOGIC: HANDLE MULTI TARGETING AND TRUE DAMAGE #
			if result is Dictionary:
				if result.get("type") == "multi_target":
					multi_target_mode = true
					multi_target_ability = result
					multi_targets.clear()
					max_multi_targets = result.get("max_targets", 3)
					print("Multi-target mode activated: ", result.get("name"), " (select up to ", max_multi_targets, " targets)")
					return
				elif result.get("true_damage", false):
					#true damage ability
					var damage = result.get("damage", 0)
					damage = check_player_damage_conditionals(current_target, damage)
					deal_true_damage(current_target, damage)
			# ORIGINAL COMBAT LOGIC
			if result is int and result > 0:
				if ability.get("aoe",false):
					#AoE - hit ALL enemies
					var current_enemies = enemies.duplicate()
					for e in current_enemies:
						if is_instance_valid(e) and e.current_health > 0:
							var damage = check_player_damage_conditionals(e, result)
							deal_damage(e, damage)
				else:
					#single target
					if current_target == null:
						print("No target selected!")
						return
					var damage = check_player_damage_conditionals(current_target, result)
					deal_damage(current_target, damage)
			
			for e in enemies:
				check_if_target_killed(e)
			update_ui()
		)
		ability_grid.add_child(btn)
