extends BehaviourTrooper

func planCombatAction() -> TurnAction:
	for rankedTarget in Ranking:
		var target = rankedTarget.Target
		if target.isDead:
			continue

		var hasLineOfSight = ActorUtils.hasLineOfSight(Parent, target)
		var dist = ActorUtils.flatDistanceBetween(Parent, target) - Parent.Definition.physicalSize
		var cripplingShotRange = Parent.Skills.Get(SkillCripplingShot).Definition.TargetingMaxRange
		if target.Buffs.Has(BuffWolfHowlTarget) and dist < cripplingShotRange and hasLineOfSight:
			return TurnAction.UseSkillOnActor(SkillCripplingShot, target)

		var pistolRange = Parent.Skills.Get(SkillPistolShot).Definition.TargetingMaxRange
		var grenadeRange = Parent.Skills.Get(SkillFragGrenade).Definition.TargetingMaxRange
		if dist < pistolRange and hasLineOfSight:
			return TurnAction.UseSkillOnActor(SkillPistolShot, target)
		elif dist < grenadeRange:
			return TurnAction.UseSkillOnActor(SkillFragGrenade, target)

	return TurnAction.Skip()
