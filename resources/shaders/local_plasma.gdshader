// Support layer under the main cell-field arc path.
//
// Legacy file name is retained, but this shader is the live plasma-sheath /
// bridge-support renderer. It composes:
// - plasma sheath close to the body
// - flame-like energetic haze in the near-body territory
// - bond bridge throats for strong resolved connections
//
// The result should support the readable arc geometry without replacing it.

shader_type canvas_item;
render_mode blend_add, unshaded;

const int MAX_SOURCES = 24;
const int MAX_BONDS = 32;

// Per-source data:
//   xy = world position
//   z  = effective body radius
//   w  = flame/sheath intensity
uniform vec4 sources[MAX_SOURCES];
uniform float source_phase[MAX_SOURCES];
// xy = blended bias direction from nearby cell-fields + ambient field
// z  = attraction/bend strength
// w  = shared / bonded unification factor
uniform vec4 source_field[MAX_SOURCES];
// xy = stable cell-local axis (body/aperture/tip direction)
// z  = style mode (0 sphere, 1 coil, 2 crescent, 3 triangle, 4 legacy line)
// w  = arc multiplier for this cell type
uniform vec4 source_style[MAX_SOURCES];
uniform int source_count = 0;

uniform float plasma_time = 0.0;

// Sheath / flame controls.
uniform float inner_width : hint_range(0.05, 4.0) = 0.55;
uniform float outer_width : hint_range(0.05, 4.0) = 1.85;
uniform float core_alpha : hint_range(0.0, 2.0) = 0.85;
uniform float glow_alpha : hint_range(0.0, 2.0) = 0.55;
uniform float brightness : hint_range(0.0, 4.0) = 1.55;
uniform float edge_softness : hint_range(0.0, 1.0) = 0.30;

uniform vec4 color_core : source_color = vec4(0.92, 0.97, 1.00, 1.0);
uniform vec4 color_mid  : source_color = vec4(0.30, 0.65, 1.00, 1.0);
uniform vec4 color_outer: source_color = vec4(0.10, 0.18, 0.55, 1.0);

uniform float noise_scale : hint_range(0.0001, 0.20) = 0.0150;
uniform float noise_speed : hint_range(0.0, 4.0) = 0.45;
uniform int fbm_octaves : hint_range(1, 6) = 4;
uniform float warp_scale : hint_range(0.0001, 0.20) = 0.018;
uniform float warp_gain : hint_range(0.0, 200.0) = 32.0;
uniform float warp_speed : hint_range(0.0, 4.0) = 0.30;
uniform float flow_speed : hint_range(0.0, 4.0) = 0.55;
uniform float territory_reach : hint_range(2.0, 16.0) = 8.80;
uniform float tendril_density : hint_range(0.25, 3.0) = 1.25;
uniform float tendril_softness : hint_range(0.0, 1.0) = 0.62;
uniform float tendril_flow_speed : hint_range(0.0, 4.0) = 0.82;
uniform float attraction_bend_gain : hint_range(0.0, 3.0) = 1.05;
uniform float lobe_gain : hint_range(0.0, 3.0) = 0.88;
uniform float bonded_unification_gain : hint_range(0.0, 3.0) = 1.12;

// Legacy internal shader-arc controls. The canonical visible cell-field arcs
// come from the cell-field overlay path in PetriDish/MagneticFieldOverlay.
uniform float cell_field_arc_enabled : hint_range(0.0, 1.0) = 1.0;
uniform float cell_field_arc_base_alpha : hint_range(0.0, 2.0) = 0.36;
uniform float cell_field_arc_base_width : hint_range(0.02, 0.30) = 0.088;
uniform float cell_field_arc_glow_alpha : hint_range(0.0, 2.0) = 0.24;
uniform float cell_field_arc_motion_speed : hint_range(0.0, 4.0) = 0.72;
uniform float cell_field_arc_motion_amplitude : hint_range(0.0, 0.4) = 0.085;
uniform float coil_field_torsion_gain : hint_range(0.0, 2.0) = 0.82;
uniform float crescent_field_funnel_gain : hint_range(0.0, 2.0) = 0.76;
uniform float triangle_field_edge_gain : hint_range(0.0, 2.0) = 0.58;

// Bond bridge contribution.
uniform vec4 bond_segments[MAX_BONDS];
uniform vec4 bond_params[MAX_BONDS];
uniform int bond_count = 0;
uniform float bridge_gain : hint_range(0.0, 4.0) = 1.20;
uniform float bridge_flow_speed : hint_range(0.0, 4.0) = 0.65;
uniform float bridge_stress_flicker : hint_range(0.0, 2.0) = 0.55;

varying vec2 world_pos;

void vertex() {
	world_pos = VERTEX;
}

float hash21(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	float a = hash21(i);
	float b = hash21(i + vec2(1.0, 0.0));
	float c = hash21(i + vec2(0.0, 1.0));
	float d = hash21(i + vec2(1.0, 1.0));
	return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

float fbm(vec2 p) {
	float v = 0.0;
	float a = 0.5;
	for (int i = 0; i < 6; i++) {
		if (i >= fbm_octaves) {
			break;
		}
		v += a * vnoise(p);
		p = p * 2.03 + vec2(11.7, 7.3);
		a *= 0.5;
	}
	return v;
}

vec2 rotate2(vec2 v, float ang) {
	float c = cos(ang);
	float s = sin(ang);
	return vec2(v.x * c - v.y * s, v.x * s + v.y * c);
}

vec2 safe_dir(vec2 v, vec2 fallback) {
	if (dot(v, v) <= 0.000001) {
		return fallback;
	}
	return normalize(v);
}

float segment_distance(vec2 p, vec2 a, vec2 b) {
	vec2 ab = b - a;
	float ab_len2 = max(dot(ab, ab), 0.000001);
	float t = clamp(dot(p - a, ab) / ab_len2, 0.0, 1.0);
	vec2 closest = a + ab * t;
	return length(p - closest);
}

vec2 quad_point(vec2 p0, vec2 p1, vec2 p2, float t) {
	float u = 1.0 - t;
	return u * u * p0 + 2.0 * u * t * p1 + t * t * p2;
}

void fragment() {
	float sheath_band = 0.0;
	float flame_field = 0.0;
	float lobe_field = 0.0;
	float arc_core_field = 0.0;
	float arc_glow_field = 0.0;
	vec2 flow = vec2(0.0);
	float dom_phase = 0.0;
	float dom_w = 0.0;

	for (int i = 0; i < MAX_SOURCES; i++) {
		if (i >= source_count) {
			break;
		}
		vec4 s = sources[i];
		vec2 src_pos = s.xy;
		float src_r = max(s.z, 1.0);
		float src_int = s.w;
		float phase = source_phase[i];
		vec4 sf = source_field[i];
		vec4 ss = source_style[i];
		float mode = ss.z;
		float arc_mult = ss.w;
		float bias_strength = clamp(sf.z, 0.0, 1.0);
		float shared = clamp(sf.w, 0.0, 1.0);

		vec2 fallback_axis = vec2(cos(phase), sin(phase));
		vec2 body_axis = safe_dir(ss.xy, fallback_axis);
		vec2 bias_dir = safe_dir(sf.xy, body_axis);

		float reach_scale = 1.0;
		float flame_gain = 1.0;
		float arc_reach_scale = 1.0;
		if (mode < 0.5) {
			// Sphere: strongest projector, broadest clean loops.
			body_axis = safe_dir(mix(body_axis, bias_dir, 0.28), body_axis);
		} else if (mode < 1.5) {
			// Coil: shorter field, stronger torsion.
			reach_scale = 0.72;
			flame_gain = 0.86;
			arc_reach_scale = 0.78;
			body_axis = safe_dir(
				rotate2(body_axis, sin(plasma_time * 0.40 + phase) * 0.45 * coil_field_torsion_gain),
				body_axis
			);
		} else if (mode < 2.5) {
			// Crescent: funnel / aperture shaper.
			reach_scale = 0.76;
			flame_gain = 0.74;
			arc_reach_scale = 0.74;
			body_axis = safe_dir(
				mix(body_axis, bias_dir, 0.18 + bias_strength * 0.22 * crescent_field_funnel_gain),
				body_axis
			);
		} else if (mode < 3.5) {
			// Triangle: weak projector, concentrated edge tension.
			reach_scale = 0.46;
			flame_gain = 0.56;
			arc_reach_scale = 0.40;
		} else {
			// Legacy line: weak residual field only.
			reach_scale = 0.58;
			flame_gain = 0.60;
			arc_reach_scale = 0.52;
		}

		vec2 field_axis = safe_dir(
			mix(body_axis, bias_dir, clamp(0.18 + bias_strength * attraction_bend_gain + shared * 0.18, 0.0, 1.0)),
			body_axis
		);
		vec2 field_perp = vec2(-field_axis.y, field_axis.x);

		vec2 d = world_pos - src_pos;
		float dist2 = dot(d, d);
		float dist = sqrt(max(dist2, 0.0001));
		vec2 dir = d / dist;
		float rr = dist / src_r;

		// Keep the close sheath subtle and mostly inside the body edge so it
		// reads as surface energy, not as a separate leftover halo ring.
		float sheath_inner = smoothstep(0.76, 0.95, rr);
		float sheath_outer = 1.0 - smoothstep(0.98 + inner_width * 0.04, 1.08 + inner_width * 0.05, rr);
		float sheath_anim = 0.86 + 0.14 * sin(phase + plasma_time * 0.34 + rr * 5.5);
		float sheath = sheath_inner * sheath_outer * (0.46 + 0.14 * src_int) * sheath_anim;
		sheath_band = max(sheath_band, sheath);

		float reach = src_r * territory_reach * reach_scale * (0.88 + 0.16 * src_int + shared * 0.14);
		float territory_t = clamp(1.0 - dist / max(reach, src_r + 1.0), 0.0, 1.0);
		// Keep the non-arc support haze soft and radial. The visible projected
		// structure should come from curved strokes, not from a filled wedge.
		float field_k = pow(territory_t, 1.55) * (0.24 + 0.22 * src_int + shared * 0.10) * flame_gain;
		lobe_field += pow(territory_t, 2.45) * 0.11 * src_int * (0.55 + shared * 0.30);

		vec2 tangent = vec2(-dir.y, dir.x);
		vec2 source_flow = tangent * (0.14 + 0.10 * territory_t);
		source_flow += dir * (0.05 + territory_t * 0.08);
		source_flow += field_axis * (0.10 + bias_strength * 0.28 + shared * 0.16);
		if (mode < 1.5 && mode >= 0.5) {
			source_flow += tangent * coil_field_torsion_gain * (0.16 + 0.22 * territory_t);
		}
		flow += source_flow * field_k * 0.52;

		float haze_outer = mix(2.65, 3.35, bias_strength * 0.26 + shared * 0.14);
		float mid_band = smoothstep(1.01, 1.34, rr) * (1.0 - smoothstep(haze_outer, haze_outer + 0.82, rr));
		vec2 stream_coord = d / src_r;
		stream_coord += source_flow * (plasma_time * tendril_flow_speed * 0.08);
		vec2 stream_frame = vec2(dot(stream_coord, field_axis), dot(stream_coord, field_perp));
		if (mode < 1.5 && mode >= 0.5) {
			stream_frame.y += sin(stream_frame.x * 1.8 + plasma_time * tendril_flow_speed + phase) * 0.28 * coil_field_torsion_gain;
		}
		float streak_a = fbm(
			stream_coord * (1.10 * tendril_density)
			+ vec2(phase, plasma_time * tendril_flow_speed * 0.45)
		);
		float streak_b = fbm(
			stream_frame * vec2(0.78, 2.45 * tendril_density)
			+ vec2(plasma_time * tendril_flow_speed * 0.28, phase + 4.1)
		);
		float flame_mask = smoothstep(
			0.76 - tendril_softness * 0.18,
			1.02 - tendril_softness * 0.04,
			streak_a * 0.58 + streak_b * 0.46
		);
		flame_field += field_k * flame_mask * mid_band * (0.42 + 0.34 * src_int);

		if (cell_field_arc_enabled > 0.5 && arc_mult > 0.001) {
			vec2 arc_axis = field_axis;
			vec2 arc_perp = field_perp;
			float motion = plasma_time * cell_field_arc_motion_speed;
			float arc_gain = arc_mult * (0.58 + 0.38 * bias_strength + shared * 0.24);
			float pull_in = clamp(bias_strength * 0.54 + shared * 0.72, 0.0, 0.92);
			float arc_end = mix(2.45, territory_reach * reach_scale * arc_reach_scale * 0.76, 0.82);

			if (mode < 3.5 || mode >= 4.5) {
				for (int a = 0; a < 3; a++) {
					float lane = float(a) - 1.0;
					float lane_mag = abs(lane);
					float lane_phase = phase + float(a) * 1.17;
					float sway = sin(motion * (0.52 + float(a) * 0.11) + lane_phase) * cell_field_arc_motion_amplitude;
					float bend = sin(motion * 0.41 + lane_phase + 0.8) * cell_field_arc_motion_amplitude * 1.8;
					float lane_gain = mix(0.78, 1.0, lane_mag);
					vec2 p0_local = vec2(0.96, 0.0);
					vec2 p1_local = vec2(1.34 + arc_end * 0.28, 0.0);
					vec2 p2_local = vec2(arc_end, 0.0);
					if (lane_mag < 0.1) {
						float center_lift = 0.24 + 0.12 * bias_strength - shared * 0.08;
						p0_local = vec2(0.96, 0.08 * bend);
						p1_local = vec2(1.28 + arc_end * 0.30, center_lift + bend * 0.90);
						p2_local = vec2(arc_end, 0.12 * sway);
					} else {
						float side_mid = lane * mix(1.08, 0.58, pull_in);
						float side_end = lane * mix(0.40, 0.10, pull_in);
						if (mode < 1.5 && mode >= 0.5) {
							side_mid += lane * 0.22 * coil_field_torsion_gain;
							side_end += bend * 0.68;
						} else if (mode >= 1.5 && mode < 2.5) {
							side_mid *= mix(1.0, 0.74, crescent_field_funnel_gain);
							side_end *= mix(1.0, 0.46, crescent_field_funnel_gain);
						}
						p0_local = vec2(0.36, lane * 0.92);
						p1_local = vec2(1.12 + arc_end * 0.25, side_mid + sway * 1.20);
						p2_local = vec2(arc_end, side_end + sway * 0.55);
					}
					vec2 q_prev = src_pos + arc_axis * (p0_local.x * src_r) + arc_perp * (p0_local.y * src_r);
					for (int s = 1; s < 7; s++) {
						float t1 = float(s) / 6.0;
						float tmid = (float(s) - 0.5) / 6.0;
						vec2 p_local = quad_point(p0_local, p1_local, p2_local, t1);
						vec2 q_curr = src_pos + arc_axis * (p_local.x * src_r) + arc_perp * (p_local.y * src_r);
						float dist_seg = segment_distance(world_pos, q_prev, q_curr);
						float arc_width = max(cell_field_arc_base_width * src_r * (0.82 + lane_mag * 0.16), 0.65);
						float fade = (1.0 - tmid * 0.42) * smoothstep(0.0, 0.10, tmid);
						float crawl = 0.72 + 0.28 * sin(lane_phase + motion * (1.12 + float(a) * 0.12) - tmid * 6.8);
						float core_band = exp(-pow(dist_seg / max(arc_width, 0.0001), 2.0));
						float glow_band = exp(-pow(dist_seg / max(arc_width * 2.70, 0.0001), 2.0));
						arc_core_field += core_band * fade * crawl * arc_gain * lane_gain;
						arc_glow_field += glow_band * fade * (0.84 + 0.16 * crawl) * arc_gain * lane_gain;
						q_prev = q_curr;
					}
				}
			}

			if (mode >= 2.5 && mode < 3.5) {
				float tip_align = max(dot(dir, body_axis), 0.0);
				float edge_align = abs(dot(dir, vec2(-body_axis.y, body_axis.x)));
				float tip_band = exp(-pow((rr - 1.10) / 0.16, 2.0)) * pow(tip_align, 6.0);
				float edge_band = exp(-pow((rr - 1.02) / 0.18, 2.0)) * pow(edge_align, 9.0);
				float glint = 0.72 + 0.28 * sin(motion * 1.30 + phase + rr * 4.0);
				arc_core_field += tip_band * triangle_field_edge_gain * arc_gain * glint;
				arc_glow_field += (tip_band * 0.65 + edge_band * 0.30) * triangle_field_edge_gain * arc_gain;
			}
		}

		if (field_k > dom_w) {
			dom_w = field_k;
			dom_phase = phase;
		}
	}

	for (int b = 0; b < MAX_BONDS; b++) {
		if (b >= bond_count) {
			break;
		}
		vec4 seg = bond_segments[b];
		vec2 pa = seg.xy;
		vec2 pb = seg.zw;
		vec4 prm = bond_params[b];
		float cap_r = max(prm.x, 1.0);
		float merge = clamp(prm.y, 0.0, 1.0);
		float bstrain = clamp(prm.z, 0.0, 1.0);
		float bphase = prm.w;
		if (merge <= 0.001) {
			continue;
		}
		vec2 ab = pb - pa;
		float ab_len2 = max(dot(ab, ab), 0.0001);
		float t = clamp(dot(world_pos - pa, ab) / ab_len2, 0.0, 1.0);
		vec2 closest = pa + ab * t;
		vec2 dvec = world_pos - closest;
		float dist2 = dot(dvec, dvec);
		float r_eff = mix(cap_r, cap_r * 0.55, bstrain);
		float r2 = r_eff * r_eff;
		float k = (r2 / (dist2 + r2 * 0.55)) * merge * bridge_gain;
		if (bstrain > 0.04) {
			float fl = vnoise(vec2(t * 7.3 + bphase, plasma_time * 4.5 + bphase));
			k *= mix(1.0, 0.55 + 0.45 * fl, bstrain * bridge_stress_flicker);
		}
		sheath_band = max(sheath_band, k * 0.46);
		flame_field += k * (0.14 + 0.20 * merge);
		lobe_field += k * (0.16 + 0.32 * merge);
		arc_glow_field += k * (0.10 + 0.18 * merge) * (1.0 - 0.55 * bstrain);
		vec2 ab_dir = ab / max(sqrt(ab_len2), 0.001);
		flow += ab_dir * k * bridge_flow_speed;
		if (k > dom_w) {
			dom_w = k;
			dom_phase = bphase;
		}
	}

	float visible = max(
		sheath_band * 0.55,
		max(
			max(lobe_field * 0.26, flame_field * 0.54),
			max(arc_glow_field * 0.44, arc_core_field * 0.42)
		)
	);
	if (visible < 0.035) {
		discard;
	}

	vec2 advect = flow * (plasma_time * flow_speed * 0.0040);
	vec2 wcoord = world_pos * warp_scale - advect;
	float wx = fbm(wcoord + vec2(plasma_time * warp_speed, dom_phase));
	float wy = fbm(wcoord + vec2(dom_phase + 7.3, plasma_time * warp_speed * 0.8));
	vec2 warp = (vec2(wx, wy) - 0.5) * warp_gain;

	vec2 ncoord = world_pos * noise_scale + warp * noise_scale;
	ncoord += vec2(plasma_time * noise_speed * 0.40, plasma_time * noise_speed);
	float n1 = fbm(ncoord + vec2(dom_phase, 0.0));
	float n2 = fbm(ncoord * 1.9 + vec2(plasma_time * noise_speed * 0.7, dom_phase + 3.1));
	float texture_n = clamp(0.55 + 0.55 * mix(n1, n2, 0.5), 0.0, 1.4);

	float core_strength = smoothstep(0.18, 0.82 + inner_width * 0.28, sheath_band);
	float flame_strength = smoothstep(
		0.04,
		max(outer_width * 0.36, 0.10),
		flame_field * (0.78 + 0.22 * texture_n)
	);
	float lobe_strength = smoothstep(
		0.02,
		max(outer_width * 0.28, 0.08),
		lobe_field
	);
	float arc_core_strength = smoothstep(0.04, 0.44, arc_core_field);
	float arc_glow_strength = smoothstep(0.02, 0.24, arc_glow_field);

	vec3 flame_col = mix(
		color_outer.rgb,
		color_mid.rgb,
		clamp(lobe_strength * 0.86 + flame_strength * 0.36, 0.0, 1.0)
	);
	flame_col = mix(
		flame_col,
		color_core.rgb,
		clamp(core_strength * 0.95 + flame_strength * 0.18, 0.0, 1.0)
	);
	vec3 arc_col = mix(color_mid.rgb, color_core.rgb, 0.78);
	arc_col = mix(arc_col, vec3(1.0), clamp(arc_core_strength * 0.20, 0.0, 0.20));

	vec3 col = flame_col;
	col = mix(col, arc_col, clamp(arc_glow_strength * 0.58 + arc_core_strength * 0.86, 0.0, 1.0));

	float a_core = core_strength * core_alpha * 0.40 * (0.90 + 0.10 * texture_n);
	float a_flame = flame_strength * glow_alpha * 0.46 * (0.74 + 0.26 * texture_n);
	float a_lobe = lobe_strength * glow_alpha * 0.10 * (0.88 + 0.12 * n1);
	float a_arc_glow = arc_glow_strength * cell_field_arc_glow_alpha * 1.08 * (0.82 + 0.18 * texture_n);
	float a_arc_core = arc_core_strength * cell_field_arc_base_alpha * 1.12;
	float a = (a_core + a_flame + a_lobe + a_arc_glow + a_arc_core) * brightness;

	float edge = smoothstep(0.02, 0.12 + edge_softness * 0.25, visible);
	a *= edge;
	a = clamp(a, 0.0, 1.0);
	COLOR = vec4(col, a);
}
