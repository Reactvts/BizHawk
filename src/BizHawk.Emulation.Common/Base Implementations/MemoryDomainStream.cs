using System;
using System.IO;
using BizHawk.Common;

namespace BizHawk.Emulation.Common
{
	public class MemoryDomainStream : Stream
	{
		public MemoryDomainStream(MemoryDomain d)
		{
			_d = d;
		}
		private readonly MemoryDomain _d;

		public override bool CanRead => true;

		public override bool CanSeek => true;

		public override bool CanWrite => _d.Writable;

		public override long Length => _d.Size;

		public override long Position { get; set; }

		public override void Flush()
		{
		}

		public override int ReadByte()
		{
			if (Position >= Length)
				return -1;
			return _d.PeekByte(Position++);
		}

		public override void WriteByte(byte value)
		{
			if (Position >= Length)
				throw new IOException("Can't resize stream");
			_d.PokeByte(Position++, value);
		}

		public override int Read(byte[] buffer, int offset, int count)
		{
			if (offset < 0 || offset + count > buffer.Length)
				throw new ArgumentOutOfRangeException("offset");
			count = (int)Math.Min(count, Length - Position);
			if (count == 0)
				return 0;
			// TODO: Memory domain doesn't have the overload we need :(
			var poop = new byte[count];
			// TODO: Range has the wrong end value
			_d.BulkPeekByte(new MutableRange<long>(Position, Position + count - 1), poop);
			Array.Copy(poop, 0, buffer, offset, count);
			Position += count;
			return count;
		}

		public override void Write(byte[] buffer, int offset, int count)
		{
			if (offset < 0 || offset + count > buffer.Length)
				throw new ArgumentOutOfRangeException("offset");
			for (var i = offset; i < offset + count; i++)
				_d.PokeByte(Position++, buffer[i]);
		}

		public override long Seek(long offset, SeekOrigin origin)
		{
			switch (origin)
			{
				case SeekOrigin.Begin:
					Position = offset;
					break;
				case SeekOrigin.Current:
					Position += offset;
					break;
				case SeekOrigin.End:
					Position = Length + offset;
					break;
				default:
					throw new ArgumentOutOfRangeException("origin");
			}
			return Position;
		}

		public override void SetLength(long value)
		{
			throw new NotSupportedException("Stream cannot be resized");
		}
	}
}
