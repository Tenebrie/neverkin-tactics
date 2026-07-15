extends Buff
class_name BuffActionPointPromise

static func AddToActor(actor: Actor, value: int, buffOwner: Node):
	if not actor.buffs or value == 0:
		return

	var node = BuffActionPointPromise.new()
	node.Duration = 1
	node.Owner = buffOwner
	node.Intensity = value
	actor.buffs.Add(node)

static func RemoveByOwner(actor: Actor, targetOwner: Node):
	if not actor.buffs:
		return
	for child in actor.buffs.get_children():
		if child is BuffActionPointPromise and child.Owner == targetOwner:
			actor.buffs.Remove(child)

static func EnsureIntensity(actor: Actor, value: int, buffOwner: Node):
	if not actor.buffs:
		return

	for child in actor.buffs.get_children():
		if child is BuffActionPointPromise buff and child.Owner == buffOwner:
			buff.Intensity = value
			return
	AddToActor(actor, value, buffOwner)
