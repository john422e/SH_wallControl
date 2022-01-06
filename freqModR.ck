// osc stuff
OscIn in;
OscMsg msg;

10003 => in.port;
in.listenAll();

// sound chain
SinOsc mod1 => Envelope sinMod => Envelope carrEnv => Envelope e;
PulseOsc mod2 => Envelope pulseMod => carrEnv => e;
// SinOsc carr => e => dac.right; // carrier
Noise carr => e => dac.right; // testing carrier as noise osc
3 => e.op; // multiply inputs
3 => carrEnv.op; // add inputs
carrEnv.keyOn();


// loop it
while (true) {
    in => now;
    while( in.recv(msg)) {
        // noteOn/noteOff messages
        if( msg.address == "/noteOn") e.keyOn();
        if( msg.address == "/noteOff") e.keyOff();
        // modulator on/offs
        if( msg.address == "/sinModOn") sinMod.keyOn();
        if( msg.address == "/sinModOff") sinMod.keyOff();
        if( msg.address == "/pulseModOn") pulseMod.keyOn();
        if( msg.address == "/pulseModOff") pulseMod.keyOff();
        // frequency of the modulator
        if( msg.address == "/modFreq") {
            msg.getFloat(0) => mod1.freq => mod2.freq;
            <<< "/modFreq", mod1.freq() >>>;
        }
        // phase of the modulator
        if( msg.address == "/mod1Phase") {
            msg.getFloat(0) => mod1.phase;
            <<< "/mod1Phase", mod1.phase() >>>;
        }
		// phase of the modulator
		if( msg.address == "/mod2Phase") {
			msg.getFloat(0) => mod2.phase;
			<<< "/mod2Phase", mod2.phase() >>>;
		}
        // frequency of the carrier
        if( msg.address == "/carrFreq") {
			<<< "noise instead of sin, testing " >>>;
            //msg.getFloat(0) => carr.freq;
            //<<< "/carrFreq", carr.freq() >>>;
        }
        // gain
        if( msg.address == "/gain") {
            msg.getFloat(0) => e.target;
            e.keyOn();
            <<< "/gain", e.target() >>>;
        }
    }
    1::samp => now;
}
