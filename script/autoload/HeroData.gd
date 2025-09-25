extends Resource
class_name HeroData

enum JobClass {
	Novice, Swordsman, Mage, Archer, Thief, Acolyte, 
	Knight, Crusader, Wizard, Sage, Hunter, Sniper, 
	Assassin, Rogue, Priest, Monk, Lord_Knight, Paladin, 
	High_Wizard, Professor, Ranger, Gunslinger, 
	Assassin_Cross, Stalker, High_Priest, Champion
}

@export var rarity: String = "Common"

@export var job_class: JobClass = JobClass.Novice:
	set(value):
		job_class = value
		job_key = JobClass.keys()[job_class]

var job_key: String

@export_group("Visuals")
@export var sprite_texture: Texture2D

func _init():
	job_key = JobClass.keys()[job_class]
