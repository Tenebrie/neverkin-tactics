using Godot;
using System;

namespace Project;
public partial class RectDecal : MeshInstance3D
{
	bool fadingIn = true;
	bool fadingOut = false;

	float fadeValue = 0;
	public Action onFadedOut;

	public override void _Ready()
	{
		SetInstanceShaderParameter("FADE".ToStringName(), fadeValue);
	}

	public override void _Process(double delta)
	{
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

	public void CleanUp()
	{
		fadeValue = 1;
		fadingIn = false;
		fadingOut = true;
	}
}
