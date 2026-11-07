extends RefCounted

# SI units, +Y up, aircraft forward is local -Z. This is an intentionally simple
# fighter-like model, not a validated F-22 aerodynamic or propulsion model.
const MASS_KG := 26000.0 # Assumed representative flight mass, not a fixed F-22 mass.
const WING_AREA_M2 := 78.0 # Approximate planform reference area.
const AIR_DENSITY := 1.225
const GRAVITY := 9.80665
const MAX_THRUST_N := 230000.0 # Simplified combined dry-thrust approximation.

var position := Vector3.ZERO
var velocity := Vector3(0, 0, -130)
var attitude := Quaternion.IDENTITY
var angular_rates := Vector3.ZERO
var throttle := 0.65
var stalled := false
var engine_power := 0.65
var indicated_airspeed := 0.0

# ISA troposphere, clamped to its 0–11 km domain; not a weather model.
func density_at_altitude(altitude_m: float) -> float:
	var height := clampf(altitude_m, 0.0, 11000.0)
	return AIR_DENSITY * pow(1.0 - 0.0000225577 * height, 4.25588)

func lift_coefficient(alpha: float) -> float:
	var degrees := absf(rad_to_deg(alpha))
	var linear := clampf(0.30 + 4.2 * alpha, -1.2, 1.45)
	if degrees <= 15.0:
		return linear
	# Lift falls beyond the critical angle; residual lift remains at deep stall.
	return lerpf(linear, signf(alpha) * 0.35, clampf((degrees - 15.0) / 20.0, 0.0, 1.0))

func step(dt: float, pitch: float, roll: float, yaw: float, throttle_delta: float, wind: Vector3 = Vector3.ZERO) -> void:
	if not is_finite(dt) or dt <= 0.0 or dt > 0.1:
		return
	throttle = clampf(throttle + clampf(throttle_delta, -1.0, 1.0) * dt * 0.35, 0.0, 1.0)
	var air_velocity := velocity - wind
	var airspeed := air_velocity.length()
	var density := density_at_altitude(position.y)
	indicated_airspeed = airspeed * sqrt(density / AIR_DENSITY)
	# Generic dynamic-pressure authority, not real F-22 control laws.
	var authority := clampf(indicated_airspeed / 100.0, 0.0, 1.0)
	var targets := Vector3(clampf(pitch,-1,1) * 0.45, -clampf(yaw,-1,1) * 0.30, clampf(roll,-1,1) * 0.70) * authority
	# First-order response approximates spool lag; no afterburner model.
	engine_power = lerpf(engine_power, throttle, 1.0 - exp(-dt / 1.5))
	angular_rates = angular_rates.lerp(targets, 1.0 - exp(-2.5 * dt))
	var rotation := Quaternion(Vector3.RIGHT, angular_rates.x * dt) * Quaternion(Vector3.UP, angular_rates.y * dt) * Quaternion(Vector3.FORWARD, angular_rates.z * dt)
	attitude = (attitude * rotation).normalized()
	var orientation := Basis(attitude)
	var force := Vector3.DOWN * MASS_KG * GRAVITY + (-orientation.z) * (engine_power * MAX_THRUST_N * density / AIR_DENSITY)
	stalled = false
	if airspeed > 0.5:
		var local := orientation.inverse() * air_velocity
		var alpha := atan2(-local.y, maxf(-local.z, 0.1))
		stalled = absf(rad_to_deg(alpha)) > 15.0
		var coefficient := lift_coefficient(alpha)
		var flow := air_velocity / airspeed
		var lift_direction := orientation.y - flow * orientation.y.dot(flow)
		var dynamic_pressure := 0.5 * density * airspeed * airspeed
		if lift_direction.length_squared() > 0.000001:
			force += lift_direction.normalized() * dynamic_pressure * WING_AREA_M2 * coefficient
		var drag_coefficient := 0.032 + 0.045 * coefficient * coefficient + (0.14 if stalled else 0.0)
		force -= flow * dynamic_pressure * WING_AREA_M2 * drag_coefficient
	velocity += force / MASS_KG * dt
	position += velocity * dt
