(

r.options.protocol = \tcp;
r.options.bindAddress = "0.0.0.0";
r.options.maxLogins = 2;

r = Server.new(\piOne, NetAddr("pione.local", 57110), r.options);

r.boot;
)
