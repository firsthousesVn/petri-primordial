shader_type canvas_item;
render_mode unshaded;

uniform float field_time = 0.0;
uniform float dish_radius = 1140.0;
uniform float mesh_spacing = 28.0;
uniform float camera_zoom = 1.0;
uniform vec2 camera_position = vec2(0.0);
uniform float visual_intensity = 1.35;
uniform vec2 world_origin = vec2(0.0);
uniform vec2 world_x_axis = vec2(1.0, 0.0);
uniform vec2 world_y_axis = vec2(0.0, 1.0);

uniform vec2 well_position = vec2(0.0);
uniform float well_radius = 0.001;
uniform float well_strength = 0.0;
uniform float well_charge_bias = 0.0;

uniform float base_pulse_speed = 0.35;
uniform float base_pulse_strength = 3.2;
uniform vec2 breath_frequency_a = vec2(0.010, 0.013);
uniform vec2 breath_frequency_b = vec2(-0.007, 0.009);
uniform vec2 hum_frequency_a = vec2(0.039, -0.035);
uniform vec2 hum_frequency_b = vec2(-0.054, 0.046);
uniform vec2 hum_envelope_frequency = vec2(0.006, -0.005);
uniform vec2 breath_wave_weights = vec2(0.6, 0.4);
uniform vec2 hum_wave_weights = vec2(0.55, 0.45);
uniform vec2 hum_envelope_shape = vec2(0.66, 0.34);
uniform float hum_height_scale = 0.24;
uniform float hum_charge_scale = 0.045;
uniform float hum_turbulence_scale = 0.04;
uniform float breath_gradient_scale = 4.2;
uniform float flow_strength_scale = 0.085;
uniform float flow_hum_scale = 0.62;
uniform float flow_vorticity_scale = 0.42;
uniform float wall_wave_reach_ratio = 0.34;
uniform float wall_wave_frequency = 0.036;
uniform float wall_wave_speed = 1.26;
uniform float wall_wave_sharpness = 2.7;
uniform float wall_wave_height_strength = 1.05;
uniform float wall_wave_push_strength = 0.64;
uniform float wall_wave_swirl_strength = 0.12;
uniform float wall_wave_swirl_speed = 0.34;
uniform int coil_torsion_count = 0;
uniform vec4 coil_torsion_a[16];
uniform vec4 coil_torsion_b[16];
uniform vec4 coil_torsion_c[16];

varying vec2 v_world_pos;

const int MAX_COIL_TORSIONS = 16;

const vec3 DISH_FILL = vec3(0.003, 0.004, 0.008);
const vec3 PALETTE_DEEP = vec3(0.008, 0.014, 0.032);
const vec3 PALETTE_INDIGO = vec3(0.032, 0.110, 0.330);
const vec3 PALETTE_BLUE = vec3(0.040, 0.260, 0.620);
const vec3 PALETTE_CYAN = vec3(0.120, 0.760, 0.960);
const vec3 PALETTE_MAGENTA = vec3(0.620, 0.180, 0.500);
const vec3 PALETTE_ROSE = vec3(0.760, 0.260, 0.560);
const vec3 PALETTE_AMBER = vec3(0.950, 0.620, 0.180);

const vec3 WALL_OUTER_BAND = vec3(0.010, 0.012, 0.016);
const vec3 WALL_MID_BAND = vec3(0.020, 0.024, 0.030);
const vec3 WALL_INNER_BAND = vec3(0.038, 0.046, 0.054);
const vec3 WALL_BEVEL = vec3(0.090, 0.112, 0.140);
const vec3 WALL_OCCLUSION = vec3(0.006, 0.010, 0.016);
const vec3 WALL_MENISCUS = vec3(0.08, 0.14, 0.22);


void vertex() {
	v_world_pos = world_origin + world_x_axis * VERTEX.x + world_y_axis * VERTEX.y;
}


float smoothstep01(float value) {
	float t = clamp(value, 0.0, 1.0);
	return t * t * (3.0 - 2.0 * t);
}


float smoothstep_derivative01(float value) {
	float t = clamp(value, 0.0, 1.0);
	return 6.0 * t * (1.0 - t);
}


vec2 clamp_to_dish(vec2 point) {
	float distance_sq = dot(point, point);
	float radius_sq = dish_radius * dish_radius;
	if (distance_sq <= radius_sq || distance_sq <= 0.000001) {
		return point;
	}

	return normalize(point) * dish_radius;
}


vec2 safe_normalize(vec2 vector_value) {
	float length_sq = dot(vector_value, vector_value);
	if (length_sq <= 0.000001) {
		return vec2(0.0);
	}
	return vector_value / sqrt(length_sq);
}


vec2 safe_inward(vec2 point) {
	float length_sq = dot(point, point);
	if (length_sq <= 0.000001) {
		return vec2(0.0);
	}
	return -point / sqrt(length_sq);
}


float substrate_hum(vec2 point) {
	float hum_phase_a = dot(point, hum_frequency_a) - field_time * (base_pulse_speed * 3.8 + 0.72);
	float hum_phase_b = dot(point, hum_frequency_b) + field_time * (base_pulse_speed * 4.4 + 1.06);
	float envelope_phase = dot(point, hum_envelope_frequency) - field_time * (base_pulse_speed * 0.32 + 0.09);
	float hum_wave = sin(hum_phase_a) * hum_wave_weights.x + sin(hum_phase_b) * hum_wave_weights.y;
	float hum_envelope = hum_envelope_shape.x + sin(envelope_phase) * hum_envelope_shape.y;
	return hum_wave * hum_envelope;
}


float radial_presence(vec2 point) {
	float radius_ratio = clamp(length(point) / max(dish_radius, 0.001), 0.0, 1.0);
	return 0.58 + ((1.0 - radius_ratio) * 0.42);
}


float base_height(vec2 point) {
	float phase_a = dot(point, breath_frequency_a) + field_time * base_pulse_speed;
	float phase_b = dot(point, breath_frequency_b) - field_time * base_pulse_speed * 0.73;
	float breath = sin(phase_a) * breath_wave_weights.x + sin(phase_b) * breath_wave_weights.y;
	return (base_pulse_strength * breath) + (base_pulse_strength * hum_height_scale * substrate_hum(point));
}


vec2 base_gradient(vec2 point) {
	float phase_a = dot(point, breath_frequency_a) + field_time * base_pulse_speed;
	float phase_b = dot(point, breath_frequency_b) - field_time * base_pulse_speed * 0.73;
	vec2 breath_slope = breath_frequency_a * cos(phase_a) * breath_wave_weights.x + breath_frequency_b * cos(phase_b) * breath_wave_weights.y;

	float hum_phase_a = dot(point, hum_frequency_a) - field_time * (base_pulse_speed * 3.8 + 0.72);
	float hum_phase_b = dot(point, hum_frequency_b) + field_time * (base_pulse_speed * 4.4 + 1.06);
	float envelope_phase = dot(point, hum_envelope_frequency) - field_time * (base_pulse_speed * 0.32 + 0.09);
	float hum_wave = sin(hum_phase_a) * hum_wave_weights.x + sin(hum_phase_b) * hum_wave_weights.y;
	float hum_envelope = hum_envelope_shape.x + sin(envelope_phase) * hum_envelope_shape.y;
	vec2 hum_slope = (
		hum_envelope * ((hum_frequency_a * cos(hum_phase_a) * hum_wave_weights.x) + (hum_frequency_b * cos(hum_phase_b) * hum_wave_weights.y))
	) + (
		hum_wave * hum_envelope_frequency * cos(envelope_phase) * hum_envelope_shape.y
	);

	return (breath_slope + hum_slope * hum_height_scale) * base_pulse_strength * breath_gradient_scale;
}


vec2 base_flow(vec2 point, vec2 gradient) {
	float phase_a = dot(point, breath_frequency_a) + field_time * base_pulse_speed;
	float phase_b = dot(point, breath_frequency_b) - field_time * base_pulse_speed * 0.73;
	vec2 breath_drive = safe_normalize(breath_frequency_a) * ((sin(phase_a) * 0.5) + 0.5) * breath_wave_weights.x
		+ safe_normalize(breath_frequency_b) * ((sin(phase_b) * 0.5) + 0.5) * breath_wave_weights.y;

	float hum_phase_a = dot(point, hum_frequency_a) - field_time * (base_pulse_speed * 3.8 + 0.72);
	float hum_phase_b = dot(point, hum_frequency_b) + field_time * (base_pulse_speed * 4.4 + 1.06);
	float envelope_phase = dot(point, hum_envelope_frequency) - field_time * (base_pulse_speed * 0.32 + 0.09);
	float hum_envelope = hum_envelope_shape.x + sin(envelope_phase) * hum_envelope_shape.y;
	vec2 hum_drive = safe_normalize(hum_frequency_a) * ((sin(hum_phase_a) * 0.5) + 0.5) * hum_wave_weights.x
		+ safe_normalize(hum_frequency_b) * ((sin(hum_phase_b) * 0.5) + 0.5) * hum_wave_weights.y;
	vec2 vortical_flow = vec2(-gradient.y, gradient.x);

	return (
		breath_drive
		+ hum_drive * hum_envelope * flow_hum_scale
		+ vortical_flow * flow_vorticity_scale
	) * base_pulse_strength * flow_strength_scale;
}


float wall_wave_reach() {
	return max(dish_radius * wall_wave_reach_ratio, 0.001);
}


float wall_wave_band(float distance_to_wall, float reach) {
	return 1.0 - smoothstep01(distance_to_wall / reach);
}


float wall_wave_band_derivative(float distance_to_wall, float reach) {
	if (reach <= 0.000001) {
		return 0.0;
	}
	return -smoothstep_derivative01(distance_to_wall / reach) / reach;
}


float boundary_wave_signal(float distance_to_wall, vec2 point) {
	float angle = atan(point.y, point.x);
	float primary_phase = distance_to_wall * wall_wave_frequency - field_time * wall_wave_speed;
	float angular_drift_phase = angle * 1.7 + field_time * (wall_wave_swirl_speed * 0.48 + 0.07);
	float angular_drift = sin(angular_drift_phase + distance_to_wall * wall_wave_frequency * 0.22) * 0.42;
	float secondary_phase = distance_to_wall * wall_wave_frequency * 0.61
		- field_time * (wall_wave_speed * 0.57 + 0.11)
		+ angle * 1.9;
	float envelope = 0.78 + sin(angle * 2.3 - field_time * (wall_wave_swirl_speed * 0.36 + 0.05)) * 0.22;
	return (sin(primary_phase + angular_drift) * 0.74 + sin(secondary_phase) * 0.26) * envelope;
}


float boundary_wave_signal_derivative(float distance_to_wall, vec2 point) {
	float angle = atan(point.y, point.x);
	float angular_drift_phase = angle * 1.7 + field_time * (wall_wave_swirl_speed * 0.48 + 0.07);
	float angular_argument = angular_drift_phase + distance_to_wall * wall_wave_frequency * 0.22;
	float angular_drift = sin(angular_argument) * 0.42;
	float angular_drift_derivative = cos(angular_argument) * wall_wave_frequency * 0.22 * 0.42;
	float primary_total = distance_to_wall * wall_wave_frequency - field_time * wall_wave_speed + angular_drift;
	float secondary_phase = distance_to_wall * wall_wave_frequency * 0.61
		- field_time * (wall_wave_speed * 0.57 + 0.11)
		+ angle * 1.9;
	float envelope = 0.78 + sin(angle * 2.3 - field_time * (wall_wave_swirl_speed * 0.36 + 0.05)) * 0.22;
	return (
		cos(primary_total) * (wall_wave_frequency + angular_drift_derivative) * 0.74
		+ cos(secondary_phase) * wall_wave_frequency * 0.61 * 0.26
	) * envelope;
}


float boundary_wave_pulse(float wave_signal) {
	return pow(clamp(wave_signal * 0.58 + 0.42, 0.0, 1.0), max(wall_wave_sharpness, 1.0));
}


float boundary_wave_height(vec2 point) {
	vec2 inward = safe_inward(point);
	if (length(inward) <= 0.0001) {
		return 0.0;
	}
	float distance_to_wall = max(dish_radius - length(point), 0.0);
	float reach = wall_wave_reach();
	float band = wall_wave_band(distance_to_wall, reach);
	if (band <= 0.0) {
		return 0.0;
	}
	float wave_signal = boundary_wave_signal(distance_to_wall, point);
	return wave_signal * wall_wave_height_strength * band;
}


vec2 boundary_wave_gradient(vec2 point) {
	vec2 inward = safe_inward(point);
	if (length(inward) <= 0.0001) {
		return vec2(0.0);
	}
	float distance_to_wall = max(dish_radius - length(point), 0.0);
	float reach = wall_wave_reach();
	float band = wall_wave_band(distance_to_wall, reach);
	if (band <= 0.0) {
		return vec2(0.0);
	}
	float band_slope = wall_wave_band_derivative(distance_to_wall, reach);
	float wave_signal = boundary_wave_signal(distance_to_wall, point);
	float wave_slope = boundary_wave_signal_derivative(distance_to_wall, point);
	float height_slope = wave_slope * wall_wave_height_strength * band
		+ wave_signal * wall_wave_height_strength * band_slope;
	return inward * height_slope;
}


vec2 boundary_wave_flow(vec2 point) {
	vec2 inward = safe_inward(point);
	if (length(inward) <= 0.0001) {
		return vec2(0.0);
	}
	float distance_to_wall = max(dish_radius - length(point), 0.0);
	float reach = wall_wave_reach();
	float band = wall_wave_band(distance_to_wall, reach);
	if (band <= 0.0) {
		return vec2(0.0);
	}
	float wave_signal = boundary_wave_signal(distance_to_wall, point);
	float pulse = boundary_wave_pulse(wave_signal);
	vec2 tangent = vec2(-inward.y, inward.x);
	float angle = atan(point.y, point.x);
	float swirl_phase = field_time * (wall_wave_swirl_speed * 0.86 + 0.05) + distance_to_wall * wall_wave_frequency * 0.31 + angle * 1.2;
	float swirl = sin(swirl_phase) * wall_wave_swirl_strength * (0.45 + pulse * 0.55);
	return inward * pulse * wall_wave_push_strength * band + tangent * swirl * band;
}


void apply_coil_torsion_signatures(
	vec2 point,
	inout vec2 gradient,
	inout vec2 flow,
	inout float charge,
	inout float coherence,
	inout float turbulence
) {
	for (int torsion_index = 0; torsion_index < MAX_COIL_TORSIONS; torsion_index++) {
		if (torsion_index >= coil_torsion_count) {
			break;
		}

		vec4 torsion_a = coil_torsion_a[torsion_index];
		vec4 torsion_b = coil_torsion_b[torsion_index];
		vec4 torsion_c = coil_torsion_c[torsion_index];
		vec2 coil_position = torsion_a.xy;
		float coil_radius = torsion_a.z;
		float coil_phase = torsion_a.w;
		float coil_spin_rate = torsion_b.x;
		float coil_strength = torsion_b.y;
		vec2 forward = torsion_b.zw;
		if (length(forward) <= 0.0001) {
			forward = vec2(1.0, 0.0);
		} else {
			forward = normalize(forward);
		}
		vec2 side = vec2(-forward.y, forward.x);
		float shear_strength = torsion_c.x;
		float charge_strength = torsion_c.y;
		float turbulence_strength = torsion_c.z;
		float helix_amplitude = torsion_c.w;
		float spin_sign = coil_spin_rate >= 0.0 ? 1.0 : -1.0;

		if (coil_radius <= 0.0) {
			continue;
		}

		vec2 offset_from_coil = point - coil_position;
		float distance_squared = dot(offset_from_coil, offset_from_coil);
		float radius_squared = coil_radius * coil_radius;
		if (distance_squared <= 0.000001 || distance_squared >= radius_squared) {
			continue;
		}

		float distance = sqrt(distance_squared);
		float distance_ratio = clamp(distance / coil_radius, 0.0, 1.0);
		float falloff = 1.0 - smoothstep01(distance_ratio);
		float local_forward = dot(offset_from_coil, forward);
		float local_side = dot(offset_from_coil, side);
		float local_angle = atan(local_side, local_forward);
		vec2 tangent = vec2(-offset_from_coil.y, offset_from_coil.x) / distance;
		float torsion_strength = coil_strength * spin_sign * (0.88 + helix_amplitude * 0.18);
		float phase_wave = sin(
			coil_phase
			+ local_angle * 1.7
			+ local_forward / max(coil_radius, 0.001) * PI * 1.4
		);
		float turbulence_wave = 0.68 + abs(sin(coil_phase * 0.82 - local_angle * 1.9)) * 0.32;
		float spin_abs = abs(coil_spin_rate);
		vec2 flow_torsion = tangent * torsion_strength * falloff;
		vec2 flow_shear = forward * phase_wave * falloff * shear_strength * spin_abs;
		float front_offset = coil_radius * (0.34 + helix_amplitude * 0.06);
		float rear_offset = coil_radius * (0.20 + helix_amplitude * 0.05);
		vec2 front_point = coil_position + forward * front_offset;
		vec2 rear_point = coil_position - forward * rear_offset;
		vec2 front_delta = point - front_point;
		vec2 rear_delta = point - rear_point;
		float front_distance = max(length(front_delta), 0.0001);
		float rear_distance = max(length(rear_delta), 0.0001);
		float front_long = dot(front_delta, forward);
		float rear_long = -dot(rear_delta, forward);
		float front_side = abs(dot(front_delta, side));
		float rear_side = abs(dot(rear_delta, side));
		float front_axial = smoothstep01(clamp((front_long + coil_radius * 0.08) / (coil_radius * 0.68), 0.0, 1.0));
		float rear_axial = smoothstep01(clamp((rear_long + coil_radius * 0.16) / (coil_radius * 1.52), 0.0, 1.0));
		float front_side_limit = coil_radius * mix(0.12, 0.24, front_axial);
		float rear_side_limit = coil_radius * mix(0.22, 0.64, rear_axial);
		float front_side_focus = 1.0 - smoothstep01(clamp(front_side / max(front_side_limit, 0.001), 0.0, 1.0));
		float rear_side_focus = 1.0 - smoothstep01(clamp(rear_side / max(rear_side_limit, 0.001), 0.0, 1.0));
		float front_distance_focus = 1.0 - smoothstep01(clamp(front_distance / (coil_radius * 0.82), 0.0, 1.0));
		float rear_distance_focus = 1.0 - smoothstep01(clamp(rear_distance / (coil_radius * 1.62), 0.0, 1.0));
		float front_focus = front_axial * front_side_focus * front_distance_focus;
		float rear_focus = rear_axial * rear_side_focus * rear_distance_focus;
		vec2 intake_direction = (front_point - point) / front_distance;
		float rear_side_sign = sign(dot(rear_delta, side));
		vec2 bite_pull = intake_direction * front_focus * (shear_strength * (1.05 + spin_abs * 0.78) + coil_strength * 0.22);
		vec2 front_compress = -side * sign(dot(front_delta, side)) * front_focus * shear_strength * 0.18;
		vec2 rear_trail = -forward * rear_focus * (shear_strength * (0.72 + spin_abs * 0.46) + coil_strength * 0.14);
		vec2 rear_splay = (
			tangent * phase_wave * 0.88
			+ side * rear_side_sign * 0.42
			- forward * 0.18
		) * rear_focus * coil_strength * 0.34;

		gradient += flow_torsion;
		gradient += flow_shear;
		gradient += bite_pull;
		gradient += front_compress;
		gradient += rear_trail;
		gradient += rear_splay;
		flow += flow_torsion * 1.05;
		flow += flow_shear * 1.25;
		flow += bite_pull * 1.60;
		flow += front_compress * 1.24;
		flow += rear_trail * 1.48;
		flow += rear_splay * 1.26;
		turbulence += spin_abs * falloff * turbulence_strength * turbulence_wave;
		turbulence += (front_focus * 0.020 + rear_focus * 0.070) * (0.8 + spin_abs) * turbulence_strength;
		charge += sin(coil_phase + local_angle * 2.0) * charge_strength * falloff;
		charge += sin(coil_phase * 1.14 + front_long * 0.12) * charge_strength * front_focus * 0.42;
		charge += cos(coil_phase * 0.92 - rear_long * 0.10) * charge_strength * rear_focus * 0.56;
		coherence -= spin_abs * falloff * (0.008 + helix_amplitude * 0.004);
		coherence -= (front_focus * 0.010 + rear_focus * 0.016) * (0.008 + helix_amplitude * 0.004);
	}
}


void sample_field(
	vec2 point,
	out float height,
	out vec2 gradient,
	out vec2 flow,
	out float charge,
	out float coherence,
	out float turbulence
) {
	vec2 sample_position = clamp_to_dish(point);
	float hum = substrate_hum(sample_position);
	float hum_abs = abs(hum);

	float base_field_height = base_height(sample_position);
	vec2 base_field_gradient = base_gradient(sample_position);
	height = base_field_height + boundary_wave_height(sample_position);
	gradient = base_field_gradient + boundary_wave_gradient(sample_position);
	flow = base_flow(sample_position, base_field_gradient) + boundary_wave_flow(sample_position);
	charge = hum * radial_presence(sample_position) * hum_charge_scale;
	coherence = 0.9 - hum_abs * 0.04;
	turbulence = 0.08 + hum_abs * hum_turbulence_scale;

	vec2 offset_from_center = sample_position - well_position;
	float distance_from_well = length(offset_from_center);
	if (well_radius > 0.0 && distance_from_well < well_radius) {
		float distance_ratio = clamp(distance_from_well / well_radius, 0.0, 1.0);
		float falloff = 1.0 - smoothstep01(distance_ratio);
		float height_delta = -well_strength * falloff;

		height += height_delta;
		charge += well_charge_bias * falloff;

		if (distance_from_well > 0.0001) {
			float slope_magnitude = (well_strength / well_radius) * smoothstep_derivative01(distance_ratio);
			vec2 toward_center = -offset_from_center / distance_from_well;
			gradient += toward_center * slope_magnitude;
		}

		float strength_scale = max(abs(well_strength), 0.001);
		float center_influence = clamp(abs(height_delta) / strength_scale, 0.0, 1.0);
		coherence += center_influence * min(strength_scale / 42.0, 1.0) * 0.12;
	}

	apply_coil_torsion_signatures(sample_position, gradient, flow, charge, coherence, turbulence);

	float gradient_energy = length(gradient);
	float flow_energy = length(flow);
	turbulence += clamp(gradient_energy * 0.09 + flow_energy * 0.06, 0.0, 0.22);
	coherence = clamp(coherence - turbulence * 0.08, 0.0, 1.0);
	charge = clamp(charge, -1.0, 1.0);
	turbulence = clamp(turbulence, 0.0, 1.0);
}


float resting_conductor(vec2 point) {
	float conductor = 0.62;
	conductor += 0.14 * sin(dot(point, vec2(0.013, -0.009)) - field_time * 0.21);
	conductor += 0.10 * sin(dot(point, vec2(-0.010, 0.016)) - field_time * 0.14 + 1.2);
	return clamp(conductor, 0.38, 0.96);
}


float context_activation(vec2 gradient, float charge, float turbulence, float height, float coherence) {
	return clamp(
		length(gradient) * 0.86
		+ clamp(length(vec2(-gradient.y, gradient.x)) * 0.22, 0.0, 0.22)
		+ abs(charge) * 0.62
		+ turbulence * 0.30
		+ max(0.0, -height) * 0.0082
		- coherence * 0.06,
		0.0,
		1.0
	);
}


float basin_quieting(float height, vec2 gradient) {
	float basin_depth = clamp(-height / 58.0, 0.0, 1.4);
	float slope_presence = clamp(length(gradient) / 0.26, 0.0, 1.0);
	return clamp(basin_depth * (1.0 - slope_presence) * 0.70, 0.0, 1.0);
}


float phase_at(vec2 point, float speed, float scale) {
	float phase_a = dot(point, vec2(scale, scale * 1.31)) + field_time * speed;
	float phase_b = dot(point, vec2(-scale * 1.73, scale * 0.83)) - field_time * speed * 0.61;
	return sin(phase_a) * 0.62 + sin(phase_b) * 0.38;
}


vec2 resolve_pull_direction(vec2 point, vec2 gradient) {
	if (dot(gradient, gradient) > 0.000001) {
		return normalize(gradient);
	}
	if (dot(point, point) > 0.000001) {
		return normalize(point);
	}
	return vec2(1.0, 0.0);
}


vec2 warp_point(
	vec2 point,
	float height,
	vec2 gradient,
	float charge,
	float coherence,
	float turbulence,
	float activation,
	float resting
) {
	float tension = length(gradient);
	float basin_depth = clamp(-height / 58.0, 0.0, 1.4);
	float lift = clamp(height / 22.0, 0.0, 0.45);
	float charge_strength = abs(charge);
	vec2 pull_direction = resolve_pull_direction(point, gradient);
	vec2 normal = vec2(-pull_direction.y, pull_direction.x);
	float gradient_softness = 1.0 - exp(-tension / 0.32);
	float capped_gradient_pull = (6.2 + basin_depth * 2.4 + charge_strength) * gradient_softness;
	float basin_pull = max(-height, 0.0) * 0.055 * (0.32 + gradient_softness * 0.44);
	float quiet_center = basin_quieting(height, gradient);
	float total_pull = min((capped_gradient_pull + basin_pull) * (1.0 - quiet_center * 0.42), mesh_spacing * 0.42);

	float phase = phase_at(
		point + gradient * 20.0,
		0.22 + charge_strength + turbulence * 0.95,
		0.018 + tension * 0.008
	);
	float tremor = phase * (0.05 + resting * 0.04 + activation * 0.08) * (0.34 + (1.0 - coherence) * 0.66);

	vec2 warped = point + pull_direction * total_pull;
	warped -= pull_direction * lift * 0.08;
	warped += normal * tremor * 1.05;

	for (int torsion_index = 0; torsion_index < MAX_COIL_TORSIONS; torsion_index++) {
		if (torsion_index >= coil_torsion_count) {
			break;
		}

		vec4 torsion_a = coil_torsion_a[torsion_index];
		vec4 torsion_b = coil_torsion_b[torsion_index];
		vec4 torsion_c = coil_torsion_c[torsion_index];
		vec2 coil_position = torsion_a.xy;
		float coil_radius = torsion_a.z;
		float coil_phase = torsion_a.w;
		float coil_spin_rate = torsion_b.x;
		float coil_strength = torsion_b.y;
		float helix_amplitude = torsion_c.w;
		float spin_sign = coil_spin_rate >= 0.0 ? 1.0 : -1.0;

		if (coil_radius <= 0.0) {
			continue;
		}

		vec2 offset_from_coil = point - coil_position;
		float distance_squared = dot(offset_from_coil, offset_from_coil);
		float radius_squared = coil_radius * coil_radius;
		if (distance_squared <= 0.000001 || distance_squared >= radius_squared) {
			continue;
		}

		float distance = sqrt(distance_squared);
		float distance_ratio = clamp(distance / coil_radius, 0.0, 1.0);
		float falloff = 1.0 - smoothstep01(distance_ratio);
		vec2 tangent = vec2(-offset_from_coil.y, offset_from_coil.x) / distance;
		float torsion_phase = sin(coil_phase + distance_ratio * PI * 1.9);
		warped += tangent * coil_strength * spin_sign * falloff * (0.82 + helix_amplitude * 0.22) * torsion_phase * 6.8;
	}

	return warped;
}


float line_alpha(float distance_to_line, float half_width, float feather) {
	return 1.0 - smoothstep(half_width - feather, half_width + feather, distance_to_line);
}


float ring_band(float radius_value, float center_radius, float half_width, float feather) {
	return 1.0 - smoothstep(half_width - feather, half_width + feather, abs(radius_value - center_radius));
}


void fragment() {
	vec2 world_pos = v_world_pos;
	float radius_value = length(world_pos);
	float pixel_world = max(camera_zoom, 0.001);
	float outer_limit = dish_radius + pixel_world * 18.0;

	if (radius_value > outer_limit) {
		COLOR = vec4(0.0);
	} else {
		float height;
		vec2 gradient;
		vec2 flow;
		float charge;
		float coherence;
		float turbulence;
		sample_field(world_pos, height, gradient, flow, charge, coherence, turbulence);

		float activation = context_activation(gradient, charge, turbulence, height, coherence);
		float quiet_center = basin_quieting(height, gradient);
		float resting = resting_conductor(world_pos);
		vec2 warped = warp_point(world_pos, height, gradient, charge, coherence, turbulence, activation, resting);

		vec2 grid_local = (fract((warped + vec2(mesh_spacing * 0.5)) / mesh_spacing) - 0.5) * mesh_spacing;
		float dist_vertical = abs(grid_local.x);
		float dist_horizontal = abs(grid_local.y);
		float feather_vertical = max(fwidth(dist_vertical), pixel_world * 0.45);
		float feather_horizontal = max(fwidth(dist_horizontal), pixel_world * 0.45);
		float body_half_width = pixel_world * 1.00;
		float outer_body_half_width = pixel_world * 1.38;
		float core_half_width = pixel_world * 0.40;

		float outer_vertical_mask = line_alpha(dist_vertical, outer_body_half_width, feather_vertical * 1.06);
		float outer_horizontal_mask = line_alpha(dist_horizontal, outer_body_half_width, feather_horizontal * 1.06);
		float body_vertical_mask = line_alpha(dist_vertical, body_half_width, feather_vertical);
		float body_horizontal_mask = line_alpha(dist_horizontal, body_half_width, feather_horizontal);
		float core_vertical_mask = line_alpha(dist_vertical, core_half_width, max(feather_vertical * 0.72, pixel_world * 0.22));
		float core_horizontal_mask = line_alpha(dist_horizontal, core_half_width, max(feather_horizontal * 0.72, pixel_world * 0.22));

		float vertical_mask = body_vertical_mask;
		float horizontal_mask = body_horizontal_mask;
		float outer_body_mask = max(outer_vertical_mask, outer_horizontal_mask);
		float body_mask = max(body_vertical_mask, body_horizontal_mask);
		float core_mask = max(core_vertical_mask, core_horizontal_mask);
		float base_mask = max(vertical_mask, horizontal_mask);
		float axis_sum = vertical_mask + horizontal_mask + 0.0001;
		float weight_vertical = vertical_mask / axis_sum;
		float weight_horizontal = horizontal_mask / axis_sum;

		float flow_strength = length(flow);
		vec2 flow_direction = flow_strength > 0.0001 ? flow / flow_strength : resolve_pull_direction(world_pos, gradient);
		vec2 flow_normal = vec2(-flow_direction.y, flow_direction.x);
		float along_flow = dot(warped, flow_direction);
		float cross_flow = dot(warped, flow_normal);
		float speed = 0.34 + flow_strength * 5.4 + activation * 0.92 + abs(charge) * 0.82 - coherence * 0.05;
		float phase_base = along_flow * 0.042 - field_time * speed + cross_flow * 0.010;
		float flow_axis_mix = dot(flow_direction, normalize(vec2(0.78, 0.62)));
		float phase_horizontal = phase_base + flow_axis_mix * 0.28;
		float phase_vertical = phase_base - flow_axis_mix * 0.28;

		float primary_horizontal = pow(max(sin(phase_horizontal), 0.0), 4.8) * weight_horizontal;
		float primary_vertical = pow(max(sin(phase_vertical), 0.0), 4.8) * weight_vertical;
		float aftertone_horizontal = pow(max(sin(phase_horizontal - 0.88), 0.0), 5.8) * weight_horizontal;
		float aftertone_vertical = pow(max(sin(phase_vertical - 0.88), 0.0), 5.8) * weight_vertical;
		float glint_horizontal = pow(max(sin(phase_horizontal - 1.62), 0.0), 9.0) * weight_horizontal;
		float glint_vertical = pow(max(sin(phase_vertical - 1.62), 0.0), 9.0) * weight_vertical;

		float primary = clamp(primary_horizontal + primary_vertical, 0.0, 1.5);
		float aftertone = clamp(aftertone_horizontal + aftertone_vertical, 0.0, 1.2);
		float glint = clamp(glint_horizontal + glint_vertical, 0.0, 1.0);
		float curvature = clamp(length(gradient) * 0.58 + turbulence * 0.32, 0.0, 1.0);

		float fringe_strength = clamp(
			primary * 0.84
			+ aftertone * 0.52
			+ curvature * 0.24
			+ activation * 0.10
			- quiet_center * 0.22,
			0.0,
			1.3
		);

		float fringe_offset = body_half_width + pixel_world * (0.18 + fringe_strength * 0.14);
		float fringe_half_width = max(pixel_world * 0.11, 0.06);
		float fringe_feather = pixel_world * 0.16;
		float cool_vertical = line_alpha(abs(abs(grid_local.x) - fringe_offset), fringe_half_width, fringe_feather) * weight_vertical;
		float cool_horizontal = line_alpha(abs(abs(grid_local.y) - fringe_offset), fringe_half_width, fringe_feather) * weight_horizontal;
		float warm_vertical = line_alpha(abs(abs(grid_local.x) - (fringe_offset + pixel_world * 0.18)), fringe_half_width, fringe_feather) * weight_vertical;
		float warm_horizontal = line_alpha(abs(abs(grid_local.y) - (fringe_offset + pixel_world * 0.18)), fringe_half_width, fringe_feather) * weight_horizontal;
		float cool_fringe_mask = clamp(cool_vertical + cool_horizontal, 0.0, 1.0);
		float warm_fringe_mask = clamp(warm_vertical + warm_horizontal, 0.0, 1.0);
		float tracer_core_mask = line_alpha(min(dist_vertical, dist_horizontal), pixel_world * 0.24, pixel_world * 0.11) * core_mask;

		float dish_mask = 1.0 - smoothstep(dish_radius - pixel_world * 1.2, dish_radius + pixel_world * 1.2, radius_value);
		float field_mask = 1.0 - smoothstep(dish_radius - pixel_world * 6.4, dish_radius - pixel_world * 1.4, radius_value);

		float basin_depth = clamp(-height / 58.0, 0.0, 1.25);
		float charge_positive = max(charge, 0.0);
		float charge_negative = max(-charge, 0.0);
		float hum_color_shift = substrate_hum(world_pos) * 0.5 + 0.5;

		vec3 wash_color = mix(DISH_FILL, PALETTE_DEEP, 0.10 + resting * 0.04);
		wash_color = mix(wash_color, PALETTE_INDIGO, 0.03 + activation * 0.03 + charge_negative * 0.04);
		wash_color *= 0.34 - quiet_center * 0.06;
		wash_color -= vec3(basin_depth * 0.050);

		vec3 outer_filament = mix(PALETTE_DEEP, PALETTE_INDIGO, clamp(resting * 0.62 + activation * 0.08, 0.0, 1.0));
		outer_filament *= 0.76 - quiet_center * 0.04;

		vec3 base_filament = mix(PALETTE_INDIGO, PALETTE_BLUE, clamp(resting * 0.78 + activation * 0.12, 0.0, 1.0));
		base_filament = mix(base_filament, PALETTE_CYAN, 0.12 + primary * 0.18 + charge_negative * 0.12);
		base_filament *= 0.98 - quiet_center * 0.05;

		vec3 core_filament = mix(PALETTE_BLUE, PALETTE_CYAN, 0.52 + primary * 0.22 + hum_color_shift * 0.06);
		core_filament = mix(core_filament, vec3(0.82, 0.96, 1.0), glint * 0.10);
		core_filament *= 1.04 - quiet_center * 0.04;

		vec3 cool_fringe_color = mix(PALETTE_CYAN, vec3(0.90, 0.98, 1.0), glint * 0.26);
		vec3 warm_fringe_color = mix(PALETTE_MAGENTA, PALETTE_ROSE, 0.66 + aftertone * 0.12);
		warm_fringe_color = mix(warm_fringe_color, PALETTE_AMBER, glint * activation * 0.55);
		vec3 tracer_core_color = mix(PALETTE_CYAN, vec3(0.92, 0.99, 1.0), primary * 0.18 + glint * 0.06);

		float wash_mix = field_mask * (0.07 - quiet_center * 0.02 + activation * 0.008);
		float outer_alpha = outer_body_mask * field_mask * visual_intensity * (0.12 + resting * 0.06 + activation * 0.03);
		float base_alpha = body_mask * field_mask * visual_intensity * (0.28 + resting * 0.12 + activation * 0.10 - quiet_center * 0.04);
		float core_alpha = core_mask * field_mask * visual_intensity * (0.14 + resting * 0.08 + primary * 0.26 + activation * 0.08);
		float cool_alpha = cool_fringe_mask * field_mask * visual_intensity * (0.04 + fringe_strength * 0.18 + primary * 0.10);
		float warm_alpha = warm_fringe_mask * field_mask * visual_intensity * (0.02 + aftertone * 0.15 + activation * 0.04);
		float tracer_alpha = tracer_core_mask * field_mask * visual_intensity * (0.08 + primary * 0.38 + glint * activation * 0.18);

		vec3 color = DISH_FILL * dish_mask;
		color += wash_color * wash_mix;
		color += outer_filament * outer_alpha;
		color += base_filament * base_alpha;
		color += core_filament * core_alpha;
		color += cool_fringe_color * cool_alpha;
		color += warm_fringe_color * warm_alpha;
		color += tracer_core_color * tracer_alpha;

		float occlusion = ring_band(radius_value, dish_radius - pixel_world * 4.8, pixel_world * 2.2, pixel_world * 0.8) * 0.88;
		color = mix(color, WALL_OCCLUSION, occlusion);

		float meniscus = ring_band(radius_value, dish_radius - pixel_world * 1.2, pixel_world * 0.55, pixel_world * 0.35) * (0.08 + activation * 0.06 + abs(charge) * 0.04);
		color += WALL_MENISCUS * meniscus;

		float inner_bevel = ring_band(radius_value, dish_radius - pixel_world * 0.75, pixel_world * 0.46, pixel_world * 0.30);
		float wall_inner = ring_band(radius_value, dish_radius + pixel_world * 1.2, pixel_world * 2.2, pixel_world * 0.9);
		float wall_mid = ring_band(radius_value, dish_radius + pixel_world * 4.5, pixel_world * 3.0, pixel_world * 1.0);
		float wall_outer = ring_band(radius_value, dish_radius + pixel_world * 8.4, pixel_world * 3.8, pixel_world * 1.2);

		color = mix(color, WALL_INNER_BAND, wall_inner * 0.95);
		color = mix(color, WALL_MID_BAND, wall_mid * 0.96);
		color = mix(color, WALL_OUTER_BAND, wall_outer * 0.95);
		color = mix(color, WALL_BEVEL, inner_bevel * 0.16);

		float outer_shadow = ring_band(radius_value, dish_radius + pixel_world * 13.2, pixel_world * 5.2, pixel_world * 1.6) * 0.45;
		color = mix(color, WALL_OUTER_BAND, outer_shadow * 0.72);

		float alpha = max(dish_mask, max(wall_inner, max(wall_mid, wall_outer)));
		alpha = max(alpha, outer_shadow * 0.45);
		alpha = clamp(alpha, 0.0, 1.0);
		color *= alpha;

		COLOR = vec4(color, alpha);
	}
}
