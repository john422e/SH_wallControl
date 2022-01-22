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
me.dir() + "../audio/interiors/" => string audioDir;
[
  "3rd_floor_center_hall.wav",
  "3rd_floor_N_hall.wav",
  "3rd_floor_N.wav",
  "B27.wav",
  "south_stairs_1.wav",
  "south_stairs_2.wav",
  "south_stairs_3.wav",
  "south_stairs_B.wav"
] @=> string filenames[];
filenames.size() => int numBufs;

SndBuf bufs[numBufs];
Envelope bufEnvs[numBufs];
Dyno comps[numBufs];
BPF filters[numBufs];
Mix2 bufMixes[numBufs];
int bufLoops[numBufs];
[8.0, 8.0, 8.0, 13.0, 4.0, 8.0, 8.0, 4.0] @=> float bufGains[];

// sound chains
for( 0 => int i; i < numBufs; i++ ) {
  bufs[i] => bufEnvs[i] => comps[i] => filters[i] => bufMixes[i] => dac;
  // set filters
  filters[i].set(500.0, 0.58);
  comps[i].compress();
  0.05 => comps[i].thresh;
  20.0 => comps[i].ratio;
  //0.5 => comps[i].slopeAbove;
  bufGains[i] => comps[i].gain;
  //8 => comps[i].gain;
  comps[i].limit();
  // read in buffer
  audioDir + filenames[i] => bufs[i].read;
  // set bufLoop to 0
  0 => bufLoops[i];
  // set compressor settings

}

// -----------------------------------------------------------------------------
// FUNCTIONS
// -----------------------------------------------------------------------------
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
      msg.getInt(0) => bufNum;

      // bufs on/off
      if( msg.address == "/bufOn") {
          spork ~ bufPlayLoop( bufs[bufNum], bufEnvs[bufNum], bufNum);
          1 => bufLoops[bufNum];
      }
      if( msg.address == "/bufOff") {
          bufEnvs[bufNum].keyOff();
          0 => bufLoops[bufNum];
      }
      // gain
      if( msg.address == "/bufGain") {
        msg.getFloat(1) => gainFactor;
        <<< gainFactor * bufGains[bufNum], bufGains[bufNum] >>>;
        (gainFactor * bufGains[bufNum]) => bufEnvs[bufNum].target;
        bufEnvs[bufNum].keyOn();
      }
      // pan
      if( msg.address == "/bufPan") msg.getFloat(1) => bufMixes[bufNum].pan;
      // filter
      if( msg.address == "/bufFilterFreq") msg.getFloat(1) => filters[bufNum].freq;
      if( msg.address == "/bufFilterQ") msg.getFloat(1) => filters[bufNum].Q;
    }
  }
}

// loops a sound buff with smooth envelope
fun void bufPlayLoop( SndBuf buf, Envelope env, int loopIndex ) {
    // make sure buff will loop and starts at the beginning
    0 => buf.pos;
    1 => buf.loop;
    // track sample count
    0 => int sampCounter;
    // set env dur
    48 => int envDur;
    envDur::samp => env.duration;

    while( bufLoops[loopIndex] ) {
        // start buff
        env.keyOn();
        while( sampCounter < buf.samples() ) {
            if( sampCounter == buf.samples() - envDur ) env.keyOff();
            sampCounter++;
            1::samp => now;
        }
        0 => sampCounter;
    }
}

spork ~ oscListener();

while( true ) {
  1::second => now;
}
