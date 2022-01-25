me.dir() => string dir;


<<< "STARTING SENSOR CONTROL" >>>;
// sensor control
//Machine.add(dir + "templates/sensorSender.ck");

<<< "STARTING STD SYNTH" >>>;
// ternary code
Machine.add(dir + "stdSynth.ck");

// pitch/blueprint mode

<<< "STARTING PULSE SYNTH" >>>;
// pulse mode
Machine.add(dir + "pulseSynth.ck");

<<< "STARTING ALARM SYNTH" >>>;
// alarm mode
Machine.add(dir + "alarmSynth.ck");

<<< "STARTING FIELDPLAY SYNTH" >>>;
// fieldplay mode
Machine.add(dir + "fieldPlay.ck");

1::second => now;


// need to:
// fix sensor stuff
// add sensor fetching to fieldplay
// make pitch/blueprint mode
// make feedback mode