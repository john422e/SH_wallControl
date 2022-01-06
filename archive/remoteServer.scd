(
~hostname = "pione.local";
~hostname = "eagle2018.local";

//r = ServerOptions.new;

s.options.protocol = \tcp;
s.options.bindAddress = "0.0.0.0";
s.options.maxLogins = 2;

r = Server.new(
	\piOne,
	NetAddr(~hostname, 57110),
	s.options);

r.boot;
)
