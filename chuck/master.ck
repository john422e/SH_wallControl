me.dir() + "synth1.ck" => string subPatch;

<<< subPatch >>>;

Machine.add( subPatch );

2::second => now;
env.keyOn();
2::second => now;
env.keyOff();
2::second => now;