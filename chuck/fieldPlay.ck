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

2 => int numSynths;
[0, 0] @=> int randFilterUpdates[];
0 => int second_i;
20 => int eventInterval; // in seconds, CHANGE BACK TO 30! AFTER FINISHING SETTING
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
      // all messages should have an address for event type
      // first arg should always be an int (0 or 1) specifying synth
      <<< msg.address >>>;
      msg.getInt(0) => int synth;
      
      // buf init (read in file)
      if( msg.address == "/bufRead") readInFile(bufs[synth], msg.getString(1));

      // bufs on/off
      if( msg.address == "/bufOn") spork ~ bufPlayLoop( bufs[synth], bufEnvs[synth]); // start looping
      if( msg.address == "/bufOff") {
          0 => bufs[synth].loop;
          bufEnvs[synth].keyOff();
      }
      
      // 
      if( msg.address == "/randUpdates" ) msg.getInt(1) => randFilterUpdates[synth]; // 0 or 1

      // gain
      if( msg.address == "/bufGain") msg.getFloat(1) => gains[synth].gain;
      // filter
      if( msg.address == "/bufFilterFreq") msg.getFloat(1) => filters[synth].freq;
      if( msg.address == "/bufFilterQ") msg.getFloat(1) => filters[synth].Q;
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

while( true ) {
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
