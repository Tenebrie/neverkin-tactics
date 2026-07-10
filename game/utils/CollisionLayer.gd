class_name CollisionLayer

const BASE           = 1 <<  0  # Base layer
const ACTOR          = 1 <<  1  # Layer 2 - Actor
const OBSTACLE       = 1 <<  2  # Layer 3 - Obstacle
const LOW_COVER      = 1 <<  8  # Layer 9 - Low Cover
const HIGH_COVER     = 1 <<  9  # Layer 10 - High Cover
const FULL_COVER     = 1 << 10  # Layer 11 - Full Cover
const IGNORED_COVER  = 1 << 31  # Layer 32 - Ignored cover

const SKILL_TARGETABLE = ACTOR | LOW_COVER | HIGH_COVER | FULL_COVER
