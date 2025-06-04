class_name PlayerConstants

# === MOVEMENT ===
const SPEED = 150.0
const ACCELERATION = 1000.0
const FRICTION = 2000.0
const AIR_RESISTANCE = 800.0  # Beaucoup plus de résistance en l'air

# === JUMP ===
const JUMP_VELOCITY = -322.0  # Hauteur originale restaurée
const JUMP_CUT_MULTIPLIER = 0.15  # Plus agressif pour couper le saut
const MAX_FALL_SPEED = 320.0  # Réduit pour éviter la sensation de lourdeur

# === PHYSICS ===
const GRAVITY_MULTIPLIER = 2.2  # Encore plus de gravité pour descendre vite

# === WALL SLIDING ===
const WALL_SLIDE_MULTIPLIER = 0.1
const WALL_SLIDE_MAX_SPEED_MULTIPLIER = 1
