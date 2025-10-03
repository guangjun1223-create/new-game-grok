# CombatUtils.gd
extends Node

# --- CÔNG THỨC HERO TẤN CÔNG QUÁI (PHIÊN BẢN MỚI 2.0) ---
# Trả về một Dictionary chứa đầy đủ thông tin về đòn đánh
func hero_tan_cong_quai(hero_attacker: Hero, monster_defender: Node, su_dung_phep: bool, skill_damage_multiplier: float = 1.0) -> Dictionary:
	var result = {"damage": 0, "is_crit": false, "is_miss": false}

	# 1. KIỂM TRA TỶ LỆ TRÚNG (HIT vs FLEE)
	var hit_chance = 80.0 + hero_attacker.hit - monster_defender.flee
	hit_chance = clamp(hit_chance, 5.0, 95.0)
	if hero_attacker.hit >= monster_defender.flee + 20:
		hit_chance = 100.0

	if randf() * 100 > hit_chance:
		result.is_miss = true
		return result

	# 2. TÍNH SÁT THƯƠNG GỐC VÀ KIỂM TRA CHÍ MẠNG
	var base_damage = 0.0
	var is_crit = false

	# Tỷ lệ chí mạng thực tế = crit của hero - kháng crit của quái
	var real_crit_rate = hero_attacker.crit_rate - (monster_defender.LUK / 5.0 if "LUK" in monster_defender else 0)
	if not su_dung_phep and randf() * 100 < real_crit_rate:
		is_crit = true
		result.is_crit = true

	if su_dung_phep:
		base_damage = randf_range(hero_attacker.min_matk, hero_attacker.max_matk)
	else:
		if is_crit:
			# Crit luôn gây sát thương tối đa
			base_damage = hero_attacker.max_atk
		else:
			base_damage = randf_range(hero_attacker.min_atk, hero_attacker.max_atk)
			
	# Nhân sát thương với hệ số skill (giờ đã hợp lệ)
	base_damage *= skill_damage_multiplier

	# 3. ÁP DỤNG SÁT THƯƠNG CHÍ MẠNG
	if is_crit:
		base_damage *= hero_attacker.crit_damage

	# 4. TÍNH TOÁN GIẢM SÁT THƯƠNG
	var final_damage = 0.0
	if su_dung_phep:
		final_damage = base_damage - monster_defender.mdef
	else:
		final_damage = base_damage - monster_defender.def

	# Đảm bảo sát thương không bị âm
	final_damage = max(final_damage, 1.0)

	result.damage = roundi(final_damage)
	return result


# --- CÔNG THỨC QUÁI TẤN CÔNG HERO ---
func quai_tan_cong_hero(monster_attacker: Node, target_hero: Hero, su_dung_phep: bool) -> Dictionary:
	var result = {"damage": 0, "is_crit": false, "is_miss": false, "is_perfect_dodge": false}

	# 1. KIỂM TRA NÉ TRÁNH HOÀN HẢO CỦA HERO
	if not su_dung_phep and randf() * 100 < target_hero.perfect_dodge:
		result.is_miss = true
		result.is_perfect_dodge = true
		return result

	# 2. KIỂM TRA TỶ LỆ TRÚNG (HIT vs FLEE)
	var hit_chance = 80.0 + monster_attacker.hit - target_hero.flee
	hit_chance = clamp(hit_chance, 5.0, 95.0)
	if monster_attacker.hit >= target_hero.flee + 20:
		hit_chance = 100.0

	if randf() * 100 > hit_chance:
		result.is_miss = true
		return result

	# 3. TÍNH SÁT THƯƠNG GỐC VÀ KIỂM TRA CHÍ MẠNG
	var base_damage = 0.0
	if su_dung_phep:
	# Lấy sát thương phép ngẫu nhiên trong khoảng min/max của quái
		base_damage = randf_range(monster_attacker.min_matk, monster_attacker.max_matk)
	else:
	# Lấy sát thương vật lý ngẫu nhiên trong khoảng min/max của quái
		base_damage = randf_range(monster_attacker.min_atk, monster_attacker.max_atk)

	var real_crit_rate = monster_attacker.crit_rate - target_hero.crit_resist
	if not su_dung_phep and randf() * 100 < real_crit_rate:
		result.is_crit = true
		base_damage *= 1.4 # Sát thương crit của quái là 140%

	# 4. TÍNH TOÁN GIẢM SÁT THƯƠNG
	var final_damage = base_damage - target_hero.def # Giả sử quái chỉ tấn công vật lý

	final_damage = max(final_damage, 1.0)

	result.damage = roundi(final_damage)
	return result
