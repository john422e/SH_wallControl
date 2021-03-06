/*
stdSynth.ck
runs ternary code and room pitch/blueprint mode
for SH@theWende, 2022 - john eagle
2 synths (chan 1, 2) on each pi
*/

// -----------------------------------------------------------------------------
// GLOBALS
// -----------------------------------------------------------------------------
1 => int running;
"stdSynth.ck" => string fn;
int synth;
0.2 => float minAmp; // for sound level when NOT boosted with sensor

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
2 => int numSynths;
int synthStates[numSynths]; // set to 0 when not using, 1 turns on

Blit synths[numSynths];
Envelope synthEnvs[numSynths];

// sound chains
for( 0 => int i; i < numSynths; i++ ) {
    // default to OFF
    0 => synthStates[i];
    // default to sine tone
    1 => synths[i].harmonics;
    synths[i] => synthEnvs[i] => dac.chan(i);
}

0.9 => dac.gain;

// -----------------------------------------------------------------------------
// FUNCTIONS
// -----------------------------------------------------------------------------

// for normalizing sensor data range
fun float normalize( float inVal, float x1, float x2 ) {
    /*
    for standard mapping:
    x1 = min, x2 = max
    inverted mapping:
    x2 = min, x1 = max
    */
    // catch out of range numbers and cap
    // for inverted ranges
    if( x1 > x2 ) { 
        if( inVal < x2 ) x2 => inVal;
        if( inVal > x1 ) x1 => inVal;
    }
    // normal mapping
    else {
        if( inVal < x1 ) x1 => inVal;
        if( inVal > x2 ) x2 => inVal;
    }
    (inVal-x1) / (x2-x1) => float outVal;
    return outVal;
}

fun void setSynthState( int synthNum, int state ) {
    state => synthStates[synthNum];
    <<< fn, "STD SYNTH STATES:", synthStates[0], synthStates[1] >>>;
    if( synthStates[synthNum] == 1) {
        // set to minAmp and turn on
        minAmp => synthEnvs[synthNum].target;
        synthEnvs[synthNum].keyOn();
    }
    else synthEnvs[synthNum].keyOff();
}

fun void setSynthGain( float amp, int synthNum ) {
    amp => synthEnvs[synthNum].target;
    synthEnvs[synthNum].keyOn();
}

fun void setAmpFromDistance(float dist) {
    //<<< "stdSynth.ck /distance", dist >>>;
    // sensor vars
    
    100.0 => float thresh;
    10.0 => float distOffset; // can set for each sensor if irregularities too much
    float amp;
    
    30 => int distSmoother; // val to feed normalize because minAmp is > 0
    
    
    // turn on sound if value below thresh
    if( dist < thresh && dist > 0.0 ) {
        normalize(dist, thresh+distSmoother, distOffset) => amp;
        <<< fn, "sensorAmp", amp >>>;
        // no synthNum comes in here, so have to check manually
        for( 0 => int i; i < numSynths; i++ ) {
            if( synthStates[i] == 1 ) {
                if( i == 0 ) amp*1.5 => amp; // only for transducers, double amp
                (amp*0.9) => synthEnvs[i].target;
                spork ~ synthEnvs[i].keyOn();
            }
            else synthEnvs[i].keyOff(); // turn off
        }
    }
    else { // go to min amp val
        for( 0 => int i; i < numSynths; i++ ) {
            if( synthStates[i] == 1 ) {
                minAmp => synthEnvs[i].target;
                spork ~ synthEnvs[i].keyOn();
            }
            else synthEnvs[i].keyOff();
        }
    }
}

fun void endProgram() {
    <<< fn, "END PROGRAM" >>>;
    // ends loop and stops program
    0 => running;
}
    

// receiver func
fun void oscListener() {
  <<< fn, "SYNTHS LISTENING ON PORT:", IN_PORT >>>;
  
  while( true ) {
    in => now; // wait for a message
    while( in.recv(msg) ) {
        //<<< "stdSynth.ck", msg.address >>>;
        // for every address but /distance, the first arg will be an int for the right synth number 
        msg.getInt(0) => synth;
        
        // global synth state, arg = 0 or 1 for on/off
        if( msg.address == "/stdSynthState" ) setSynthState(synth, msg.getInt(1));
        
        // end program
        if( msg.address == "/endProgram" ) endProgram();
        
        // master gain
        if( msg.address == "/masterGain" ) msg.getFloat(0) => dac.gain;
        
        // ONLY CHECK IF SYNTH STATE IS ON
        if( synthStates[0] == 1 || synthStates[1] == 1 ) {
            // all messages should have an address for event type
            // first arg should always be an int (0 or 1) specifying synth, except for /distance
            //<<< "stdSynth.ck", msg.address >>>;
            
            // individual synth on/off
            if( msg.address == "/synthOn") synthEnvs[synth].keyOn();
            if( msg.address == "/synthOff") synthEnvs[synth].keyOff();
            // synth freq/harmonics
            if( msg.address == "/synthFreq") msg.getFloat(1) => synths[synth].freq;
            if( msg.address == "/synthHarmonics") msg.getInt(1) => synths[synth].harmonics;
            // gain
            if( msg.address == "/synthGain") setSynthGain(msg.getFloat(1), synth);
            // get sensor data
            if( msg.address == "/distance" ) setAmpFromDistance(msg.getFloat(0)); 
        }
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
<<< "stdSynth.ck stopping" >>>;