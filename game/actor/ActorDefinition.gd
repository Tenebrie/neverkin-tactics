@tool
extends Resource
class_name ActorDefinition

@export var Name: String = "Unnamed"
@export var Faction: Actor.Faction = Actor.Faction.Neutral
@export var PerceivedThreat = Actor.ThreatLevel.Concerning
@export var pronouns = Pronouns.Preset.Neutral
@export var initiative: int = 0

@export_group("Token")
@export var physicalSize: float = 0.4
@export var TokenOffset: Vector2 = Vector2.ZERO
@export var TokenTexture: Texture2D

@export_group("Avatar")
@export var AvatarTexture: Texture2D

@export_group("Resources")
@export var healthMaximum: int = 10
@export var healthHumanityThreshold: int = 0

@export var ManaMaximum: int = 0

@export var ActionPointsMax: int = 2
@export var MovementSpeedPerActionPoint: float = 5.0

@export_group("Innate Skills")
@export var Skills: Array[GDScript[Skill]] = []

@export_group("Shapeshifting")
@export var enablesShifted = false

@export_group("User Interface")
@export var showHoverInfo = true

@export_group("Sounds", "sound")
@export var soundReadyEffectStream: AudioStream
