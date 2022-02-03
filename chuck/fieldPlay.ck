/*
fieldPlay.ck
for SH@theWende, 2022 - john eagle
2 synths (chan 1, 2) on each pi
*/

/*
cassia channels:
1/2: Zoom, less active
3/4: Spot: L/R one area, more active
5/6: Spot: L/R one area, more active
*/





// -----------------------------------------------------------------------------
// GLOBALS
// -----------------------------------------------------------------------------

"fieldPlay.ck" => string fn;
1 => int running;
int synth;
0.9 => float minAmp;

// time/event tracking
0 => int second_i;
5 => int eventInterval; // in seconds
[0, 0] @=> int randFilterUpdates[];
int eventTrigger;


// -----------------------------------------------------------------------------
// OSC
// -----------------------------------------------------------------------------
OscIn in;
OscMsg msg;

10000 => int port;
port => in.port;
in.listenAll();

// -----------------------------------------------------------------------------
// AUDIO
// -----------------------------------------------------------------------------
// synth defs
2 => int numSynths;
int synthStates[numSynths]; // set to 0 when not using, 1 turns on

SndBuf bufs[numSynths];
Envelope bufEnvs[numSynths];
Dyno comps[numSynths];
BPF filters[numSynths];
Gain gains[numSynths];

// sound chains
for( 0 => int i; i < numSynths; i++ ) {
  bufs[i] => bufEnvs[i] => comps[i] => filters[i] => gains[i] => dac.chan(i);
  // set filters
  filters[i].set(500.0, 0.58); // default filter settings (change freq?)
  // set compressor settings
  comps[i].compress();
  0.7 => comps[i].thresh;
  20.0 => comps[i].ratio;
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

// readIn soundFile
fun void readInFile( SndBuf buf, string fn ) {
    (me.dir() + fn) => buf.read;
};

fun void setSynthState( int synthNum, int state ) {
    state => synthStates[synthNum];
    <<< fn, "BUF SYNTH STATES:", synthStates[0], synthStates[1] >>>;
    if( synthStates[synthNum] == 1) {
        // set to minAmp and turn on
        minAmp => bufEnvs[synthNum].target;
        bufEnvs[synthNum].keyOn();
    }
    else bufEnvs[synthNum].keyOff();
}

fun void setRandUpdates(int synthNum, int randState, int seed) {
    randState => randFilterUpdates[synthNum]; // 0 or 1
    <<< "fieldPlay.ck RAND UPDATES SET:", synthNum, randFilterUpdates[synthNum] >>>;
    Math.srandom(seed); // set seed based on pi num
    // if 1, do a change right away

    // TRYING WITHOUT THIS, REENABLE IF TOO WEIRD

    if( randFilterUpdates[synthNum] == 1) spork ~ bufChange(filters[synthNum], bufEnvs[synthNum], 5.0);
}

fun void setValsFromDistance(float dist) {
    <<< "fieldPlay.ck /distance", dist >>>;
    // sensor vars
    150.0 => float thresh;
    10.0 => float distOffset;
    float amp;
    float qVal;

    30 => int distSmoother; // val to feed normalize because minAmp is > 0

    // set these
    1.05 => float extBoost;
    20.0 => float ampScaler;
    2.0 => ampScaler; // TESTING
    15.0 => float qScaler; // NOT USING THIS RIGHT NOW


    // turn on sound if value below thresh
    if( dist < thresh && dist > 0.0 ) {
        normalize(dist, thresh+distSmoother, distOffset) * ampScaler => amp;
        <<< "fieldPlay.ck sensorAmp", amp >>>;
        // no synthNum comes in here, so have to check manually
        for( 0 => int i; i < numSynths; i++ ) {
            if( synthStates[i] == 1 ) {
                if( i == 1 ) {
                    // SET FOR EXTERIORS ONLY
                    //<<< "BEFORE AMP", amp >>>;
                    amp*extBoost => amp; // double the amp for the exterior sounds (speakers)
                    //<<< "TRIPLED AMP", amp >>>;
                    amp => gains[i].gain; // PROBABLY NEED TO SMOOTH THIS
                    //amp => filters[synth].gain;
                    amp => bufEnvs[i].target;
                    spork ~ bufEnvs[i].keyOn();
                }
                else {
                    // SET FOR INTERIORS ONLY
                    amp => gains[i].gain; // PROBABLY NEED TO SMOOTH THIS
                    //amp => filters[synth].gain;
                    amp => bufEnvs[i].target;
                    spork ~ bufEnvs[i].keyOn();
                }
            }
            else { // go to min amp val
                if( i == 1 ) {
                    // EXTERIORS ONLY
                    // double everything for exterior sounds (speakers)
                    //10.0 => filters[synth].Q;
                    (minAmp*extBoost) => gains[i].gain;
                    //minAmp => filters[synth].gain;
                    (minAmp*extBoost) => bufEnvs[i].target;
                }
                else {
                    // INTERIORS ONLY
                    minAmp => gains[i].gain;
                    //minAmp => filters[synth].gain;
                    minAmp => bufEnvs[i].target;
                    spork ~ bufEnvs[i].keyOn();
                }
            }
        }
    }
}

fun void endProgram() {
    <<< "fieldPlay.ck END PROGRAM" >>>;
    // ends loop and stops program
    0 => running;
}

// receiver function -> everything is triggered from this
fun void oscListener() {
  <<< "fieldPlay.ck BUFFER SYNTHS LISTENING ON PORT:", port >>>;

  while( true ) {
    in => now; // wait for a message
    while( in.recv(msg)) {

        // for every address but /distance, the first arg will be an int for the right synth number
        msg.getInt(0) => synth;

        // global synth state, arg = 0 or 1 for on/off
        if( msg.address == "/bufSynthState" ) setSynthState(synth, msg.getInt(1));
        
        if( msg.address == "/masterGain" ) msg.getFloat(0) => dac.gain;

        // end program
        if( msg.address == "/endProgram" ) endProgram();

        // ONLY CHECK IF SYNTH STATE IS ON
        if( synthStates[0] == 1 || synthStates[1] == 1 ) {
            // all messages should have an address for event type
            // first arg should always be an int (0 or 1) specifying synth
            <<< "fieldPlay.ck", msg.address >>>;

            // buf init (read in file)
            if( msg.address == "/bufRead") readInFile(bufs[synth], msg.getString(1));

            // bufs on/off
            if( msg.address == "/bufOn") spork ~ bufPlayLoop( bufs[synth], bufEnvs[synth]); // start looping
            if( msg.address == "/bufOff") 0 => bufs[synth].loop;

            // set randUpdates on/off
            if( msg.address == "/randUpdates" ) setRandUpdates(synth, msg.getInt(1), msg.getInt(2));

            // gain
            if( msg.address == "/bufGain") msg.getFloat(1) => gains[synth].gain;

            // filter
            if( msg.address == "/bufFilterFreq") msg.getFloat(1) => filters[synth].freq;
            if( msg.address == "/bufFilterQ") msg.getFloat(1) => filters[synth].Q;
            

            // get sensor data
            //if( msg.address == "/distance" ) setValsFromDistance(msg.getFloat(0));
        }
    }
  }
}

// loops a sound buff with smooth envelope
fun void bufPlayLoop( SndBuf buf, Envelope env ) {
    // make sure buff will loop and starts at the beginning
    0 => buf.pos;
    1 => buf.loop;
    // track sample count
    0 => int sampCounter;
    // set env dur
    48 => int envDur;
    envDur::samp => env.duration;

    while( buf.loop() ) {
        // start buff
        env.keyOn();
        while( (sampCounter < buf.samples()) && buf.loop() ) {
            if( sampCounter == buf.samples() - envDur ) env.keyOff();
            sampCounter++;
            1::samp => now;
        }
        0 => sampCounter;
    }
    // turn off when loop killed
    env.keyOff();
}

// initiate random change in BPF
fun void bufChange( BPF bpf, Envelope env, float q ) {
    <<< "fieldPlay.ck CHANGING BPF STATE" >>>;
    // turn off
    env.keyOff();
    50::ms => now;
    // make sure Q is at a high value
    //10.0 => bpf.Q;
    q => bpf.Q;
    // pick random freq for BPF
    Math.random2f(250.0, 1000.0) => bpf.freq;
    <<< bpf.freq(), bpf.Q() >>>;
    // turn back on
    env.keyOn();
    50::ms => now;
}

// -----------------------------------------------------------------------------
// MAIN LOOP
// -----------------------------------------------------------------------------

spork ~ oscListener();

while( running ) {
    // check for update state on synth 1
    if( randFilterUpdates[0] && (second_i % eventInterval == 0) ) {
        Math.random2(0, 1) => eventTrigger;
        <<< "fieldPlay.ck 0 EVENT TRIGGER:", eventTrigger >>>;
        if( eventTrigger ) {
            spork ~ bufChange(filters[0], bufEnvs[0], 10.0); // higher Q for transducer
        }
    }
    // check for update state on synth 2
    if( randFilterUpdates[1] && (second_i % eventInterval == 0) ) {
        Math.random2(0, 1) => eventTrigger;
        <<< "fieldPlay.ck 1 EVENT TRIGGER:", eventTrigger >>>;
        if( eventTrigger ) {
            spork ~ bufChange(filters[1], bufEnvs[1], 5.0); // lower Q for speaker
        }
    }
    // advance time
    second_i++;
    1::second => now;
}
<<< "fieldPlay.ck stopping" >>>;
