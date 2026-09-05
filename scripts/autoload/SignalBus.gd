extends Node
## SignalBus — semua signal global game. Autoload pertama.

# --- Status game ---
signal game_state_changed(new_state: String)
signal chapter_changed(chapter_id: String)
signal location_changed(location_id: String)
signal objective_changed(text: String)
signal flag_changed(flag_name: String, value: Variant)

# --- Dialog ---
signal dialogue_started(dialogue_id: String)
signal dialogue_node_shown(node_id: String)
signal dialogue_finished(dialogue_id: String, last_node: String)
signal dialogue_choice_made(node_id: String, choice_index: int, choice_text: String)
signal memory_flashback_started(node_id: String)
signal memory_flashback_ended(node_id: String)

# --- Investigasi / inventory / jurnal ---
signal clue_found(clue_id: String)
signal item_added(item_id: String)
signal item_removed(item_id: String)
signal item_used(item_id: String, target_id: String)
signal deduction_solved(deduction_id: String)
signal hint_used(hints_left: int)
signal journal_updated
signal inventory_updated

# --- Hubungan ---
signal relationship_changed(char_id: String, old_value: int, new_value: int)

# --- UI / notifikasi ---
signal toast_requested(text: String, kind: String)
signal prompt_requested(text: String)
signal prompt_cleared
signal ui_screen_requested(screen: String)
signal loading_progress(ratio: float, label: String)

# --- Audio ---
signal music_requested(track_id: String)
signal ambient_requested(track_id: String)
signal sfx_requested(sfx_id: String)

# --- Ending ---
signal ending_triggered(ending_id: String)
