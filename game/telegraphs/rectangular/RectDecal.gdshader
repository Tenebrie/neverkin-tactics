shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_lambert, specular_schlick_ggx;

instance uniform float COLOR_R : hint_range(0.0, 1.0) = 0;
instance uniform float COLOR_G : hint_range(0.0, 1.0) = 1;
instance uniform float COLOR_B : hint_range(0.0, 1.0) = 1;
instance uniform float PROGRESS : hint_range(0.0, 1.0) = 0.5;
instance uniform float SIZE_X : hint_range(0.01, 10.0) = 0.5;
instance uniform float SIZE_Z : hint_range(0.01, 10.0) = 0.5;
instance uniform float OUTER_WIDTH : hint_range(0.02, 0.10) = 0.05;
instance uniform float FADE : hint_range(0.0, 1.0) = 1;
instance uniform float CULL_DIST = 0;

void fragment()
{
	ALPHA = 0.05;
	bool transparent = false;
	float smoothOver = 0.015;
	float prog = PROGRESS;
	vec3 world = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vec3 pos = (inverse(MODEL_MATRIX) * vec4((world), 1.0)).xyz;
	float outerStartX = SIZE_X - OUTER_WIDTH;
	float outerStartZ = SIZE_Z - OUTER_WIDTH;
	bool leftRightEdge = (abs(pos.x) >= outerStartX && abs(pos.x) <= SIZE_X);
	bool topBottomEdge = (abs(pos.z) >= outerStartZ && abs(pos.z) <= SIZE_Z);
	
	bool innerLeftRight = abs(pos.x) <= prog * SIZE_X;
	bool innerTopBottom = abs(pos.z) <= prog * SIZE_Z;
	bool innerCircle = (innerTopBottom && innerLeftRight);
	if (topBottomEdge && leftRightEdge && !innerCircle)
	{
		float d1 = (abs(pos.x) - SIZE_X + OUTER_WIDTH) / OUTER_WIDTH;
		float d2 = (abs(pos.z) - SIZE_Z + OUTER_WIDTH) / OUTER_WIDTH;
		float d3 = sqrt(d1 * d1 + d2 * d2);
		if (d3 < 0.5)
		{
			ALPHA = max(0.05, d3 * 2.0);
		}
		else
		{
			float a = (1.0 - d3) * 2.0;
			ALBEDO = vec3(a, a, a);
			ALPHA = max(0.0, (1.0 - d3) * 2.0);
		}
		transparent = true;
	}
	else if (leftRightEdge && !innerCircle)
	{
		float d2 = (abs(pos.x) - SIZE_X + OUTER_WIDTH) / OUTER_WIDTH;
		if (d2 < 0.5)
		{
			ALPHA = d2 * 2.0;
		}
		else
		{
			float a = (1.0 - d2) * 2.0;
			ALBEDO = vec3(a, a, a);
			ALPHA = (1.0 - d2) * 2.0;
		}
	}
	else if (topBottomEdge && !innerCircle)
	{
		float d2 = (abs(pos.z) - SIZE_Z + OUTER_WIDTH) / OUTER_WIDTH;
		if (d2 < 0.5)
		{
			ALPHA = d2 * 2.0;
		}
		else
		{
			float a = (1.0 - d2) * 2.0;
			ALBEDO = vec3(a, a, a);
			ALPHA = (1.0 - d2) * 2.0;
		}
	}
	else if (innerCircle && !leftRightEdge && !topBottomEdge)
	{
		float d2 = (abs(pos.z) - prog * SIZE_Z + smoothOver) / smoothOver;
		float toLimit = prog - d2;
		ALPHA = min(0.5, toLimit) * 1.0;
		
		float d3 = (abs(pos.x) - prog * SIZE_X + smoothOver) / smoothOver;
		float toLimit2 = prog - d3;
		ALPHA *= max(0, min(1, toLimit2) * 1.0);
	}
	else if (innerCircle)
	{
		float d1 = leftRightEdge ? (abs(pos.x) - SIZE_X + OUTER_WIDTH) / OUTER_WIDTH : 0.0;
		float d2 = topBottomEdge ? (abs(pos.z) - SIZE_Z + OUTER_WIDTH) / OUTER_WIDTH : 0.0;
		float d3 = sqrt(d1 * d1 + d2 * d2);
		if (d3 < 0.5)
		{
			ALPHA = 1.0;
		}
		else
		{
			float a = (1.0 -d3) * 2.0;
			float b = min(1, d3 * 2.0 * a + (1.0 - d3) * 2.0);
			ALBEDO = vec3(b, b, b);
			ALPHA = max(0, a);
		}
		
		transparent = true;
	}
	float a = 1.0;
	
	ALBEDO = ALBEDO * vec3(COLOR_R * 0.5, COLOR_G * 0.5, COLOR_B * 0.5);
	if (!transparent)
		ALPHA = max(ALPHA, float(0.05));
	ALPHA = min(1.0, ALPHA);
	EMISSION = ALBEDO * 2.0;
	ALPHA *= FADE;
	
	if (abs(pos.x) > SIZE_X || abs(pos.z) > SIZE_Z)
	{
		ALPHA = 0.0;
	}
	
	if (CULL_DIST > 0.0 && (world.x > CULL_DIST || world.x < -CULL_DIST || world.z > CULL_DIST || world.z < -CULL_DIST))
	{
		ALPHA = 0.0;
	}
}
