extends Skill
class_name SkillHeadbutt

var dashTelegraph = TelegraphPreset.ForcePush.new(20.0)

func _prepare() -> void:
	dashTelegraph.Travel.RectLength = definition.TargetingMaxRange
	dashTelegraph.Travel.addTargetFilter(func(actor):
		return actor != parent
	)
	dashTelegraph.Travel.Attachment = Telegraph.Attachment.Caster
	dashTelegraph.Travel.addProcessor(func(tele):
		tele.position.y = -0.01
	)
	dashTelegraph.Travel.addProcessor(TelegraphProcessor.LookAtMouse)
	dashTelegraph.Travel.RectWidth = parent.physicalSize * 2
	
	dashTelegraph.Impact.addTargetFilter(func(actor):
		return actor != parent
	)
	
	definition.telegraphs = [
		dashTelegraph.Travel, 
		dashTelegraph.Impact,
	]
