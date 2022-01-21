SinOsc s => Envelope e1 => dac.chan(0);
SinOsc t => Envelope e2 => dac.chan(1);

0.5 => s.gain;
0.5 => t.gain;

440 => s.freq;
660 => t.freq;

repeat( 12 ) {
	e1.keyOn();
	1::second => now;
	e1.keyOff();
	e2.keyOn();
	1::second => now;
	e2.keyOff();
}
