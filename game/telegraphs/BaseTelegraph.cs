using System;
using System.Collections.Generic;
using System.Linq;
using Godot;

namespace Project;

public abstract partial class BaseTelegraph : Node3D
{
	private bool autoCleaning = true;
	private bool periodic;
	private Action<BaseUnit> onTargetEntered = null;
	private Action onFinishedCallback = null;
	private Func<BaseUnit, bool> targetValidator = null;
	private Action<BaseUnit> onFinishedPerTargetCallback = null;

	public class TelegraphSettings
	{
		public BaseTelegraph Parent;
		public TelegraphSettings(BaseTelegraph parent)
		{
			Parent = parent;
		}

		public bool AutoCleaning
		{
			get => Parent.autoCleaning;
			set => Parent.autoCleaning = value;
		}

		public bool Periodic
		{
			get => Parent.periodic;
			set => Parent.periodic = value;
		}

		public UnitAlliance Alliance
		{
			get => Parent.alliance;
			set
			{
				Parent.alliance = value;
				Parent.UpdateColor();
			}
		}

		public float GrowTime
		{
			get => Parent.growTime;
			set
			{
				Parent.growTime = value;
				Parent.finishesAt = Parent.createdAt + Music.Singleton.SecondsPerBeat * value * 1000;
			}
		}

		public Action<BaseUnit> OnTargetEntered
		{
			get => Parent.onTargetEntered;
			set => Parent.onTargetEntered = value;
		}
		public Action OnFinishedCallback
		{
			get => Parent.onFinishedCallback;
			set => Parent.onFinishedCallback = value;
		}
		public Func<BaseUnit, bool> TargetValidator
		{
			get => Parent.targetValidator;
			set => Parent.targetValidator = value;
		}
		public Action<BaseUnit> OnFinishedPerTargetCallback
		{
			get => Parent.onFinishedPerTargetCallback;
			set => Parent.onFinishedPerTargetCallback = value;
		}
	}

	protected double createdAt;
	protected double finishesAt;
	protected bool endReached;
	protected bool cleaningUp;
	readonly List<BaseUnit> targets = new();

	protected float GrowPercentage;

	protected UnitAlliance alliance = UnitAlliance.Hostile;
	private float growTime = 1; // beats

	private readonly TelegraphSettings settings;
	public virtual TelegraphSettings Settings => settings;

	public BaseTelegraph()
	{
		settings = new(this);
	}

	public override void _Ready()
	{
		finishesAt = createdAt + Music.Singleton.SecondsPerBeat * growTime * 1000;
		UpdateColor();
	}

	public override void _Process(double delta)
	{
		var time = (double)Time.GetTicksMsec();
		GrowPercentage = (float)Math.Min(1, (time - createdAt) / (finishesAt - createdAt));

		if (GrowPercentage >= 1 && !endReached)
		{
			endReached = true;
			try
			{
				onFinishedCallback?.Invoke();
				if (onFinishedPerTargetCallback != null)
				{
					foreach (var target in GetTargets())
						onFinishedPerTargetCallback(target);
				}
			}
			catch (Exception ex) { GD.PrintErr(ex); }

			if (!Settings.Periodic && Settings.AutoCleaning)
				CleanUp();
		}
	}

	protected void OnBodyEntered(Node3D body)
	{
		if (body is not BaseUnit unit)
			return;

		targets.Add(unit);
		try
		{
			if (targetValidator == null || targetValidator(unit))
				onTargetEntered?.Invoke(unit);
		}
		catch (Exception ex)
		{
			GD.PrintErr(ex);
		}
	}

	protected void OnBodyExited(Node3D body)
	{
		if (body is not BaseUnit unit)
			return;

		targets.Remove(unit);
	}

	void UpdateColor()
	{
		SetColor(CastUtils.GetAllianceColor(alliance));
	}

	public List<BaseUnit> GetTargets()
	{
		return targets.Distinct().Where(target => target != null && IsInstanceValid(target) && targetValidator == null || targetValidator(target)).ToList();
	}

	public void SnapToGround()
	{
		GlobalPosition = CastUtils.SnapToGround(this, GlobalPosition);
	}

	protected abstract void SetColor(Color color);

	public virtual void CleanUp()
	{
		QueueFree();
	}
}