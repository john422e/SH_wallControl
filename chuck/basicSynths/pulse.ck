Blit carr => Envelope masterEnv => dac;
SinOsc mod => masterEnv;

// set to multiply mode
3 => masterEnv.op;

// set carr properties
440 => carr.freq;
1 => carr.harmonics; // make it a sine wave

// set mod freq
2.0 => mod.freq;

// turn everything on
masterEnv.keyOn();

repeat(5)
{
    1::second => now;
}

// turn everything off
masterEnv.keyOff();
1::second => now;