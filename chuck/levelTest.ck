/*
for SH@theWende, 2022 - john eagle
2 synths (chan 1, 2) on each pi
*/

// -----------------------------------------------------------------------------
// GLOBALS
// -----------------------------------------------------------------------------
0 => int synthState;


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
2 => int numSynths;
SinOsc synths[numSynths];
Envelope envs[numSynths];
for( 0 => int i; i < numSynths; i++ ) {
    synths[i] => envs[i] => dac.chan(i);
}

// -----------------------------------------------------------------------------
// RECEIVER FUNC
// -----------------------------------------------------------------------------
fun void oscListener() {
  <<< "SYNTHS LISTENING ON PORT:", port >>>;
  int synth;
  while( true ) {
    in => now; // wait for a message
    while( in.recv(msg)) {
      // all messages should have an address for event type
      // first arg should always be an int (0 or 1) specifying synth
      <<< msg.address >>>;
      msg.getInt(0) => synth;

      // synth on/off
      if( msg.address == "/synthOn") 1 => synthState;
      if( msg.address == "/synthOff") 0 => synthState;
      // synth freq
      if( msg.address == "/synthFreq") msg.getFloat(1) => synths[synth].freq;
      // gain
      if( msg.address == "/synthGain") msg.getFloat(1) => envs[synth].target;
    }
  }
}

spork ~ oscListener();

while( true ) {
    if( synthState ) {
         
        envs[0].keyOn();
        1::second => now;
        envs[0].keyOff();
        100::ms => now;
        envs[1].keyOn();
        1::second => now;
        envs[1].keyOff();
        2::second => now;
    }
    1::second => now;
  
}
