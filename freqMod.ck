// osc stuff
OscIn in;
OscMsg msg;

10002 => in.port;
in.listenAll();

// sound chain
SinOsc mod1 => Envelope sinMod => Envelope carrEnv => Envelope e;
PulseOsc mod2 => Envelope pulseMod => carrEnv => e;
SinOsc carr => e => dac;
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
        if( msg.address == "/modPhase") {
            msg.getFloat(0) => mod1.phase;
            <<< "/modPhase", mod1.phase() >>>;
        }
        // frequency of the carrier
        if( msg.address == "/carrFreq") {
            msg.getFloat(0) => carr.freq;
            <<< "/carrFreq", carr.freq() >>>;
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
