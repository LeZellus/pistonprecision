class_name PlayerConstants

# === MOVEMENT ===
const SPEED: float        	= 160.0
const ACCELERATION: float   = 2000.0
const FRICTION: float       = 3200.0
const AIR_RESISTANCE: float = 1300.0 # Réduit pour moins de friction en l'air

# === JUMP ===
const JUMP_VELOCITY: float       = -415.0
const JUMP_CUT_MULTIPLIER: float = 0.1
const MAX_FALL_SPEED: float      = 410.0

# HORIZONTAL CONTROL
const AIR_SPEED_MULTIPLIER: float 		= 1.4 # Vitesse max en l'air (140% de la vitesse sol)
const AIR_ACCELERATION: float           = 3500.0 # Accélération rapide en l'air
const AIR_FRICTION: float               = 800.0 # Friction réduite pour garder l'élan
const AIR_DIRECTION_CHANGE_BOOST: float = 1.2 # Boost pour changer de direction rapidement

# === PHYSICS ===
const GRAVITY_MULTIPLIER: float = 2.5

# === WALL SLIDING ===
const WALL_SLIDE_MULTIPLIER: float         = 0.5
const WALL_SLIDE_MAX_SPEED_MULTIPLIER: int = 1

# === BUFFER SETTINGS ===
const JUMP_BUFFER_TIME: float = 0.1
const COYOTE_TIME: float      = 0.05

# === DASH ===
const DASH_SPEED: float    = 800.0
const DASH_DURATION: float = 0.15
const DASH_COOLDOWN: float = 0.3
