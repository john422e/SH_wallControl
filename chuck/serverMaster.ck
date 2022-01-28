<<< "ADDING ALL SYNTHS TO SERVER" >>>;
me.dir() => string dir;


<<< "STARTING SENSOR CONTROL" >>>;
// sensor control
Machine.add(dir + "sensorSender.ck");

<<< "STARTING PULSE SYNTH" >>>;
// pulse mode
Machine.add(dir + "pulseSynth.ck");

<<< "STARTING STD SYNTH" >>>;
// ternary code + pitch/blueprint mode
Machine.add(dir + "stdSynth.ck");

<<< "STARTING FIELDPLAY SYNTH" >>>;
// fieldplay mode
Machine.add(dir + "fieldPlay.ck");

<<< "STARTING FB SYNTH" >>>;
// FB mode
Machine.add(dir + "fbReceiverSynth.ck");

<<< "STARTING ALARM SYNTH" >>>;
// alarm mode
Machine.add(dir + "alarmSynth.ck");

1::second => now;