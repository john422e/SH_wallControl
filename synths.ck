/*
for SH@theWende, 2022 - john eagle
2 synth defs on each pi
*/

// -----------------------------------------------------------------------------
// OSC
// -----------------------------------------------------------------------------
OscIn in;
OscMsg msg;

10002 => in.port;
in.listenAll();

// -----------------------------------------------------------------------------
// AUDIO
// -----------------------------------------------------------------------------
// synth defs
2 => int numSynths;

SinOsc mods[numSynths];
Envelope modEnvs[numSynths];
Envelope carrEnvs[numSynths];
Envelope masterEnvs[numSynths];
PulseOsc pulseOscs[numSynths];
Envelope pulseEnvs[numSynths];
Blit carrOscs[numSynths];

// sound chains
for( 0 => int i; i < numSynths; i++ ) {
  mods[i] => modEnvs[i] => carrEnvs[i] => masterEnvs[i];
  pulseOscs[i] => pulseEnvs[i] => carrEnvs[i] => masterEnvs[i];
  carrOscs[i] => masterEnvs[i] => dac.chan(i);
  3 => masterEnvs[i].op;
  3 => carrEnvs[i].op;
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
      if( msg.address == "/noteOn") masterEnvs[synth].keyOn();
      if( msg.address == "/noteOff") masterEnvs[synth].keyOff();
      if( msg.address == "/carrOn") carrEnv[synth].keyOn();
      if( msg.address == "/carrOff") carrEnv[synth].keyOff();
      // carrOsc freq/harmonics
      if( msg.address == "/carrFreq") msg.getFloat(1) => carrOscs[synth].freq;
      if( msg.address == "/harmonics") msg.getInt(1) => carrOscs[synth].harmonics;
      // modulator on/off ---- combine these?
      if( msg.address == "/modOn") modEnvs[synth].keyOn();
      if( msg.address == "/modOff") modEnvs[synth].keyOff();
      if( msg.address == "/pulseOn") pulseEnvs[synth].keyOn();
      if( msg.address == "/pulseOff") pulseEnvs[synth].keyOff();
      // mod freq
      if( msg.address == "/modFreq") msg.getFloat(1) => mods[synth].freq;
      if( msg.address == "/pulseFreq") msg.getFloat(1) => pulseOscs[synth].freq;
      if( msg.address == "/pulseWidth") msg.getFloat(1) => pulseOscs[synth].width;
      // gain
      if( msg.address == "/gain") {
        msg.getFloat(1) => masterEnvs[synth].target;
        masterEnvs[synth].keyOn();
      }
    }
  }
}

spork ~ oscListener();

while( true ) {
  1::samp => now;
}
