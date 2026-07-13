extends ActorBuffs
class_name PropBuffs

func Add(_buff: Buff) -> void:
	return

func AddUpToMaxIntensity(_prototype: Buff, _maxIntensity: int) -> void:
	return

func Get(_buffClass: GDScript[Buff]) -> Buff:
	return null

func GetAll(_buffClass: GDScript[Buff]) -> Array[Buff]:
	return []

func listAllVisible() -> Array[Buff]:
	return []

func Has(_buffClass: GDScript[Buff]) -> int:
	return false

func Count(_buffClass: GDScript[Buff]) -> int:
	return 0

func Remove(_buff: Buff) -> void:
	pass

func RemoveAll(_buffClass: GDScript[Buff]) -> void:
	pass
