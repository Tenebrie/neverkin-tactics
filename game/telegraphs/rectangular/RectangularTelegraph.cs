using System;
using System.Collections.Generic;
using System.Linq;
using Godot;

namespace Project;
public partial class RectangularTelegraph : BaseTelegraph
{
	private RectDecal decal;
	private Area3D hitbox;
	private CollisionShape3D collisionShape;

	private float width = 1;
	private float length = 1;
	private float height = 2;
	private float rotation = 0;
	private Origin lengthOrigin = Origin.Center;

	public new TelegraphSettings Settings;
	public new class TelegraphSettings : BaseTelegraph.TelegraphSettings
	{
		public new RectangularTelegraph Parent;
		public TelegraphSettings(RectangularTelegraph parent) : base(parent)
		{
			Parent = parent;
		}

		public float Width
		{
			get => Parent.width;
			set
			{
				Parent.width = value;
				Parent.UpdateSize();
			}
		}

		public float Length
		{
			get => Parent.length;
			set
			{
				Parent.length = value;
				Parent.UpdateSize();
			}
		}

		public float Height
		{
			get => Parent.height;
			set
			{
				Parent.height = value;
				Parent.UpdateSize();
			}
		}

		public Origin LengthOrigin
		{
			get => Parent.lengthOrigin;
			set
			{
				Parent.lengthOrigin = value;
				// TODO: Make that work properly
				var decalPos = Parent.decal.Position;
				var collisionShapePos = Parent.collisionShape.Position;
				if (value == Origin.Start)
				{
					Parent.decal.Position = new Vector3(decalPos.X, decalPos.Y, decalPos.Z - Length / 2);
					Parent.collisionShape.Position = new Vector3(collisionShapePos.X, collisionShapePos.Y, collisionShapePos.Z - Length / 2);
				}
			}
		}
	}

	public RectangularTelegraph()
	{
		createdAt = Time.GetTicksMsec();
		Settings = new(this);
	}

	public override void _EnterTree()
	{
		hitbox = GetNode<Area3D>("Hitbox");
		decal = GetNode<RectDecal>("RectDecal");
		collisionShape = GetNode<CollisionShape3D>("Hitbox/CollisionShape3D");
		collisionShape.Shape = (Shape3D)collisionShape.Shape.Duplicate();

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

	private void UpdateSize()
	{
		// Scale = new Vector3(width * 2, 1, length * 2);
		(decal.Mesh as PlaneMesh).Size = new Vector2(32, 32);
		(collisionShape.Shape as BoxShape3D).Size = new Vector3(width, height, length);
		decal.SetInstanceShaderParameter("SIZE_X".ToStringName(), width / 2);
		decal.SetInstanceShaderParameter("SIZE_Z".ToStringName(), length / 2);
	}

	public void SetHeight(float value)
	{
		height = value;
		UpdateSize();
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

	// public static bool IsPointInsideRectangle(Vector3 pt, Vector3 A, Vector3 B, Vector3 C, Vector3 D)
	// {
	// 	double x1 = A.X;
	// 	double x2 = B.X;
	// 	double x3 = C.X;
	// 	double x4 = D.X;

	// 	double y1 = A.Z;
	// 	double y2 = B.Z;
	// 	double y3 = C.Z;
	// 	double y4 = D.Z;

	// 	double a1 = Math.Sqrt((x1 - x2) * (x1 - x2) + (y1 - y2) * (y1 - y2));
	// 	double a2 = Math.Sqrt((x2 - x3) * (x2 - x3) + (y2 - y3) * (y2 - y3));
	// 	double a3 = Math.Sqrt((x3 - x4) * (x3 - x4) + (y3 - y4) * (y3 - y4));
	// 	double a4 = Math.Sqrt((x4 - x1) * (x4 - x1) + (y4 - y1) * (y4 - y1));

	// 	double b1 = Math.Sqrt((x1 - pt.X) * (x1 - pt.X) + (y1 - pt.Z) * (y1 - pt.Z));
	// 	double b2 = Math.Sqrt((x2 - pt.X) * (x2 - pt.X) + (y2 - pt.Z) * (y2 - pt.Z));
	// 	double b3 = Math.Sqrt((x3 - pt.X) * (x3 - pt.X) + (y3 - pt.Z) * (y3 - pt.Z));
	// 	double b4 = Math.Sqrt((x4 - pt.X) * (x4 - pt.X) + (y4 - pt.Z) * (y4 - pt.Z));

	// 	double u1 = (a1 + b1 + b2) / 2;
	// 	double u2 = (a2 + b2 + b3) / 2;
	// 	double u3 = (a3 + b3 + b4) / 2;
	// 	double u4 = (a4 + b4 + b1) / 2;

	// 	double A1 = Math.Sqrt(u1 * (u1 - a1) * (u1 - b1) * (u1 - b2));
	// 	double A2 = Math.Sqrt(u2 * (u2 - a2) * (u2 - b2) * (u2 - b3));
	// 	double A3 = Math.Sqrt(u3 * (u3 - a3) * (u3 - b3) * (u3 - b4));
	// 	double A4 = Math.Sqrt(u4 * (u4 - a4) * (u4 - b4) * (u4 - b1));

	// 	double difference = A1 + A2 + A3 + A4 - a1 * a2;
	// 	return difference < 1;
	// }

	public enum Origin
	{
		Center,
		Start,
	}
}
