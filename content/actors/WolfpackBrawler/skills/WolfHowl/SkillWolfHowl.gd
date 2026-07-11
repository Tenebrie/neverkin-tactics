extends Skill
class_name SkillWolfHowl

func _ready() -> void:
	definition = preload("./SkillWolfHowl.tres").duplicate()
	definition.telegraphs = [
		TelegraphPreset.MaxCastRange.new(),
		TelegraphPreset.SingleActor.new()
	]
	super._ready()

func _cast(targets: Skill.TargetData) -> void:
	var target = targets.actor
	target.Buffs.Add(BuffWolfHowlTarget.new())

	var damageInstance = DamageInstance.ForAggroGeneration(self, 10)
	for ally in BehaviourUtils.findAllies(parent):
		if ally.Behaviour is not ActorBehaviourWorldControlled allyBehaviour:
			continue
		allyBehaviour.RecordGrudge(damageInstance, target)
