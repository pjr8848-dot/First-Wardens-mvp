extends PopupPanel

@onready var description_label = $events_background/event_text
@onready var choice1 = $events_background/option1
@onready var choice1_label = $events_background/option1/option1_text
@onready var choice2 = $events_background/option2
@onready var choice2_label = $events_background/option2/option2_text
@onready var confirm_button = $events_background/confirm

var current_event_data = null
var selected_choice = -1  # 0 or 1

func _ready():
	# Reset visuals
	choice1.modulate = Color(1,1,1)
	choice2.modulate = Color(1,1,1)
	confirm_button.mouse_filter = Control.MOUSE_FILTER_IGNORE


func show_event(event_data: Dictionary):
	current_event_data = event_data
	selected_choice = -1
	confirm_button.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	description_label.text = event_data.get("description", "An unexpected event...")
	choice1_label.text = event_data.get("choice1_text", "Choice 1")
	choice2_label.text = event_data.get("choice2_text", "Choice 2")
	
	choice1.tooltip_text = event_data.get("choice1_tooltip", "No information")
	choice2.tooltip_text = event_data.get("choice2_tooltip", "No information")
	
	popup_centered()
	show()

	# Connect inputs once
	if not choice1.has_meta("connected"):
		choice1.set_meta("connected", true)
		
		choice1.gui_input.connect(func(event):
			if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
				select_option(0)
		)
		choice2.gui_input.connect(func(event):
			if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
				select_option(1)
		)
		confirm_button.gui_input.connect(func(event):
			if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
				_on_confirm_pressed()
		)

func select_option(choice: int):
	selected_choice = choice
	choice1.modulate = Color(1.3, 1.1, 0.5) if choice == 0 else Color(1,1,1)
	choice2.modulate = Color(1.3, 1.1, 0.5) if choice == 1 else Color(1,1,1)
	confirm_button.mouse_filter = Control.MOUSE_FILTER_STOP

func _on_confirm_pressed():
	if selected_choice == -1 or current_event_data == null:
		return
	
	var outcomes = current_event_data.get("outcomes", [])
	if selected_choice < outcomes.size():
		var outcome = outcomes[selected_choice]
		
		# === APPLY OUTCOME ===
		if outcome.has("xp"):
			PlayerData.current_xp += outcome.xp
			PlayerData.total_xp += outcome.xp
			print("Gained ", outcome.xp, " XP")
		
		if outcome.has("heal"):
			PlayerData.current_health = min(PlayerData.max_health, PlayerData.current_health + outcome.heal)
			print("Healed for ", outcome.heal)
		
		if outcome.has("damage"):
			# Simple chance-based damage for now
			if randf() < outcome.get("damage_chance", 1.0):
				PlayerData.current_health = max(0, PlayerData.current_health - outcome.damage)
				print("Took ", outcome.damage, " damage!")
				
		if outcome.has("item"):
			# Simple chance-based damage for now
			if randf() < outcome.get("item_chance", 1.0):
				var random_item = Inventory.get_random_item_WOblessing()
				PlayerData.add_to_inventory(random_item.id)
				print("Found ", random_item.name)
	
	queue_free()
