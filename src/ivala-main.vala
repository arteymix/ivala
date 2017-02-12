namespace IVala
{
	public int main ()
	{
		var kernel = GLib.Object.@new (typeof (IVala.Kernel),
		                               ip:               new GLib.InetAddress.loopback (GLib.SocketFamily.IPV4),
		                               control_port:     50160,
		                               shell_port:       57503,
		                               stdin_port:       52597,
		                               hb_port:          42540,
		                               iopub_port:       40885,
		                               signature_scheme: "hmac-sha256",
		                               key:              "a0436f6c-1916-498b-8eb9-e81ab9368e84") as IVala.Kernel;

		kernel.start ();

		new GLib.MainLoop ().run ();

		return 0;
	}
}
