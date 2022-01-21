//-----------------------------------------------------------------------------------
// MODE FUNCTIONS
//-----------------------------------------------------------------------------------


(
// TERNARY MODE
~setFreqsFromChain = {
	arg chain, primePair;
	var baseFreq = 100, primes = [primePair[0], primePair[1], 1/primePair[0], 1/primePair[1]], thisFreq, polars, directions, orientation, freqs=Array.new(8), muls;
	freqs.add(baseFreq);
	//freqs.postln;
	polars = ['N', 'E', 'S', 'W'];
	//orientation = polars.choose; // random
	orientation = polars[1]; // fixed, always starting looking 'east'
	//["FACING", orientation].postln;
	// 0 = L, 1 = straight, 2 = R
	chain.do( {
		arg chainVal, i; // chainVal is 0, 1, 2; i=index
		var newFreq;
		// set L/straight/R based on orientation
		switch ( orientation,
			'E', { muls = primes; directions = polars },
			'S', { muls = primes.rotate(-1); directions = polars.rotate(-1) },
			'W', { muls = primes.rotate(-2); directions = polars.rotate(-2) },
			'N', { muls = primes.rotate(-3); directions = polars.rotate(-3) }
		);

		//[orientation, muls, directions].postln;

		newFreq = freqs[i] * muls[chainVal]; // set new freq
		freqs.add(newFreq);
		orientation = directions[chainVal]; // set new orientation
	});
	// now make sure it's in range
	while( { freqs.minItem < 100.0 },
		{
			["TOO LOW", freqs.minItem].postln;
			freqs = freqs.collect( {
				arg freq;
				freq * (9/8);
			});
	});
	// return freqs
	freqs;
};

// PHASE CANCELLATION MODE
~getPhaseFreqs = {
	arg power=1.15;
	var startFreqs, freqs, freqMin, freqMax;
	startFreqs = Array.fill(4,
		{
			arg i;
			var freq;
			i = i + 1;
			freqMin = i * 100;
			freqMax = freqMin.pow(power);
			//[freqMin, freqMax].postln; // range
			freq = rrand(freqMin, freqMax);
	});

	startFreqs.postln;
	freqs = Array.new(8);

	startFreqs.do(
		{
			arg freq;
			['freq', freq].postln;
			// add each freq twice
			freqs.add(freq);
			freqs.add(freq);
	});
	// return freqs;
	freqs;
};

// PULSE RATE, call this every time with Phase Cancellation Mode
~getPulseRate = {
	arg pulseMin=0.5, pulseMax=3.0;
	var pulseRate;
	pulseRate = rrand(pulseMin, pulseMax);
	["PULSE RATE:", pulseRate].postln;
	// return pulse rate
	pulseRate;
};
)

//
r = ~getPhaseFreqs.();
f = ~getPulseRate.();
// BLUEPRINT