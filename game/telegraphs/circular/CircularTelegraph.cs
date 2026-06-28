using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Linq;
using Godot;
using Project;

namespace Project;
public partial class CircularTelegraph : BaseTelegraph
{
	private CircleDecal decal;
	private Area3D hitbox;

	private float radius = .5f;
	public new TelegraphSettings Settings;
	public new class TelegraphSettings : BaseTelegraph.TelegraphSettings
	{
		public new CircularTelegraph Parent;
		public TelegraphSettings(CircularTelegraph parent) : base(parent)
		{
			Parent = parent;
		}

		public float Radius
		{
			get => Parent.radius;
			set
			{
				Parent.radius = value;
				Parent.UpdateRadius();
			}
		}
	}

	public CircularTelegraph()
	{
		createdAt = Time.GetTicksMsec();
		Settings = new(this);
	}

	public override void _EnterTree()
	{
		hitbox = GetNode<Area3D>("Hitbox");
		decal = GetNode<CircleDecal>("CircleDecal");

		hitbox.BodyEntered += OnBodyEntered;
		hitbox.BodyExited += OnBodyExited;

		base._EnterTree();
	}

	public override void _ExitTree()
	{
		hitbox.BodyEntered -= OnBodyEntered;
		hitbox.BodyExited -= OnBodyExited;

		base._ExitTree();
	}

	public override void _Process(double delta)
	{
		base._Process(delta);
		decal.SetInstanceShaderParameter("PROGRESS".ToStringName(), GrowPercentage);
	}

	private void UpdateRadius()
	{
		hitbox.Scale = new Vector3(radius * 2, radius * 2, radius * 2);
		decal.Radius = radius;
	}

	protected override void SetColor(Color color)
	{
		decal.SetInstanceShaderParameter("COLOR_R".ToStringName(), color.R);
		decal.SetInstanceShaderParameter("COLOR_G".ToStringName(), color.G);
		decal.SetInstanceShaderParameter("COLOR_B".ToStringName(), color.B);
	}

	public void EnableCulling()
	{
		decal.EnableCulling();
	}

	public override void CleanUp()
	{
		decal.CleanUp();
		decal.onFadedOut = () => base.CleanUp();
	}
}
