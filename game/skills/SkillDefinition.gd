@tool
extends Resource
class_name SkillDefinition

@export var Name: String = "Unnamed"
@export_multiline var Description: String
@export var IconTexture: Texture2D
@export var ActionPointCost: int = 1
@export var MovementRequired: float = 0.0

@export var Hotkey: InputEventKey

@export_group("Skill Targeting", "Targeting")
@export var TargetingMaxRange: float = 1.0
@export var TargetingResolvesNextTurn: bool = false

@export_group("Shapeshifting", "Shapeshift")
@export var ShapeshiftTargetActor: ActorDefinition

@export_group("NPC Behaviour", "Behaviour")
@export var BehaviourRequireLineOfSight = true
@export var BehaviourTargetsGround = false

var Telegraphs: Array[TelegraphDefinition]
