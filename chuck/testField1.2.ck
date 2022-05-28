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
20 => int eventInterval; // in seconds
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
Dyno limiters[numSynths];
BPF filters[numSynths];
Gain makeUpGains[numSynths];

// sound chains

// for sensor sound => add second dyno for limiting/compression or enveloper at end of sound chain to control input signal (side chain)


for( 0 => int i; i < numSynths; i++ ) {
  bufs[i] => bufEnvs[i] => filters[i] => makeUpGains[i] => limiters[i] => dac.chan(i);

  // crank the gain
  90.0 => makeUpGains[i].gain;
  // set filters
  filters[i].set(500.0, 0.58); // default filter settings (change freq?)
  // turn on limiter
  limiters[i].limit();
  0.8 => limiters[i].thresh;
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
    <<< fn, "RAND UPDATES SET:", synthNum, randFilterUpdates[synthNum] >>>;
    Math.srandom(seed); // set seed based on pi num
    // if 1, do a change right away

    // TRYING WITHOUT THIS, REENABLE IF TOO WEIRD

    if( randFilterUpdates[synthNum] == 1) spork ~ bufChange(filters[synthNum], bufEnvs[synthNum], makeUpGains[synthNum]);
}

fun void setValsFromDistance(float dist) {
    // NOT GONNA USE THIS FOR NOW
    <<< fn, "/distance", dist >>>;
    // sensor vars
    150.0 => float thresh;
    10.0 => float distOffset;
    float qVal;

    30 => int distSmoother; // val to feed normalize because minAmp is > 0

    // set these
    1.05 => float extBoost;
    20.0 => float ampScaler;
    15.0 => float qScaler; // NOT USING THIS RIGHT NOW


    // turn on sound if value below thresh
    if( dist < thresh && dist > 0.0 ) {
        normalize(dist, distOffset, thresh+distSmoother) * qScaler => qVal;
        <<< fn, "qVal", qVal >>>;
        (qVal+2) => filters[1].Q;
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
            //<<< fn, msg.address >>>;

            // buf init (read in file)
            if( msg.address == "/bufRead") readInFile(bufs[synth], msg.getString(1));

            // bufs on/off
            if( msg.address == "/bufOn") spork ~ bufPlayLoop( bufs[synth], bufEnvs[synth]); // start looping
            if( msg.address == "/bufOff") 0 => bufs[synth].loop;

            // set randUpdates on/off
            if( msg.address == "/randUpdates" ) setRandUpdates(synth, msg.getInt(1), msg.getInt(2));

            // gain
            if( msg.address == "/bufGain") msg.getFloat(1) => makeUpGains[synth].gain;

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
fun void bufChange( BPF bpf, Envelope env, Gain gain) {
    <<< "fieldPlay.ck CHANGING BPF STATE" >>>;
    
    float q;
    
    // turn off
    env.keyOff();
    50::ms => now;
    // make sure Q is at a high value
    Math.random2f(3.0, 12.0) => q;
    //10.0 => bpf.Q;
    q => bpf.Q;
    // pick random freq for BPF
    Math.random2f(250.0, 1000.0) => bpf.freq;
    5.0 => env.target;
    //1.25 => gain.gain;
    
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
    if( synthStates[0]) {
        // check for update state on synth 1
        if( randFilterUpdates[0] && (second_i % eventInterval == 0) ) {
            Math.random2(0, 1) => eventTrigger;
            <<< "fieldPlay.ck 0 EVENT TRIGGER:", eventTrigger >>>;
            if( eventTrigger ) {
                spork ~ bufChange(filters[0], bufEnvs[0], makeUpGains[0]); // higher Q for transducer
            }
        }
    }
    if( synthStates[1]) {
        // check for update state on synth 2
        if( randFilterUpdates[1] && (second_i % eventInterval == 0) ) {
            Math.random2(0, 1) => eventTrigger;
            <<< "fieldPlay.ck 1 EVENT TRIGGER:", eventTrigger >>>;
            if( eventTrigger ) {
                spork ~ bufChange(filters[1], bufEnvs[1], makeUpGains[1]); // lower Q for speaker
            }
        }
    }
    // advance time
    second_i++;
    1::second => now;
}
<<< "fieldPlay.ck stopping" >>>;
