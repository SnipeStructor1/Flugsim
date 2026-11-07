extends RefCounted

# SI units, +Y up, aircraft forward is local -Z. This is an intentionally simple
# fixed-wing model, not a certified aerodynamic model or real aircraft data.
const MASS_KG := 1200.0
const WING_AREA_M2 := 16.0
const AIR_DENSITY := 1.225
const GRAVITY := 9.80665
const MAX_THRUST_N := 3000.0

var position := Vector3.ZERO
var velocity := Vector3(0, 0, -55)
var attitude := Quaternion.IDENTITY
var angular_rates := Vector3.ZERO
var throttle := 0.65
var stalled := false

func lift_coefficient(alpha: float) -> float:
	var degrees := absf(rad_to_deg(alpha))
	var linear := clampf(0.24 + 4.2 * alpha, -1.2, 1.45)
	if degrees <= 15.0:
		return linear
	# Lift falls beyond the critical angle; residual lift remains at deep stall.
	return lerpf(linear, signf(alpha) * 0.35, clampf((degrees - 15.0) / 20.0, 0.0, 1.0))

func step(dt: float, pitch: float, roll: float, yaw: float, throttle_delta: float, wind: Vector3 = Vector3.ZERO) -> void:
	if not is_finite(dt) or dt <= 0.0 or dt > 0.1:
		return
	throttle = clampf(throttle + clampf(throttle_delta, -1.0, 1.0) * dt * 0.35, 0.0, 1.0)
	var targets := Vector3(clampf(pitch,-1,1) * 0.45, -clampf(yaw,-1,1) * 0.30, clampf(roll,-1,1) * 0.70)
	angular_rates = angular_rates.lerp(targets, 1.0 - exp(-2.5 * dt))
	var rotation := Quaternion(Vector3.RIGHT, angular_rates.x * dt) * Quaternion(Vector3.UP, angular_rates.y * dt) * Quaternion(Vector3.FORWARD, angular_rates.z * dt)
	attitude = (attitude * rotation).normalized()
	var orientation := Basis(attitude)
	var air_velocity := velocity - wind
	var airspeed := air_velocity.length()
	var force := Vector3.DOWN * MASS_KG * GRAVITY + (-orientation.z) * (throttle * MAX_THRUST_N)
	stalled = false
	if airspeed > 0.5:
		var local := orientation.inverse() * air_velocity
		var alpha := atan2(-local.y, maxf(-local.z, 0.1))
		stalled = absf(rad_to_deg(alpha)) > 15.0
		var coefficient := lift_coefficient(alpha)
		var flow := air_velocity / airspeed
		var lift_direction := orientation.y - flow * orientation.y.dot(flow)
		var dynamic_pressure := 0.5 * AIR_DENSITY * airspeed * airspeed
		if lift_direction.length_squared() > 0.000001:
			force += lift_direction.normalized() * dynamic_pressure * WING_AREA_M2 * coefficient
		var drag_coefficient := 0.032 + 0.045 * coefficient * coefficient + (0.14 if stalled else 0.0)
		force -= flow * dynamic_pressure * WING_AREA_M2 * drag_coefficient
	velocity += force / MASS_KG * dt
	position += velocity * dt
