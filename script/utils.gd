# res://script/utils.gd (hoặc bất kỳ đường dẫn nào bạn muốn lưu)
extends Node

# Hàm định dạng số, thêm dấu phẩy ngăn cách hàng nghìn
func format_number(number) -> String:
	var s = str(number)
	var result = ""
	var count = 0
	for i in range(s.length() - 1, -1, -1):
		result = s[i] + result
		count += 1
		if count % 3 == 0 and i > 0:
			result = "," + result
	return result
