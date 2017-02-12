public class IVala.Kernel : GLib.Object
{
	public InetAddress ip { construct; get; }

	public uint control_port { construct; get; }

	public uint shell_port { construct; get; }

	public uint stdin_port { construct; get; }

	public uint hb_port { construct; get; }

	public uint iopub_port { construct; get; }

	public string signature_scheme { construct; get; }

	public string key { construct; get; }

	/* ZeroMQ stuff */
	private ZMQ.Context context;
	private ZMQ.Socket  control_socket;
	private ZMQ.Socket  shell_socket;
	private ZMQ.Socket  iopub_socket;
	private ZMQ.Socket  stdin_socket;
	private ZMQ.Socket  hb_socket;

	public Kernel.from_connection_file (GLib.File connection_file) throws Error
	{
		// TODO
	}

	construct
	{
		context = new ZMQ.Context ();

		control_socket = ZMQ.Socket.create (context, ZMQ.SocketType.ROUTER);
		shell_socket   = ZMQ.Socket.create (context, ZMQ.SocketType.ROUTER);
		stdin_socket   = ZMQ.Socket.create (context, ZMQ.SocketType.ROUTER);
		hb_socket      = ZMQ.Socket.create (context, ZMQ.SocketType.ROUTER);
		iopub_socket   = ZMQ.Socket.create (context, ZMQ.SocketType.ROUTER);
	}

	private size_t _started = 0;

	public void start () throws Error
	{
		if (GLib.Once.init_enter (&_started))
		{
			control_socket.bind (new InetSocketAddress (ip, (uint16) control_port).to_string ());
			shell_socket.bind (new InetSocketAddress (ip, (uint16) shell_port).to_string ());
			stdin_socket.bind (new InetSocketAddress (ip, (uint16) stdin_port).to_string ());
			hb_socket.bind (new InetSocketAddress (ip, (uint16) hb_port).to_string ());
			iopub_socket.bind (new InetSocketAddress (ip, (uint16) iopub_port).to_string ());

			/* start loops */
			control_loop.begin ();
			shell_loop.begin ();
			hb_loop.begin ();

			Once.init_leave (&_started, 1);
		}
		else
		{
			warning ("The kernel has already been started.");
		}
	}

	private class ZMQSocketSource : Source
	{
		public ZMQ.PollItem poll_item;

		public ZMQSocketSource (ZMQ.Socket socket, short poll_events)
		{
			poll_item = ZMQ.PollItem () {socket = socket, events = poll_events};
			int fd = -1;
			size_t fd_len = sizeof (int);
			socket.getsockopt (ZMQ.SocketOption.FD, &fd, ref fd_len);
			/* in edge-triggered mode, it's a pre-condition to have something on the socket first */
			GLib.IOCondition io_conditions = 0;
			if (ZMQ.PollEvents.IN in poll_events) {
				add_unix_fd (fd, GLib.IOCondition.IN);
			}
			if (ZMQ.PollEvents.OUT in poll_events) {
				add_unix_fd (fd, GLib.IOCondition.OUT);
			}
			if (ZMQ.PollEvents.ERR in poll_events) {
				add_unix_fd (fd, GLib.IOCondition.ERR);
			}
			add_unix_fd (fd, io_conditions);
		}

		public override bool prepare (out int timeout)
		{
			timeout = 10;
			return false;
		}

		public override bool check ()
		{
			ZMQ.poll ({poll_item}, 0);
			return poll_item.events in poll_item.revents;
		}

		public override bool dispatch (SourceFunc callback)
		{
			return callback ();
		}
	}

	private async ZMQ.Message receive_message_from_socket_async (ZMQ.Socket socket) throws Error
	{
		var message = ZMQ.Message ();
		var source = new ZMQSocketSource (socket, ZMQ.PollEvents.IN);
		source.set_callback (receive_message_from_socket_async.callback);
		source.attach (GLib.MainContext.@default ());
		yield;
		socket.recvmsg (ref message);
		return (owned) message;
	}

	private async void send_message_on_socket_async (ZMQ.Socket socket, owned ZMQ.Message message) throws Error
	{
		var source = new ZMQSocketSource (socket, ZMQ.PollEvents.OUT);
		source.set_callback (send_message_on_socket_async.callback);
		source.attach (GLib.MainContext.@default ());
		yield;
		socket.sendmsg (ref message);
	}

	private async void control_loop ()
	{
		while (true)
		{
			var message = yield receive_message_from_socket_async (control_socket);
		}
	}

	private async void shell_loop ()
	{
		while (true)
		{
			var message = yield receive_message_from_socket_async (control_socket);
		}
	}

	private async void hb_loop ()
	{
		while (true)
		{
			var message = yield receive_message_from_socket_async (control_socket);
		}
	}
}
