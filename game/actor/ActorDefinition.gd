@tool
extends Resource
class_name ActorDefinition

@export var Name: String = "Unnamed"
@export var TokenTexture: Texture2D
@export var AvatarTexture: Texture2D

@export var HealthMaximum: int = 3
@export var HealthHumanityThreshold: int = 0

@export var ActionPointsMax: int = 3
@export var MovementSpeedPerActionPoint: float = 2.0

@export var RenderPriority: int = 0

@export var Skills: Array[GDScript[Skill]] = []
