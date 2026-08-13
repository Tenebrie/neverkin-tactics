extends Component
class_name ChromaComponent

var chargeCount = 0

func createSnapshot() -> Variant:
	return chargeCount

func restoreSnapshot(snapshot: Variant):
	chargeCount = snapshot as int
	_updateChromaSkills()

func _parentReady():
	parent.actions.castResolved.connect(func(castSkill: Skill):
		if not castSkill.definition.keywords.has(Keyword.Chroma):
			return

		if chargeCount < castSkill.definition.ChargesMaximum:
			chargeCount += 1
		else:
			chargeCount = 0
		_updateChromaSkills()
	)

func _updateChromaSkills():
	var chromaSkills = parent.Skills.GetAllByKeyword(Keyword.Chroma)
	for skill in chromaSkills:
		skill.chargesLeft = chargeCount
