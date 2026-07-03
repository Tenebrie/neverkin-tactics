class_name CollisionLayer

const BASE        = 1 <<  0  # Base layer
const ACTOR       = 1 <<  1  # Layer 2 - Actor
const LOW_COVER   = 1 <<  8  # Layer 9 - Low Cover
const HIGH_COVER  = 1 <<  9  # Layer 10 - High Cover
const FULL_COVER  = 1 << 10  # Layer 11 - Full Cover

const SKILL_TARGETABLE = ACTOR | LOW_COVER | HIGH_COVER | FULL_COVER
