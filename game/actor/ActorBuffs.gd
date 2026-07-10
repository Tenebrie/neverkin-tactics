extends Component
class_name ActorBuffs

signal Changed()

func listAllVisible() -> Array[Buff]:
	var buffs: Array[Buff]
	for child in get_children():
		if child is not Buff buff:
			continue
		if buff.definition:
			buffs.push_back(child)
	return buffs

func Add(buff: Buff) -> void:
	add_child(buff)
	Changed.emit()
	if buff is not BuffHealthThreat:
		MessageLog.PrintChatMessage("%s has received buff %s"%[Parent.Definition.Name, buff.get_script().get_global_name()])

func Get(buffClass: GDScript[Buff]) -> Buff:
	for child in get_children():
		if child is Buff buff and Utils.IsNodeDescendantOf(child, buffClass) and not child.is_queued_for_deletion():
			return child
	return null

func Has(buffClass: GDScript[Buff]) -> int:
	for child in get_children():
		if child is Buff buff and Utils.IsNodeDescendantOf(child, buffClass) and not child.is_queued_for_deletion():
			return true
	return false

func Count(buffClass: GDScript[Buff]) -> int:
	var total = 0
	for child in get_children():
		if child is Buff buff and Utils.IsNodeDescendantOf(child, buffClass) and not child.is_queued_for_deletion():
			total += buff.Intensity
	return total

func Remove(buff: Buff) -> void:
	buff.queue_free()
	remove_child(buff)
	Changed.emit()
	if buff is not BuffHealthThreat:
		MessageLog.PrintChatMessage("%s has lost buff %s"%[Parent.Definition.Name, buff])
