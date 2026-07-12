extends Buff
class_name BuffHealthThreat

static func AddToActor(actor: Actor, value: int, buffOwner: Node):
	if not actor.buffs:
		return

	var node = BuffHealthThreat.new()
	node.Owner = buffOwner
	node.Intensity = value
	actor.buffs.Add(node)

static func RemoveByOwner(actor: Actor, targetOwner: Node):
	if not actor.buffs:
		return
	for child in actor.buffs.get_children():
		if child is BuffHealthThreat and child.Owner == targetOwner:
			actor.buffs.Remove(child)

static func EnsureIntensity(actor: Actor, value: int, buffOwner: Node):
	if not actor.buffs:
		return

	for child in actor.buffs.get_children():
		if child is BuffHealthThreat buff and child.Owner == buffOwner:
			buff.Intensity = value
			return
	AddToActor(actor, value, buffOwner)
