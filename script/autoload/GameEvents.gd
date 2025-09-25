# GameEvents.gd
# Vai trò: "Tổng đài" của game. Chỉ chứa các tín hiệu (signals) toàn cục.
extends Node

# signal cho phép một script phát ra một "thông báo" mà các script khác có thể "lắng nghe".
# Khi người chơi click vào một hero, hero đó sẽ emit tín hiệu này.
# UI sẽ kết nối với tín hiệu này để hiển thị thông tin của hero được chọn.
# (hero: Hero) định nghĩa rằng tín hiệu này sẽ gửi kèm một tham chiếu đến đối tượng hero.
@warning_ignore("unused_signal")
signal hero_selected(hero: Hero)
@warning_ignore("unused_signal")
signal hero_deselected()
@warning_ignore("unused_signal")
signal inventory_selection_changed()
@warning_ignore("unused_signal")
signal respawn_started(hero: Hero)
@warning_ignore("unused_signal")
signal respawn_finished(hero: Hero)
@warning_ignore("unused_signal")
signal hero_arrived_at_shop(hero: Hero)
@warning_ignore("unused_signal")
signal hero_arrived_at_inn(hero: Hero)
@warning_ignore("unused_signal")
signal inn_room_chosen(hero: Hero, inn_level: int)
@warning_ignore("unused_signal")
signal hero_arrived_at_crafting_station(hero: Hero, station_type: String)
@warning_ignore("unused_signal")
signal hero_arrived_at_potion_shop(hero: Hero)
@warning_ignore("unused_signal")
signal hero_arrived_at_equipment_shop(hero: Hero)
