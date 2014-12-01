﻿using BizHawk.Emulation.Common;

namespace BizHawk.Emulation.Cores.Atari.Atari7800
{
	public partial class Atari7800 : IInputPollable
	{
		public int LagCount
		{
			get { return _lagcount; }
			set { _lagcount = value; }
		}

		public bool IsLagFrame
		{
			get { return _islag; }
		}

		private bool _islag = true;
		private int _lagcount;
	}
}
