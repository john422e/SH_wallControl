/*
for SH@theWende, 2022 - john eagle
1 synths (chan 2) on each pi
*/

// -----------------------------------------------------------------------------
// GLOBALS
// -----------------------------------------------------------------------------

1 => int running;
// 0 or 1 for alarm on/off
1 => int alarmState;

// -----------------------------------------------------------------------------
// OSC
// -----------------------------------------------------------------------------

OscIn in;
OscMsg msg;

10000 => int IN_PORT;
IN_PORT => in.port;
in.listenAll();

// -----------------------------------------------------------------------------
// AUDIO
// -----------------------------------------------------------------------------

// synth defs
SawOsc saw => Envelope env => dac.chan(1);
Phasor ramp => blackhole;

// set freq
440.0 => saw.freq;

// -----------------------------------------------------------------------------
// FUNCTIONS
// -----------------------------------------------------------------------------


fun void pulse(SawOsc s, Phasor p, Envelope e, float freq, float index, float pulseRate) {
    e.keyOn();
    pulseRate => p.freq;
    while( alarmState ) {
        freq + (p.last() * index) => s.freq;
        1::samp => now;
    }
    e.keyOff();
}

// receiver func
fun void oscListener() {
    <<< "ALARM LISTENING ON PORT:", IN_PORT >>>;
    int synth;
    while( running ) {
        in => now; // wait for a message
        while( in.recv(msg) ) {
            // alarm on/off
            if( msg.address == "/alarmOn") {
                1 => alarmState;
                spork ~ pulse(saw, ramp, env, 440.0, 200.0, 2.0);
            }
            if( msg.address == "/alarmOff") 0 => alarmState;
            // set alarm gain with float
            if( msg.address == "/alarmGain") msg.getFloat(1) => env.target;
            // end program
            if( msg.address == "/endProgram" ) 0 => running;
        }
    }
}

// -----------------------------------------------------------------------------
// MAIN LOOP
// -----------------------------------------------------------------------------


spork ~ oscListener();

while( running ) {
    1::samp => now;
}

// turn everything off
env.keyOff();
<<< "alarmSynth.ck stopping" >>>;
1::second => now;