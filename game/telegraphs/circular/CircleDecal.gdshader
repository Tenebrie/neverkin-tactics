shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_disabled, diffuse_lambert, specular_schlick_ggx;

instance uniform float COLOR_R : hint_range(0.0, 1.0) = 0;
instance uniform float COLOR_G : hint_range(0.0, 1.0) = 1;
instance uniform float COLOR_B : hint_range(0.0, 1.0) = 1;
instance uniform float PROGRESS : hint_range(0.0, 1.0) = 0.5;
instance uniform float RADIUS : hint_range(0.01, 10.0) = 0.5;
instance uniform float SCALE : hint_range(0.01, 10.0) = 1;
instance uniform float OUTER_WIDTH : hint_range(0.02, 0.10) = 0.05;
instance uniform float FADE : hint_range(0.0, 1.0) = 1;
instance uniform float INNER_ALPHA : hint_range(0.0, 1.0) = 1.0;
instance uniform float SECTOR : hint_range(0, 3.15) = 3.15;
instance uniform float CULL_DIST = 0;

float dfLine(vec2 O, vec2 P)
{
    vec2 D = normalize(O);
    vec2 X = O + D * dot(P-O, D);

    return distance(P, X);
}

void fragment()
{
	float dist = distance(NODE_POSITION_VIEW, VERTEX);
	float effectiveRadius = RADIUS * SCALE;
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
	
	vec3 world = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vec3 pos = (inverse(MODEL_MATRIX) * vec4((world), 1.0)).xyz;
	
	// Sector / cone
	if (SECTOR < PI)
	{
		float angle = acos(dot(pos, vec3(0.0, 0.0, -1.0)) / sqrt(pos.x * pos.x + pos.z * pos.z)) * sign(pos.x);
		if (angle > SECTOR || angle < -SECTOR)
		{
			ALPHA = 0.0;
		}
		else
		{
			vec3 leftLineVector = vec3(-sin(-SECTOR) * -1.0, 0.0, cos(-SECTOR) * -1.0);
			vec3 rightLineVector = vec3(-sin(SECTOR) * -1.0, 0.0, cos(SECTOR) * -1.0);
			
			float distToLeft = dfLine(leftLineVector.xz, pos.xz);
			float distToRight = dfLine(rightLineVector.xz, pos.xz);
			
			float distToCompare = angle < 0.0 ? distToLeft : distToRight;
			if (distToCompare < (OUTER_WIDTH * 0.8))
			{
				float d2 = (distToCompare) * 1.0 / (OUTER_WIDTH * 0.8);
				if (d2 < 0.5)
				{
					ALPHA = d2 * 2.0;
				}
				else
				{
					ALPHA += (1.0 - d2) * 2.0;
				}
				
				if (outerEdge)
				{
					float d3 = (dist - effectiveRadius + OUTER_WIDTH) * 1.0 / OUTER_WIDTH;
					if (d3 >= 0.5)
					{
						ALPHA = min(ALPHA, (1.0 - d3) * 2.0);
					}
				}
				ALPHA = min(1.0, ALPHA);
			}
		}
	}
	
	ALPHA *= FADE;
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

