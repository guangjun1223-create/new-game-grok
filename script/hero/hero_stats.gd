# res://script/hero/HeroStats.gd
extends Node
class_name HeroStats

signal stats_updated
signal exp_changed(current_exp, exp_to_next_level)
signal free_points_changed
signal job_changed

var hero: Hero
var job_key: String = "Novice"
var job_history: Array = ["Novice"]


var level: int = 1
var current_exp: int = 0
var exp_to_next_level: int = 100
var free_points: int = 0
var bonus_aspd_flat: float = 0.0
const ATTACK_RANGE: float = 150.0
var speed: float = 150.0


var str_co_ban: float = 1.0; var str_tang_truong: float = 0.0
var agi_co_ban: float = 1.0; var agi_tang_truong: float = 0.0
var vit_co_ban: float = 1.0; var vit_tang_truong: float = 0.0
var int_co_ban: float = 1.0; var int_tang_truong: float = 0.0
var dex_co_ban: float = 1.0; var dex_tang_truong: float = 0.0
var luk_co_ban: float = 1.0; var luk_tang_truong: float = 0.0

var STR: int = 1; var AGI: int = 1; var VIT: int = 1
var INTEL: int = 1; var DEX: int = 1; var LUK: int = 1

var max_hp: float = 0.0; var max_sp: float = 0.0
var atk: float = 0.0; var matk: float = 0.0
var min_atk: float = 0.0
var max_atk: float = 0.0
var min_matk: float = 0.0
var max_matk: float = 0.0
var def: float = 0.0; var mdef: float = 0.0
var attack_time: float = 1.0
var attack_range_calculated: float = 150.0
var hit: float = 0; var flee: float = 0; var crit_rate: float = 0; var crit_damage: float = 1.5
var perfect_dodge: float = 0.0
var crit_resist: float = 0.0

var bonus_str: float = 0.0; var bonus_agi: float = 0.0; var bonus_vit: float = 0.0
var bonus_intel: float = 0.0; var bonus_dex: float = 0.0; var bonus_luk: float = 0.0
var bonus_atk: float = 0.0; var bonus_matk: float = 0.0
var bonus_max_hp: float = 0.0; var bonus_max_sp: float = 0.0
var bonus_def: float = 0.0; var bonus_mdef: float = 0.0
var bonus_hit: float = 0.0; var bonus_flee: float = 0.0
var bonus_crit_rate: float = 0.0; var bonus_crit_dame: float = 0.0
var bonus_attack_range: float = 0.0; var attack_speed_mod: float = 0.0

func _ready():
	hero = get_parent()

func initialize_stats():
	var du_lieu_nghe = GameDataManager.get_hero_definition(job_key)
	if du_lieu_nghe.is_empty(): return
	STR = int(str_co_ban) + du_lieu_nghe.get("str", 0)
	AGI = int(agi_co_ban) + du_lieu_nghe.get("agi", 0)
	VIT = int(vit_co_ban) + du_lieu_nghe.get("vit", 0)
	INTEL = int(int_co_ban) + du_lieu_nghe.get("int", 0)
	DEX = int(dex_co_ban) + du_lieu_nghe.get("dex", 0)
	LUK = int(luk_co_ban) + du_lieu_nghe.get("luk", 0)
	update_secondary_stats()

func update_secondary_stats():
	# --- SỬA LỖI: Gọi đúng tên hàm có dấu gạch dưới ---
	_reset_bonus_stats()
	hero.hero_inventory.apply_equipment_stats(self)
	hero.hero_skills.apply_passive_skill_bonuses(self)

	var total_str = STR + bonus_str
	var total_agi = AGI + bonus_agi
	var total_vit = VIT + bonus_vit
	var total_intel = INTEL + bonus_intel
	var total_dex = DEX + bonus_dex
	var total_luk = LUK + bonus_luk
	
	var weapon_data: Dictionary = hero.hero_inventory.get_current_weapon_data()
	var weapon_type: String = weapon_data.get("weapon_type", "")
		
	var base_hp = (level * 10.0) + (total_vit * 5.0)
	if weapon_type == "SWORD": base_hp += total_str * 0.5
	max_hp = base_hp * (1.0 + total_vit * 0.01) + bonus_max_hp
	
	var base_sp = (level * 5.0) + (total_intel * 3.0)
	max_sp = base_sp * (1.0 + total_intel * 0.01) + bonus_max_sp
	
	def = (total_vit / 2.0) + (total_dex / 5.0) + (level / 4.0) + bonus_def
	mdef = total_intel + (total_dex / 5.0) + (level / 4.0) + bonus_mdef
	
	hit = level + total_dex + bonus_hit
	flee = level + total_agi + bonus_flee
	
	var base_max_atk = 0.0
	match weapon_type:
		"SWORD": base_max_atk = (total_str * 1.5) + (total_dex * 0.3)
		"DAGGER": base_max_atk = (total_str * 1.0) + (total_dex * 0.2) + (total_agi * 0.2)
		"BOW": base_max_atk = (total_dex * 1.2) + (total_str * 0.3)
		"STAFF": base_max_atk = total_str * 0.5
		_: base_max_atk = total_str

	var bonus_atk_from_stats = pow(int(total_str / 10), 2) - 1 + (total_dex / 5) + (total_luk / 5)
	max_atk = base_max_atk + bonus_atk_from_stats + bonus_atk
	min_atk = max_atk * (1.0 - (total_dex / 200.0))
	
	var base_min_matk = total_intel + pow(int(total_intel / 7), 2)
	var base_max_matk = total_intel + pow(int(total_intel / 5), 2)
	if weapon_type == "STAFF":
		base_min_matk *= 1.5; base_max_matk *= 1.5
	else:
		base_min_matk = total_intel / 2.9; base_max_matk = total_intel / 2.0

	var bonus_matk_from_stats = pow(int(total_intel / 10), 2) - 1
	min_matk = base_min_matk + bonus_matk_from_stats + bonus_matk
	max_matk = base_max_matk + bonus_matk_from_stats + bonus_matk
	
	crit_rate = (total_luk * 0.3) + bonus_crit_rate
	crit_damage = 1.5 + (total_agi / 500.0) + (total_luk / 200.0) + bonus_crit_dame
	perfect_dodge = (total_luk / 10.0)
	crit_resist = (total_luk / 15.0)
	
	var weapon_penalty = weapon_data.get("aspd_penalty", 0.0)
	var shield_id = hero.hero_inventory.equipment.get("OFF_HAND")
	if typeof(shield_id) == TYPE_STRING and not shield_id.is_empty():
		weapon_penalty += ItemDatabase.get_item_data(shield_id).get("aspd_penalty", 0.0)
	
	var stat_bonus_aspd = sqrt( (total_dex*total_dex / 80.0) + (total_agi*total_agi / 32.0) )
	var aspd = round(156 + stat_bonus_aspd - weapon_penalty + bonus_aspd_flat)
	aspd = clamp(aspd, 0, 193)
	
	attack_time = 0.2
	if (200.0 - aspd) > 0:
		var attacks_per_second = 50.0 / (200.0 - aspd)
		attack_time = (1.0 / attacks_per_second)

	attack_range_calculated = ATTACK_RANGE + bonus_attack_range
	
	if is_instance_valid(hero):
		hero.current_hp = min(hero.current_hp, max_hp)
		hero.current_sp = min(hero.current_sp, max_sp)
	
	stats_updated.emit()

func _reset_bonus_stats():
	bonus_str = 0.0; bonus_agi = 0.0; bonus_vit = 0.0
	bonus_intel = 0.0; bonus_dex = 0.0; bonus_luk = 0.0
	bonus_atk = 0.0; bonus_matk = 0.0
	bonus_max_hp = 0.0; bonus_max_sp = 0.0
	bonus_def = 0.0; bonus_mdef = 0.0
	bonus_hit = 0.0; bonus_flee = 0.0
	bonus_crit_rate = 0.0; bonus_crit_dame = 0.0
	bonus_attack_range = 0.0
	bonus_aspd_flat = 0.0 # Thêm dòng này

func apply_item_stats(item_id: String):
	var item_data = ItemDatabase.get_item_data(item_id); if item_data.is_empty(): return
	var item_stats = item_data.get("stats", {}); if item_stats.is_empty(): return
	bonus_str += item_stats.get("str", 0.0); bonus_agi += item_stats.get("agi", 0.0); bonus_vit += item_stats.get("vit", 0.0)
	bonus_intel += item_stats.get("int", 0.0); bonus_dex += item_stats.get("dex", 0.0); bonus_luk += item_stats.get("luk", 0.0)
	bonus_atk += item_stats.get("atk", 0.0); bonus_matk += item_stats.get("matk", 0.0); bonus_max_hp += item_stats.get("max_hp", 0.0)
	bonus_max_sp += item_stats.get("max_sp", 0.0); bonus_def += item_stats.get("def", 0.0); bonus_mdef += item_stats.get("mdef", 0.0)
	bonus_hit += item_stats.get("hit", 0.0); bonus_flee += item_stats.get("flee", 0.0); bonus_crit_rate += item_stats.get("crit_rate", 0.0)
	bonus_crit_dame += item_stats.get("crit_dame", 0.0); bonus_attack_range += item_stats.get("attack_range_bonus", 0.0)
	bonus_aspd_flat += item_stats.get("bonus_aspd_flat", 0.0)

func gain_exp(amount: int):
	if hero.is_dead or (job_key == "Novice" and level >= 10) or level >= 100: return
	current_exp += amount
	var text_position = hero.global_position - Vector2(0, 150)
	FloatingTextManager.show_text("+" + str(amount) + " EXP", Color.YELLOW, text_position)
	_check_level_up()

func _check_level_up():
	var has_leveled_up = false
	while current_exp >= exp_to_next_level and level < 100:
		has_leveled_up = true
		current_exp -= exp_to_next_level
		level += 1
		free_points += 5
		exp_to_next_level = int(100 * pow(level, 1.5))

		# hưởng cho hero 1 điểm kỹ năng mỗi khi lên cấp [cite: 43]
		if is_instance_valid(hero) and hero.has_node("HeroSkills"):
			hero.hero_skills.skill_points += 1

		# Cộng chỉ số tăng trưởng theo nghề 
		STR += roundi(str_tang_truong); AGI += roundi(agi_tang_truong)
		VIT += roundi(vit_tang_truong)
		INTEL += roundi(int_tang_truong); DEX += roundi(dex_tang_truong); LUK += roundi(luk_tang_truong)
		
	if has_leveled_up:
		hero.heal_to_full()
		free_points_changed.emit()
		
		# Báo cho UI biết rằng số điểm kỹ năng đã thay đổi để cập nhật hiển thị 
		if is_instance_valid(hero) and hero.has_node("HeroSkills"):
			hero.hero_skills.skill_tree_changed.emit()

	exp_changed.emit(current_exp, exp_to_next_level)
	update_secondary_stats()

func nang_cap_chi_so(stat_name: String):
	if free_points <= 0: 
		return
	free_points -= 1
	match stat_name:
		"str": STR += 1
		"agi": AGI += 1
		"vit": VIT += 1
		"int": INTEL += 1
		"dex": DEX += 1
		"luk": LUK += 1
	free_points_changed.emit(); update_secondary_stats()
	PlayerStats.save_game()

func change_job(new_job_key: String):
	var new_job_data = GameDataManager.get_hero_definition(new_job_key); if new_job_data.is_empty(): return
	job_key = new_job_key
	job_history.append(new_job_key)
	str_tang_truong = new_job_data.get("str_growth", 0.0);
	agi_tang_truong = new_job_data.get("agi_growth", 0.0)
	vit_tang_truong = new_job_data.get("vit_growth", 0.0); int_tang_truong = new_job_data.get("int_growth", 0.0)
	dex_tang_truong = new_job_data.get("dex_growth", 0.0); luk_tang_truong = new_job_data.get("luk_growth", 0.0)
	level = 1;
	current_exp = 0; exp_to_next_level = int(100 * pow(level, 1.5))
	initialize_stats(); hero.heal_to_full();
	job_changed.emit()
	exp_changed.emit(current_exp, exp_to_next_level)

	# TỰ ĐỘNG THÁO TRANG BỊ KHÔNG PHÙ HỢP
	hero.hero_inventory.unequip_invalid_items_after_job_change()

	# === THÊM DÒNG NÀY VÀO CUỐI HÀM ===
	PlayerStats.save_game()


func save_data() -> Dictionary:
	return { "level": level, "current_exp": current_exp, "exp_to_next_level": exp_to_next_level, "free_points": free_points,
		"job_key": job_key, "job_history": job_history, "str_co_ban": str_co_ban, "agi_co_ban": agi_co_ban, "vit_co_ban": vit_co_ban,
		"int_co_ban": int_co_ban, "dex_co_ban": dex_co_ban, "luk_co_ban": luk_co_ban,
		"str_tang_truong": str_tang_truong, "agi_tang_truong": agi_tang_truong, "vit_tang_truong": vit_tang_truong,
		"int_tang_truong": int_tang_truong, "dex_tang_truong": dex_tang_truong, "luk_tang_truong": luk_tang_truong,
		"STR": STR, "AGI": AGI, "VIT": VIT, "INTEL": INTEL, "DEX": DEX, "LUK": LUK }

func load_data(data: Dictionary):
	if data.is_empty(): return
	level = data.get("level", 1); current_exp = data.get("current_exp", 0)
	exp_to_next_level = data.get("exp_to_next_level", 100); free_points = data.get("free_points", 0)
	job_key = data.get("job_key", "Novice"); job_history = data.get("job_history", ["Novice"])
	str_co_ban = data.get("str_co_ban", 1.0)
	agi_co_ban = data.get("agi_co_ban", 1.0); vit_co_ban = data.get("vit_co_ban", 1.0)
	int_co_ban = data.get("int_co_ban", 1.0); dex_co_ban = data.get("dex_co_ban", 1.0)
	luk_co_ban = data.get("luk_co_ban", 1.0); str_tang_truong = data.get("str_tang_truong", 0.0)
	agi_tang_truong = data.get("agi_tang_truong", 0.0); vit_tang_truong = data.get("vit_tang_truong", 0.0)
	int_tang_truong = data.get("int_tang_truong", 0.0); dex_tang_truong = data.get("dex_tang_truong", 0.0)
	luk_tang_truong = data.get("luk_tang_truong", 0.0); STR = data.get("STR", 1); AGI = data.get("AGI", 1)
	VIT = data.get("VIT", 1); INTEL = data.get("INTEL", 1); DEX = data.get("DEX", 1); LUK = data.get("LUK", 1)
	update_secondary_stats()
