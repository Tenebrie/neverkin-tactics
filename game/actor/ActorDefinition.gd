@tool
extends Resource
class_name ActorDefinition

@export var Name: String = "Unnamed"
@export var Faction: Actor.Faction = Actor.Faction.Neutral
@export var PerceivedThreat = Actor.ThreatLevel.Concerning
@export var pronouns = Pronouns.Preset.Neutral
@export var initiative: int = 0

@export_group("Token")
@export var PhysicalSize: float = 0.4
@export var TokenOffset: Vector2 = Vector2.ZERO
@export var TokenTexture: Texture2D

@export_group("Avatar")
@export var AvatarTexture: Texture2D

@export_group("Stats")
@export var HealthMaximum: int = 3
@export var HealthHumanityThreshold: int = 0

@export var ActionPointsMax: int = 3
@export var MovementSpeedPerActionPoint: float = 2.0

@export_group("Innate Skills")
@export var Skills: Array[GDScript[Skill]] = []
