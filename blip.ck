SinOsc blip[16] => Pan2 p => dac;

fun void setFund ( float f, int harms ) {
	for( 1 => int i; i < 17; i++ ) {
		(f * i) => blip[i-1].freq;
		if( i <= harms ) {
			//( 1/i ) => blip[i-1].gain; // do the math in db then convert to gain
			Math.random2f(0.5, 1.0) => blip[i-1].gain;
		}
		else 0 => blip[i-1].gain;
		<<< blip[i-1].freq(), blip[i-1].gain() >>>;
	}
};


setFund(220.0, 10);

<<< blip[2].freq(), blip[2].gain() >>>;

//e.keyOn();
20::second => now;
