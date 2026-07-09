extends Skill
class_name SkillWolfHowl

func _ready() -> void:
	Definition = preload("./SkillWolfHowl.tres").duplicate()
	Definition.Telegraphs = [
		TelegraphPreset.MaxCastRange.new(),
		TelegraphPreset.SingleActor.new()
	]
	super._ready()

func Cast(targets: Skill.TargetData) -> void:
	var target = targets.actor
	target.Buffs.Add(BuffWolfHowlTarget.new())

	var damageInstance = DamageInstance.ForAggroGeneration(self, 10)
	for ally in BehaviourUtils.findAllies(Parent):
		if ally.Behaviour is not ActorBehaviourWorldControlled allyBehaviour:
			continue
		allyBehaviour.RecordGrudge(damageInstance, target)
