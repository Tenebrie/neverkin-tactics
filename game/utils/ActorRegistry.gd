class_name ActorRegistry

var List: Array[Actor] = []

func Register(actor: Actor):
	var index = List.find(actor)
	if index > 0:
		return
	List.push_back(actor)

func Unregister(actor: Actor):
	var index = List.find(actor)
	if index < 0:
		return
	List.remove_at(index)
