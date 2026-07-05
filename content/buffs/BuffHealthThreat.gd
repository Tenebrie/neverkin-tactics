extends Buff
class_name BuffHealthThreat

static func AddToActor(actor: Actor, value: int, buffOwner: Node):
	if not actor.Buffs:
		return

	var node = BuffHealthThreat.new()
	node.Owner = buffOwner
	node.Intensity = value
	actor.Buffs.Add(node)

static func RemoveByOwner(actor: Actor, targetOwner: Node):
	if not actor.Buffs:
		return
	for child in actor.get_children():
		if child is BuffHealthThreat and child.Owner == targetOwner:
			actor.Buffs.Remove(child)

static func EnsureIntensity(actor: Actor, value: int, buffOwner: Node):
	if not actor.Buffs:
		return

	for child in actor.get_children():
		if child is BuffHealthThreat buff and child.Owner == buffOwner:
			buff.Intensity = value
			return
	AddToActor(actor, value, buffOwner)
