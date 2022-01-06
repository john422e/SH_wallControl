/*
UGens:
Blit: 2 of them
SndBuf[]: field recordings
Step: live mic

OSC addresses:
/osc1 (or 2)/
 on
 off
 freq
 harmonics
 gain
 pan
 pulse 


*/

// sound chains
// oscs (set .harmonics to 1 for sine wave)
Blit osc1 => Envelope oscEnv1 => Pan2 oscPan1 => dac;
Blit osc2 => Envelope oscEnv2 => Pan2 oscPan2 => dac;
// buffers
[
"3rd_floor_center_hall.wav",
"3rd_floor_N_hall.wav"
] @=> string wavNames[];
SndBuf fieldRecs[wavNames.size()] => Envelope bufEnvs[wavNames.size()] => dac;

me.dir() + "audio/interiors/" => string audioDir;
for(0 => int i; i < wavNames.size(); i++ ) {
	// prepend audioDir
	audioDir + wavNames[i] => wavNames[i];
	// read in file
	wavNames[i] => fieldRecs[i].read;
}


1 => int bufLoop;

fun void bufPlayLoop( SndBuf buf, Envelope env ) {
	// make sure buff will loop and starts at the beginning
	0 => buf.pos;
	1 => buf.loop;
	// track sample count
	0 => int sampCounter;
	// set env dur
	48 => int envDur;
	envDur::samp => bufEnvs[0].duration;
	
	while( bufLoop ) {
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




1 => osc1.harmonics;

spork ~ bufPlayLoop( fieldRecs[0], bufEnvs[0] );


15::second => now;
0 => bufLoop;