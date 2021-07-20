(
o = ServerOptions.new;
o.protocol_(\tcp);
t = Server.remote(\piOne, NetAddr("pione.local", 57110), o);
t.addr.connect;
t.startAliveThread(0);
t.doWhenBooted( { "remote tcp server started".postln; t.notify; t.initTree });
)