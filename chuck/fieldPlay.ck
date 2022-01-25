/*
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

1 => int running;
0 => int synthState;
2 => int numSynths;
int synth;
int seed;
[0, 0] @=> int randFilterUpdates[];
0 => int second_i;
20 => int eventInterval; // in seconds, CHANGE BACK TO 30! AFTER FINISHING SETTING
int eventTrigger;
// sensor vars
300.0 => float thresh;
10.0 => float distOffset;
float dist;
float amp;
float qVal;
0.2 => float minAmp;


// set these
10.0 => float ampScaler;
20.0 => float qScaler;

30 => int distSmoother;

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
  0.05 => comps[i].thresh;
  20.0 => comps[i].ratio;
}

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

// receiver function -> everything is triggered from this
fun void oscListener() {
  <<< "BUFFER SYNTHS LISTENING ON PORT:", port >>>;
  int bufNum;
  float gainFactor;
  while( true ) {
    in => now; // wait for a message
    while( in.recv(msg)) {
        
        // end program
        if( msg.address == "/endProgram") 0 => running;
        
        if( msg.address == "/bufSynthState" ) {
            
            // global synth state, arg = 0 or 1 for on/off
            msg.getInt(0) => synth;
            msg.getInt(1) => synthState;
            <<< "BUFF SYNTH STATE:", synthState >>>;
            if( synthState == 1 ) {
                <<< "BUFF SYNTH ON" >>>;
                // set to minAmp and turn on
                minAmp => bufEnvs[synth].target;
                bufEnvs[synth].keyOn();
            }
            else bufEnvs[synth].keyOff();
        }
        // only check for everything else if synthState is 1
        if( synthState ) {
            
            // all messages should have an address for event type
            // first arg should always be an int (0 or 1) specifying synth
            <<< msg.address >>>;
            msg.getInt(0) => synth;
            
            // buf init (read in file)
            if( msg.address == "/bufRead") readInFile(bufs[synth], msg.getString(1));
            
            // bufs on/off
            if( msg.address == "/bufOn") spork ~ bufPlayLoop( bufs[synth], bufEnvs[synth]); // start looping
            if( msg.address == "/bufOff") {
                <<< "BUFF OFF" >>>;
                0 => bufs[synth].loop;
                bufEnvs[synth].keyOff();
            }
            if( msg.address == "/randUpdates" ) {
                // address, synth, hostnum(0-7), state (0 or 1)
                // set state
                msg.getInt(1) => randFilterUpdates[synth]; // 0 or 1
                <<< "RAND UPDATES SET:", synth, randFilterUpdates[synth] >>>;
                msg.getInt(2) => seed;
                Math.srandom(seed);
                // if 1, do a change right away
                if( randFilterUpdates[synth] == 1) spork ~ bufChange(filters[synth], bufEnvs[synth]);
            }
            // gain
            if( msg.address == "/bufGain") msg.getFloat(1) => gains[synth].gain;
            // filter
            if( msg.address == "/bufFilterFreq") msg.getFloat(1) => filters[synth].freq;
            if( msg.address == "/bufFilterQ") msg.getFloat(1) => filters[synth].Q;
            // get sensor data
            if( msg.address == "/distance" ) {
                msg.getFloat(1) => dist;
                <<< "/distance", dist >>>;
                // turn on sound if value below thresh
                if( dist < thresh && dist > 0.0 ) {
                    
                    //normalize(dist, thresh+distSmoother, distOffset) * qScaler => filters[synth].Q;
                    normalize(dist, thresh+distSmoother, distOffset) * ampScaler => amp;
                    <<< "FIELD AMP", amp >>>;
                    amp => gains[synth].gain; // PROBABLY NEED TO SMOOTH THIS
                    //spork ~ gains[synth].keyOn();
                }
                else { // go to min amp val
                    //10.0 => filters[synth].Q;
                    minAmp => gains[synth].gains;
                    //spork ~ bufEnvs[synth].keyOn();
                }
            }
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
fun void bufChange( BPF bpf, Envelope env ) {
    <<< "CHANGING BPF STATE" >>>;
    // turn off
    env.keyOff();
    50::ms => now;
    // make sure Q is at a high value
    10.0 => bpf.Q;
    // pick random freq for BPF
    Math.random2f(100, 2000.0) => bpf.freq;
    // turn back on
    env.keyOn();
    50::ms => now;
}



spork ~ oscListener();

while( running ) {
    // check for update state on synth 1
    if( randFilterUpdates[0] && (second_i % eventInterval == 0) ) {
        Math.random2(0, 1) => eventTrigger;
        <<< "EVENT TRIGGER:", eventTrigger >>>;
        if( eventTrigger ) {
            spork ~ bufChange(filters[0], bufEnvs[0]);
        }
    }
    // check for update state on synth 2
    if( randFilterUpdates[1] && (second_i % eventInterval == 0) ) {
        Math.random2(0, 1) => eventTrigger;
        <<< "EVENT TRIGGER:", eventTrigger >>>;
        if( eventTrigger ) {
            spork ~ bufChange(filters[1], bufEnvs[1]);
        }
    }
    // advance time
    second_i++;
    1::second => now;
}
<<< "fieldPlay.ck stopping" >>>;
