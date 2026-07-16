shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_disabled, diffuse_lambert, specular_schlick_ggx;

instance uniform float COLOR_R : hint_range(0.0, 1.0) = 0;
instance uniform float COLOR_G : hint_range(0.0, 1.0) = 1;
instance uniform float COLOR_B : hint_range(0.0, 1.0) = 1;
instance uniform float COLOR_A : hint_range(0.0, 1.0) = 1;
instance uniform float PROGRESS : hint_range(0.0, 1.0) = 0.5;
instance uniform float RADIUS : hint_range(0.01, 10.0) = 0.5;
instance uniform float HALF_TRAVEL : hint_range(0.0, 100.0) = 0.5;
instance uniform float OUTER_WIDTH : hint_range(0.02, 0.10) = 0.05;
instance uniform float FADE : hint_range(0.0, 1.0) = 1;
instance uniform float INNER_ALPHA : hint_range(0.0, 1.0) = 1.0;
instance uniform float CULL_DIST = 0;

void fragment()
{
	vec3 world = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vec3 pos = (inverse(MODEL_MATRIX) * vec4((world), 1.0)).xyz;

	vec2 spine = vec2(pos.x, pos.z - clamp(pos.z, -HALF_TRAVEL, HALF_TRAVEL));
	float dist = length(spine);

	float effectiveRadius = RADIUS;
	float innerLimit = effectiveRadius * PROGRESS;
	ALPHA = 0.05 * INNER_ALPHA;
	bool outerEdge = dist > float(effectiveRadius - OUTER_WIDTH) && dist < float(effectiveRadius);
	bool innerCircle = dist < innerLimit;
	if (outerEdge)
	{
		float d2 = (dist - effectiveRadius + OUTER_WIDTH) * float(1) / OUTER_WIDTH;
		if (d2 < 0.5)
		{
			ALPHA = d2 * float(2);
		}
		else
		{
			float a = (1.0 - d2) * 2.0;
			ALBEDO = vec3(a, a, a);
			ALPHA = (float(1)-d2) * float(2);
		}
	}
	if (innerCircle)
	{
		float toLimit = innerLimit - dist;
		float d2 = (dist - effectiveRadius + OUTER_WIDTH) * float(1) / OUTER_WIDTH;
		if (d2 < 0.5)
			ALPHA = max(ALPHA, min(1, toLimit * float(25)) * 0.5);
	}

	if (dist < effectiveRadius)
	{
		ALBEDO = ALBEDO * vec3(COLOR_R * 0.5, COLOR_G * 0.5, COLOR_B * 0.5);
		ALPHA = max(ALPHA, float(0.05 * INNER_ALPHA));
	}

	ALPHA *= FADE * COLOR_A;
	EMISSION = ALBEDO * 2.0;

	if (dist > effectiveRadius)
	{
		ALPHA = 0.0;
	}

	if (CULL_DIST > 0.0 && (world.x > CULL_DIST || world.x < -CULL_DIST || world.z > CULL_DIST || world.z < -CULL_DIST))
	{
		ALPHA = 0.0;
	}
}
