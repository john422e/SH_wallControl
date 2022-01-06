// receiver.ck
// Eric Heep

// osc stuff
OscIn in;
OscMsg msg;

10002 => in.port;
in.listenAll();

// sine tones
SinOsc sin => dac;
sin.gain(0.0);
sin.freq(1.0);

Step st => Gain stGain => dac;

0.001 => float gainInc;
0.0 => float targetGain;

fun void easeGain() {
    while (true) {
        if (sin.gain() < targetGain - gainInc) {
            sin.gain() + gainInc => sin.gain;
        }
        else if (sin.gain() > targetGain + gainInc) {
            sin.gain() - gainInc => sin.gain;
        }
        1::ms => now;
    }
}

spork ~ easeGain();

// loop it
while (true) {
    in => now;
    while (in.recv(msg)) {
        // frequency of the sine tone
        if (msg.address == "/sineFreq") {
            msg.getFloat(0) => sin.freq;
            <<< "/sineFreq", sin.freq() >>>;
        }
        // gain of the sine tone
        if (msg.address == "/sineGain") {
            msg.getFloat(0) => targetGain;
            <<< "/sineGain", targetGain >>>;
        }
        // phase
        if (msg.address == "/sinePhase") {
            msg.getFloat(0) => sin.phase;
            <<< "/sinePhase", sin.phase() >>>;
        }
    }
    1::samp => now;
}