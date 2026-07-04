extends Buff
class_name BuffHealthThreat

@export var ThreatValue: int = 1

static func AddToActor(actor: Actor, value: int, buffOwner: Node):
	if not actor.Buffs:
		return

	var node = BuffHealthThreat.new()
	node.Owner = buffOwner
	node.ThreatValue = value
	actor.Buffs.Add(node)

static func RemoveByOwner(actor: Actor, targetOwner: Node):
	if not actor.Buffs:
		return
	for child in actor.get_children():
		if child is BuffHealthThreat and child.Owner == targetOwner:
			actor.Buffs.Remove(child)
