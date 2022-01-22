SawOsc saw => Envelope env => dac;
Phasor ramp => blackhole;

// 0 or 1 for alarm on/off
1 => int alarmState;

fun void pulse(SawOsc s, Phasor p, Envelope e, float freq, float index, float pulseRate) {
    e.keyOn();
    pulseRate => p.freq;
    while( alarmState ) {
        freq + (p.last() * index) => s.freq;
        1::samp => now;
    }
    e.keyOff();
}

// set freq
440.0 => saw.freq;

spork ~ pulse(saw, ramp, env, 440.0, 200.0, 2.0);

repeat(50)
{
    //<<< ramp.last() * 1000 >>>;
    100::ms => now;
}

// turn everything off
env.keyOff();
1::second => now;