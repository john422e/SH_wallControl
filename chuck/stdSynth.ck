/*
for SH@theWende, 2022 - john eagle
2 synths (chan 1, 2) on each pi
*/

// -----------------------------------------------------------------------------
// OSC
// -----------------------------------------------------------------------------
OscIn in;
OscMsg msg;

10000 => in.port;
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
  synths[i] => synthEnvs[i] => dac.chan(i);
}

// -----------------------------------------------------------------------------
// RECEIVER FUNC
// -----------------------------------------------------------------------------
fun void oscListener() {
  <<< "SYNTHS LISTENING" >>>;
  int synth;
  while( true ) {
    in => now; // wait for a message
    while( in.recv(msg)) {
      // all messages should have an address for event type
      // first arg should always be an int (0 or 1) specifying synth
      <<< msg.address >>>;
      msg.getInt(0) => synth;

      // synth on/off
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
    }
  }
}

spork ~ oscListener();

while( true ) {
  1::samp => now;
}
