(
o = ServerOptions.new;
o.protocol_(\tcp);
t = Server.remote(\piOne, NetAddr("eagle2018.local", 57110), o);
t.addr.connect;
t.startAliveThread(0);
t.doWhenBooted( { "remote tcp server started".postln; t.notify; t.initTree });
)

SynthDescLib.global.addServer(t);

(
SynthDef( \micOut, {
	arg out=0, gain=0.5;
	var sig;
	sig = SoundIn.ar([0, 0], gain);
	Out.ar(out, sig);
}).add;
)


x = Synth(\micOut, [\gain, 0.6]);
x.free;
t.plotTree;
t.freeAll;

{ SinOsc.ar(220, 0, 0.4) }.play;

s.plotTree;
