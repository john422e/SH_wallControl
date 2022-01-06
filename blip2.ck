Blit s => Envelope e => JCRev r => dac;

.5 => s.gain;
.5 => r.mix;


while( true ) {
	Math.random2(110, 330) => s.freq;
	Math.random2(1, 8) => s.harmonics;
	
	e.keyOn();
	2::second => now;
	e.keyOff();
	0.25::second => now;
}