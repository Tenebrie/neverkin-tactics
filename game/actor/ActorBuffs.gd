extends Component
class_name ActorBuffs

signal Changed()

func Add(buff: Buff) -> void:
	if buff.definition and buff.definition.stackType == Buff.StackType.None:
		RemoveAll(buff.get_script())
	add_child(buff)
	if buff.definition and buff.definition.stackType == Buff.StackType.StacksDuration:
		_combineDurations(buff)
	elif buff.definition and buff.definition.stackType == Buff.StackType.StacksIntensity:
		_combineIntensity(buff)
	Changed.emit()

func AddUpToMaxIntensity(prototype: Buff, maxIntensity: int) -> void:
	var script = prototype.get_script() as GDScript[Buff]
	if Count(script) < maxIntensity:
		Add(prototype)
		return
	var existing = Get(script)
	var prototypeDuration: int = SimulateInstance(prototype, func(buff):
		return buff.Duration
	)
	existing.Duration = maxi(prototypeDuration, existing.Duration)

func _combineDurations(prototype: Buff):
	var allBuffs = GetAll(prototype.get_script())
	if allBuffs.size() == 1:
		return

	var base = allBuffs[0]
	for buff in allBuffs.slice(1):
		base.Duration += buff.Duration
		buff.queue_free()
		remove_child(buff)

func _combineIntensity(prototype: Buff):
	var allBuffs = GetAll(prototype.get_script())
	if allBuffs.size() == 1:
		return

	var base = allBuffs[0]
	var totalIntensity = base.Intensity
	var longestDuration = base.Duration
	for buff in allBuffs.slice(1):
		totalIntensity += buff.Intensity
		longestDuration = max(longestDuration, buff.Duration)
		buff.queue_free()
		remove_child(buff)
	base.Intensity = totalIntensity
	base.Duration = longestDuration

func Get(buffClass: GDScript[Buff]) -> Buff:
	for child in get_children():
		if child is Buff buff and Utils.IsNodeDescendantOf(child, buffClass) and not child.is_queued_for_deletion():
			return child
	return null

func GetAll(buffClass: GDScript[Buff]) -> Array[Buff]:
	var out: Array[Buff]
	for child in get_children():
		if child is Buff buff and Utils.IsNodeDescendantOf(child, buffClass) and not child.is_queued_for_deletion():
			out.push_back(buff)
	return out

func listAllVisible() -> Array[Buff]:
	var buffs: Array[Buff]
	for child in get_children():
		if child is not Buff buff:
			continue
		if buff.definition:
			buffs.push_back(child)
	return buffs

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

func Simulate(buffScript: GDScript[Buff], cb: func(buff: Buff) -> Variant) -> Variant:
	return SimulateInstance(buffScript.new(), cb)

func SimulateInstance(buff: Buff, cb: func(buff: Buff) -> Variant) -> Variant:
	set_block_signals(true)
	add_child(buff)
	var response: Variant = cb.call(buff)
	remove_child(buff)
	buff.queue_free()
	set_block_signals(false)
	return response

func Remove(buff: Buff) -> void:
	buff.queue_free()
	remove_child(buff)
	Changed.emit()

func RemoveAll(buffClass: GDScript[Buff]) -> void:
	for child in get_children():
		if child is Buff buff and Utils.IsNodeDescendantOf(child, buffClass) and not child.is_queued_for_deletion():
			Remove(buff)
