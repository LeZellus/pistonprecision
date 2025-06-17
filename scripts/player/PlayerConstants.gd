# scripts/player/PlayerConstants.gd - AVEC WALL JUMP SETTINGS
class_name PlayerConstants

# === MOVEMENT ===
const SPEED: float        	= 160.0
const ACCELERATION: float   = 2000.0
const FRICTION: float       = 3200.0
const AIR_RESISTANCE: float = 1300.0

# === JUMP ===
const JUMP_VELOCITY: float       = -415.0
const JUMP_CUT_MULTIPLIER: float = 0.1
const MAX_FALL_SPEED: float      = 410.0

# === AIR CONTROL ===
const AIR_SPEED_MULTIPLIER: float 		= 1.4
const AIR_ACCELERATION: float           = 3500.0
const AIR_FRICTION: float               = 800.0
const AIR_DIRECTION_CHANGE_BOOST: float = 1.2

# === PHYSICS ===
const GRAVITY_MULTIPLIER: float = 2.5

# === WALL SLIDING (STYLE RITE) ===
const WALL_SLIDE_MULTIPLIER: float         = 0.4  # Plus lent, plus contrôlé
const WALL_SLIDE_MAX_SPEED_MULTIPLIER: int = 1

# === WALL JUMP (CONTRÔLE ÉQUILIBRÉ) ===
const WALL_JUMP_GRACE_TIME: float = 0.10          
const WALL_JUMP_VELOCITY: float = -415.0          
const WALL_JUMP_HORIZONTAL_FORCE: float = 3.0     # Votre valeur qui fonctionne bien
const WALL_JUMP_CONTROL_DELAY: float = 0       # TRÈS court pour récupérer le contrôle vite
const WALL_JUMP_MIN_SEPARATION: float = 20.0

# === BUFFER SETTINGS ===
const JUMP_BUFFER_TIME: float = 0.1
const COYOTE_TIME: float      = 0.05

# === DASH ===
const DASH_SPEED: float    = 800.0
const DASH_DURATION: float = 0.15
const DASH_COOLDOWN: float = 0.3
