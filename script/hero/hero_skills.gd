# res://script/hero/HeroSkills.gd
extends Node
class_name HeroSkills

signal skill_tree_changed
signal skill_activated(skill_id, cooldown_duration)

var hero: Hero

const MAX_SKILL_SLOTS = 4
var skill_points: int = 0
var learned_skills: Dictionary = {}
var equipped_skills: Array = []
var _skill_cooldowns: Dictionary = {}

func _ready():
	await owner.ready
	
	hero = owner
	
	hero.hero_stats.job_changed.connect(func(): 
		skill_points = 0
		skill_tree_changed.emit()
	)
	
	equipped_skills.resize(MAX_SKILL_SLOTS)
	equipped_skills.fill(null)

func get_skill_level(skill_id: String) -> int: return learned_skills.get(skill_id, 0)

func learn_or_upgrade_skill(skill_id: String):
	var skill_data = SkillDatabase.get_skill_data(skill_id); if skill_data.is_empty(): return
	var current_level = get_skill_level(skill_id)
	var max_level = skill_data.get("max_level", 1); if current_level >= max_level: return
	var cost_array = skill_data.get("skill_point_cost", []); if current_level >= cost_array.size(): return
	var cost = cost_array[current_level]
	if skill_points >= cost:
		skill_points -= cost; learned_skills[skill_id] = current_level + 1
		if skill_data.get("usage_type") == "PASSIVE": hero.hero_stats.update_secondary_stats()
		skill_tree_changed.emit()
		PlayerStats.save_game()

func is_skill_equipped(skill_id: String) -> bool: return skill_id in equipped_skills

func equip_skill(skill_id: String):
	if is_skill_equipped(skill_id): return
	var empty_slot = equipped_skills.find(null)
	if empty_slot != -1: equipped_skills[empty_slot] = skill_id; skill_tree_changed.emit()
	PlayerStats.save_game()

func unequip_skill(skill_id: String):
	var slot = equipped_skills.find(skill_id)
	if slot != -1: equipped_skills[slot] = null; skill_tree_changed.emit()
	PlayerStats.save_game()

func update_cooldowns(delta: float):
	for skill_id in _skill_cooldowns:
		if _skill_cooldowns[skill_id] > 0: _skill_cooldowns[skill_id] -= delta

func get_ready_skill_to_activate() -> String:
	# Nếu không có mục tiêu thì không dùng skill
	if not is_instance_valid(hero.target_monster): return ""

	var usable_skills: Array = []
	for skill_id in equipped_skills:
		if skill_id != null:
			var data = SkillDatabase.get_skill_data(skill_id)
			var level = get_skill_level(skill_id)
			if level == 0: continue # Bỏ qua nếu skill chưa học

			# --- KIỂM TRA CÁC ĐIỀU KIỆN ---
			var sp_cost = data.get("sp_cost_per_level", [])[level - 1]
			var on_cooldown = _skill_cooldowns.get(skill_id, 0.0) > 0
			var in_range = true # Mặc định là trong tầm
			if data.has("max_range"):
				var distance = hero.global_position.distance_to(hero.target_monster.global_position)
				in_range = distance <= data.get("max_range")
			
			# Nếu skill thỏa mãn mọi điều kiện: hết cooldown, đủ SP, trong tầm đánh
			if not on_cooldown and hero.current_sp >= sp_cost and in_range:
				usable_skills.append(skill_id)

	# Nếu có danh sách skill có thể dùng, chọn ngẫu nhiên một skill và trả về ID
	if not usable_skills.is_empty():
		return usable_skills.pick_random()
	
	# Nếu không có skill nào, trả về chuỗi rỗng
	return ""

func _activate_skill(skill_id: String):
	var data = SkillDatabase.get_skill_data(skill_id); var level = get_skill_level(skill_id)
	if data.is_empty() or level == 0: return
	var sp_cost = data.get("sp_cost_per_level", [])[level - 1]
	if hero.current_sp < sp_cost: return
	hero.current_sp -= sp_cost
	var cooldown = data.get("cooldown", 5.0); _skill_cooldowns[skill_id] = cooldown
	skill_activated.emit(skill_id, cooldown)
	var effects = data.get("effects_per_level")[level - 1]
	match skill_id:
		"NOV_SWORD_BOOM":
			hero._spawn_vfx("sword_boom", -60.0, Vector2(2,2)) # Gọi hàm của hero
			var multiplier = effects.get("damage_multiplier", 1.0)
			hero.execute_attack_on(hero.target_monster, false, multiplier)
		"NOV_FIRE_BOLT":
			hero._shoot_projectile(hero.magic_ball, true)

func apply_passive_skill_bonuses(stats_component: HeroStats):
	for skill_id in learned_skills:
		var level = learned_skills[skill_id]
		var data = SkillDatabase.get_skill_data(skill_id)
		if data.get("usage_type") == "PASSIVE":
			var effects = data.get("effects_per_level", [])[level - 1]
			stats_component.bonus_max_hp += effects.get("bonus_max_hp", 0.0)
			stats_component.bonus_flee += effects.get("bonus_flee", 0.0)

func check_skill_requirements(skill_id: String) -> Dictionary:
	var result = {"can_equip": true, "reason": ""}
	var data = SkillDatabase.get_skill_data(skill_id)
	if data.is_empty(): result.can_equip = false; result.reason = "Skill không hợp lệ."; return result
	if data.has("required_weapon_type"):
		var required = data["required_weapon_type"]
		var current = hero.hero_inventory.get_current_weapon_type()
		if required != current:
			result.can_equip = false; result.reason = "Cần: " + required; return result
	return result

func save_data() -> Dictionary:
	return { "skill_points": skill_points, "learned_skills": learned_skills, "equipped_skills": equipped_skills }

func load_data(data: Dictionary):
	if data.is_empty(): return
	skill_points = data.get("skill_points", 0)
	learned_skills = data.get("learned_skills", {}).duplicate(true)
	equipped_skills = data.get("equipped_skills", []).duplicate(true)
	
	if equipped_skills.size() < MAX_SKILL_SLOTS:
		equipped_skills.resize(MAX_SKILL_SLOTS)
