/*
alarmSynth.ck
for SH@theWende, 2022 - john eagle
1 synths (chan 2) on each pi
*/

// -----------------------------------------------------------------------------
// GLOBALS
// -----------------------------------------------------------------------------

1 => int running;
"alarmSynth.ck" => string fn;
// 0 or 1 for alarm on/off
int alarmState;

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
SawOsc sawSlow => Envelope envSlow => dac.chan(0);
SawOsc saw => Envelope env => dac.chan(1);
Phasor ramp => blackhole;
Phasor rampSlow => blackhole;

0.9 => dac.gain;

// set freq
440.0 => saw.freq;

// -----------------------------------------------------------------------------
// FUNCTIONS
// -----------------------------------------------------------------------------


fun void pulse(SawOsc s, Phasor p, Envelope e, float freq, float index, float pulseRate) {
    e.keyOn();
    pulseRate => p.freq;
    0.6 => env.target;
    while( alarmState ) {
        freq + (p.last() * index) => s.freq;
        1::samp => now;
    }
    e.keyOff();
}

// receiver func
fun void oscListener() {
    <<< fn, "ALARM LISTENING ON PORT:", IN_PORT >>>;
    int synth;
    while( running ) {
        in => now; // wait for a message
        while( in.recv(msg) ) {
            // alarm on/off
            if( msg.address == "/alarmOn") {
                1 => alarmState;
                msg.getFloat(1) => env.target;
                spork ~ pulse(saw, ramp, env, 440.0, 200.0, 2.0);
                spork ~ pulse(sawSlow, rampSlow, envSlow, 440.0, 300.0, 0.25);
            }
            if( msg.address == "/alarmOff") 0 => alarmState;
            // set alarm gain with float
            if( msg.address == "/alarmGain") msg.getFloat(1) => env.target;
            if( msg.address == "/masterGain") msg.getFloat(0) => dac.gain;
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
    1::second => now;
}

// turn everything off
env.keyOff();
<<< fn, "stopping" >>>;
1::second => now;