me.dir() => string dir;

// sensor control
Machine.add(dir + "templates/sensorSender.ck");

// ternary code
Machine.add(dir + "stdSynth.ck");

// pitch/blueprint mode

// pulse mode
Machine.add(dir + "pulseSynth.ck");

// alarm mode
Machine.add(dir + "alarmSynth.ck");

// fieldplay mode
Machine.add(dir + "fieldPlay.ck");

//1::day => now;


// need to:
// fix sensor stuff
// add sensor fetching to fieldplay
// make pitch/blueprint mode
// make feedback mode