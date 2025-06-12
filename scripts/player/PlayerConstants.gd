class_name PlayerConstants

# === MOVEMENT ===
const SPEED = 160.0
const ACCELERATION = 2000.0
const FRICTION = 3200.0
const AIR_RESISTANCE = 1300.0  # Réduit pour moins de friction en l'air

# === JUMP ===
const JUMP_VELOCITY = -415.0
const JUMP_CUT_MULTIPLIER = 0.1
const MAX_FALL_SPEED = 410.0

# HORIZONTAL CONTROL
const AIR_SPEED_MULTIPLIER = 1.4      # Vitesse max en l'air (140% de la vitesse sol)
const AIR_ACCELERATION = 3500.0       # Accélération rapide en l'air
const AIR_FRICTION = 800.0            # Friction réduite pour garder l'élan
const AIR_DIRECTION_CHANGE_BOOST = 1.2 # Boost pour changer de direction rapidement

# === PHYSICS ===
const GRAVITY_MULTIPLIER = 2.5

# === WALL SLIDING ===
const WALL_SLIDE_MULTIPLIER = 0.5
const WALL_SLIDE_MAX_SPEED_MULTIPLIER = 1

# === BUFFER SETTINGS ===
const JUMP_BUFFER_TIME = 0.1
const COYOTE_TIME = 0.05

# === DASH ===
const DASH_SPEED = 800.0
const DASH_DURATION = 0.15
const DASH_COOLDOWN = 0.3
