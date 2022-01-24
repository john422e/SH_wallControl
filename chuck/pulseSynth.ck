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

Blit carrs[numSynths];
SinOsc mods[numSynths];
Envelope envs[numSynths];

// sound chains
for( 0 => int i; i < numSynths; i++ ) {
    carrs[i] => envs[i] => dac.chan(i);
    mods[i] => envs[i];
    3 => envs[i].op;
    1 => carrs[i].harmonics; // default to sine wave
    1.0 => mods[i].freq; // default to 1 second pulse
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

      // carrOscs on/off
      if( msg.address == "/pulseOn") envs[synth].keyOn();
      if( msg.address == "/pulseOff") envs[synth].keyOff();
      // carrOsc freq/harmonics
      if( msg.address == "/carrFreq") msg.getFloat(1) => carrs[synth].freq;
      if( msg.address == "/carrHarmonics") msg.getInt(1) => carrs[synth].harmonics;
      // mod freq
      if( msg.address == "/modFreq") msg.getFloat(1) => mods[synth].freq;
      // gain
      if( msg.address == "/pulseGain") msg.getFloat(1) => envs[synth].target;
    }
  }
}

spork ~ oscListener();

while( true ) {
    1::day => now;
}
