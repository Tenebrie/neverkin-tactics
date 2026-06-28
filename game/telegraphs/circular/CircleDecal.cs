using Godot;
using System;

namespace Project;

[Tool]
public partial class CircleDecal : MeshInstance3D
{
	bool persistent = false;
	[Export]
	public bool Persistent
	{
		get => persistent;
		set
		{
			persistent = value;
			SetInstanceShaderParameter("PROGRESS".ToStringName(), value ? 1.0 : 0.5);
		}
	}

	float radius = 0.5f;
	[Export(PropertyHint.Range, "0.25, 10")]
	public float Radius
	{
		get => radius;
		set
		{
			radius = value;
			(Mesh as PlaneMesh).Size = new Vector2(value * 2, value * 2);
			SetInstanceShaderParameter("RADIUS".ToStringName(), radius);
		}
	}

	float coneAngle = 3.15f;
	[Export(PropertyHint.Range, "0, 3.15")]
	public float ConeAngle
	{
		get => coneAngle;
		set
		{
			coneAngle = value;
			SetInstanceShaderParameter("SECTOR".ToStringName(), value);
		}
	}

	UnitAlliance alliance = UnitAlliance.Neutral;
	[Export]
	public UnitAlliance Alliance
	{
		get => alliance;
		set
		{
			alliance = value;
			SetColor(CastUtils.GetAllianceColor(value));
		}
	}

	bool fadingIn = true;
	bool fadingOut = false;

	float fadeValue = 0;
	public Action onFadedOut;

	public override void _Ready()
	{
		if (Engine.IsEditorHint())
			return;

		SetInstanceShaderParameter("FADE".ToStringName(), fadeValue);
	}

	public override void _Process(double delta)
	{
		if (Engine.IsEditorHint())
			return;

		if (fadingOut)
		{
			fadeValue -= (float)delta * 4;

			SetInstanceShaderParameter("FADE".ToStringName(), fadeValue);
			if (fadeValue <= 0)
			{
				onFadedOut?.Invoke();
				QueueFree();
			}
		}
		else if (fadingIn)
		{
			fadeValue += (float)delta * 4;
			SetInstanceShaderParameter("FADE".ToStringName(), fadeValue);
			if (fadeValue >= 1)
			{
				fadeValue = 1;
				fadingIn = false;
			}
		}
	}

	public void EnableCulling()
	{
		SetInstanceShaderParameter("CULL_DIST".ToStringName(), this.GetArenaSize());
	}

	public void SetInnerAlpha(float value)
	{
		SetInstanceShaderParameter("INNER_ALPHA".ToStringName(), value);
	}

	public void SetProgress(float value)
	{
		SetInstanceShaderParameter("PROGRESS".ToStringName(), value);
	}

	public void SetColor(Color color)
	{
		SetInstanceShaderParameter("COLOR_R".ToStringName(), color.R);
		SetInstanceShaderParameter("COLOR_G".ToStringName(), color.G);
		SetInstanceShaderParameter("COLOR_B".ToStringName(), color.B);
	}

	public void SetOuterWidth(float value)
	{
		SetInstanceShaderParameter("OUTER_WIDTH".ToStringName(), value / 20);
	}

	public void CleanUp()
	{
		fadeValue = 1;
		fadingIn = false;
		fadingOut = true;
	}
}
