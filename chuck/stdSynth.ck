/*
for SH@theWende, 2022 - john eagle
2 synths (chan 1, 2) on each pi
*/

// -----------------------------------------------------------------------------
// GLOBALS
// -----------------------------------------------------------------------------
1 => int running;
0 => int synthState; // set to 0 when not using, 1 turns on
// sensor vars
150.0 => float thresh;
10.0 => float distOffset; // can set for each sensor if irregularities too much
float dist;
float amp;
0.2 => float minAmp; // for sound level when NOT boosted with sensor
30 => int distSmoother; // val to feed normalize because minAmp is > 0

//0 => distSmoother; // TROUBLESHOOTING

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

Blit synths[numSynths];
Envelope synthEnvs[numSynths];

// sound chains
for( 0 => int i; i < numSynths; i++ ) {
    // default to sine tone
    1 => synths[i].harmonics;
    //0.05 => synthEnvs[i].time; // TESTING
    synths[i] => synthEnvs[i] => dac.chan(i);
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

// receiver func
fun void oscListener() {
  <<< "SYNTHS LISTENING ON PORT:", IN_PORT >>>;
  int synth;
  while( true ) {
    in => now; // wait for a message
    while( in.recv(msg) ) {
      // global synth state, arg = 0 or 1 for on/off
      if( msg.address == "/stdSynthState" ) {
          msg.getInt(0) => synthState;
          <<< "STD SYNTH STATE:", synthState >>>;
          if( synthState == 1 ) {
              // set to minAmp and turn on
              minAmp => synthEnvs[synth].target;
              synthEnvs[synth].keyOn();
          }
          else synthEnvs[synth].keyOff();
      }
      if( synthState ) {
          // all messages should have an address for event type
          // first arg should always be an int (0 or 1) specifying synth
          //<<< msg.address >>>;
          msg.getInt(0) => synth;
          
          
          
          // individual synth on/off
          if( msg.address == "/synthOn") synthEnvs[synth].keyOn();
          if( msg.address == "/synthOff") synthEnvs[synth].keyOff();
          // synth freq/harmonics
          if( msg.address == "/synthFreq") msg.getFloat(1) => synths[synth].freq;
          if( msg.address == "/synthHarmonics") msg.getInt(1) => synths[synth].harmonics;
          // gain
          if( msg.address == "/synthGain") {
              msg.getFloat(1) => synthEnvs[synth].target;
              synthEnvs[synth].keyOn();
          }
          // end program
          if( msg.address == "/endProgram" ) 0 => running;
          
          // get sensor data
          if( msg.address == "/distance" ) {
              msg.getFloat(1) => dist;
              <<< "/distance", dist >>>;
              // turn on sound if value below thresh
              if( dist < thresh && dist > 0.0 ) {
                  normalize(dist, thresh+distSmoother, distOffset) => amp;
                  <<< "sensorAmp", amp >>>;
                  amp => synthEnvs[synth].target;
                  spork ~ synthEnvs[synth].keyOn();
              }
              else { // go to min amp val
                  minAmp => synthEnvs[synth].target;
                  spork ~ synthEnvs[synth].keyOn();
              }
          }
      }
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
<<< "stdSynth.ck stopping" >>>;