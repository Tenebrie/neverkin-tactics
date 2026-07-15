extends BehaviourTrooper

func tryAttack(target: Actor) -> TurnAction:
	if target and not target.isDead and target.buffs.Has(BuffWolfHowlTarget):
		var dist = ActorUtils.flatDistanceBetweenActors(parent, target)
		var cripplingShotRange = parent.Skills.Get(SkillCripplingShot).definition.TargetingMaxRange
		if dist < cripplingShotRange and ActorUtils.hasLineOfSight(parent, target):
			return TurnAction.UseSkillOnActor(SkillCripplingShot, target)

	return super.tryAttack(target)
