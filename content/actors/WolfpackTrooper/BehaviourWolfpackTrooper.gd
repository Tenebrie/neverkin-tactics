extends BehaviourTrooper

func planCombatAction() -> TurnAction:
	for rankedTarget in Ranking:
		var target = rankedTarget.Target
		if target.isDead:
			continue

		var hasLineOfSight = ActorUtils.hasLineOfSight(parent, target)
		var dist = ActorUtils.flatDistanceBetween(parent, target) - parent.physicalSize
		var cripplingShotRange = parent.Skills.Get(SkillCripplingShot).definition.TargetingMaxRange
		if target.buffs.Has(BuffWolfHowlTarget) and dist < cripplingShotRange and hasLineOfSight:
			return TurnAction.UseSkillOnActor(SkillCripplingShot, target)

		var pistolRange = parent.Skills.Get(SkillPistolShot).definition.TargetingMaxRange
		var grenadeRange = parent.Skills.Get(SkillFragGrenade).definition.TargetingMaxRange
		if dist < pistolRange and hasLineOfSight:
			return TurnAction.UseSkillOnActor(SkillPistolShot, target)
		elif dist < grenadeRange:
			return TurnAction.UseSkillOnActor(SkillFragGrenade, target)

	return TurnAction.Skip()
