SinOsc s => Envelope e1 => dac.left;
SinOsc t => Envelope e2 => dac.right;

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