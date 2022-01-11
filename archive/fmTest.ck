// synth def

// main osc
Blit osc => Envelope oscEnv => dac;


PulseOsc pulse => Envelope pulseEnv;
SinOsc mod => Envelope modEnv => Envelope carrEnv;

pulseEnv => carrEnv => oscEnv;

3 => oscEnv.op;
3 => carrEnv.op;
carrEnv.keyOn();



pulseEnv.keyOn();
oscEnv.keyOn();
1 => pulse.freq;


1 => osc.harmonics;
while ( true ) {
	<<< oscEnv.last() >>>;
	100::ms => now;
}