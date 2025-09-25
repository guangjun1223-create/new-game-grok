# CombatUtils.gd
extends Node

# --- CÔNG THỨC HERO TẤN CÔNG QUÁI (PHIÊN BẢN MỚI 2.0) ---
# Trả về một Dictionary chứa đầy đủ thông tin về đòn đánh
func hero_tan_cong_quai(
	atk_hero: float,
	matk_hero: float,
	dex_hero: float,
	crit_rate_hero: float,
	_hit_hero: float, # Không còn dùng nhưng giữ lại để tương thích
	cap_do_hero: int,
	def_quai: float,
	mdef_quai: float,
	_giap_quai: float,
	cap_do_quai: int,
	su_dung_phep: bool
) -> Dictionary:

	# Chuẩn bị sẵn một "báo cáo" kết quả
	var result = {
		"damage": 0,
		"is_crit": false,
		"is_miss": false
	}

	# 1. LOGIC TÍNH TỈ LỆ TRÚNG MỚI
	var ti_le_trung_cuoi_cung: float = 90.0
	var chenh_lech_cap_do = cap_do_quai - cap_do_hero
	if chenh_lech_cap_do > 0:
		ti_le_trung_cuoi_cung -= chenh_lech_cap_do
	ti_le_trung_cuoi_cung = clamp(ti_le_trung_cuoi_cung, 5.0, 90.0)

	if randf() * 100 > ti_le_trung_cuoi_cung:
		print("HERO TAN CONG: MISS! (Cơ hội trúng: %.1f%%)" % ti_le_trung_cuoi_cung)
		result.is_miss = true
		return result # Trả về báo cáo -> Đánh trượt

	# 2. TÍNH SÁT THƯƠNG CƠ BẢN (giữ nguyên)
	var bien_do = clamp(1.0 - (dex_hero / 100.0), 0.05, 0.3)
	var dame_raw: float
	if su_dung_phep:
		var min_dame = matk_hero * (1.0 - bien_do)
		var max_dame = matk_hero * (1.0 + (dex_hero / 100.0))
		dame_raw = randf_range(min_dame, max_dame)
		var tile_giam = clamp(mdef_quai / (mdef_quai + 100.0), 0.0, 0.8)
		dame_raw *= (1.0 - tile_giam)
	else:
		var min_dame = atk_hero * (1.0 - bien_do)
		var max_dame = atk_hero * (1.0 + (dex_hero / 100.0))
		dame_raw = randf_range(min_dame, max_dame)
		var tile_giam = clamp(def_quai / (def_quai + 100.0), 0.0, 0.8)
		dame_raw *= (1.0 - tile_giam)

	# 3. LOGIC TÍNH TỈ LỆ CHÍ MẠNG MỚI
	var ti_le_chi_mang_cuoi_cung = crit_rate_hero
	if chenh_lech_cap_do > 0:
		ti_le_chi_mang_cuoi_cung -= chenh_lech_cap_do
	ti_le_chi_mang_cuoi_cung = clamp(ti_le_chi_mang_cuoi_cung, 0.0, 100.0)

	if randf() * 100 < ti_le_chi_mang_cuoi_cung:
		dame_raw *= 1.5
		result.is_crit = true # Ghi nhận vào báo cáo -> Đây là đòn CRIT
		print("HERO TAN CONG: CRITICAL HIT! (Cơ hội crit: %.1f%%)" % ti_le_chi_mang_cuoi_cung)

	# 4. TRẢ VỀ KẾT QUẢ CUỐI CÙNG
	var final_damage_int = int(round(dame_raw))
	result.damage = final_damage_int # Ghi nhận sát thương vào báo cáo
	print("HERO TAN CONG: Gây ra %d sát thương." % final_damage_int)
	return result


# --- CÔNG THỨC QUÁI TẤN CÔNG HERO (PHIÊN BẢN MỚI 2.0) ---
func quai_tan_cong_hero(
	atk_quai: float,
	matk_quai: float,
	hit_quai: float,
	crit_quai: float,
	cap_do_quai: int,
	def_hero: float,
	mdef_hero: float,
	flee_hero: float,
	cap_do_hero: int,
	su_dung_phep: bool
) -> Dictionary:

	var result = {
		"damage": 0,
		"is_crit": false,
		"is_miss": false
	}

	# 1. TÍNH TỈ LỆ TRÚNG (công thức gốc)
	var hit_chance = clamp(hit_quai - flee_hero + (cap_do_quai - cap_do_hero) * 0.5, 20, 100)
	if randf() * 100 > hit_chance:
		print("QUAI TAN CONG: MISS!")
		result.is_miss = true
		return result

	# 2. TÍNH SÁT THƯƠNG
	var tile_giam: float
	var dame_base: float
	var def_min_hero = def_hero * 0.9
	var def_max_hero = def_hero * 1.1
	var mdef_min_hero = mdef_hero * 0.9
	var mdef_max_hero = mdef_hero * 1.1

	if su_dung_phep:
		dame_base = matk_quai
		var mdef_random = randf_range(mdef_min_hero, mdef_max_hero)
		tile_giam = clamp(mdef_random / (mdef_random + 100.0), 0.0, 0.8)
	else:
		dame_base = atk_quai
		var def_random = randf_range(def_min_hero, def_max_hero)
		tile_giam = clamp(def_random / (def_random + 100.0), 0.0, 0.8)
	var dame_final = dame_base * (1.0 - tile_giam)

	# 3. KIỂM TRA CHÍ MẠNG
	if randf() * 100 < crit_quai:
		dame_final *= 1.5
		result.is_crit = true
		print("QUAI TAN CONG: CRITICAL HIT!")

	# 4. TRẢ VỀ KẾT QUẢ
	var final_damage_int = int(round(dame_final))
	result.damage = final_damage_int
	print("QUAI TAN CONG: Gây ra %d sát thương." % final_damage_int)
	return result
