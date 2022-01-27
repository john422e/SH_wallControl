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

// PULSE MODE
~getPulseFreqs = {
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

// PITCH ROOM/BLUEPRINT
~getRoomPitches = {
	var minFreq=110.0, maxFreq=500.0;
	var lowFreq = rrand(minFreq, maxFreq);
	var minInterval=1.04, maxInterval=1.2;
	var freqs=Array.new(8), intervals;

	// make seven random intervals
	intervals = 7.collect( { rrand(minInterval, maxInterval) });
	freqs.add(lowFreq).postln;
	// fill a freq list from starting freq building up one interval at a time
	intervals.do( {
		arg interval, i;
		var newFreq;
		newFreq = freqs[i] * interval;
		freqs.add(newFreq);
	});
	//["RANGE:", freqs[7]/freqs[0]].postln;
	freqs = freqs.scramble;
	freqs;
};

// FIELDPLAY

~sfFiles = [
	[
		"../audio/desertNight/1.wav",
		"../audio/desertNight/2.wav",
		"../audio/desertNight/3.wav",
		"../audio/desertNight/4.wav"
	],
	[
		"../audio/desertQuiet/1.wav",
		"../audio/desertQuiet/2.wav"
	],
	[
		"../audio/desertTraffic/1.wav",
		"../audio/desertTraffic/2.wav",
		"../audio/desertTraffic/3.wav",
		"../audio/desertTraffic/4.wav"
	],
	[
		"../audio/interiors/1.wav",
		"../audio/interiors/2.wav",
		"../audio/interiors/3.wav",
		"../audio/interiors/4.wav",
		"../audio/interiors/5.wav",
		"../audio/interiors/6.wav",
		"../audio/interiors/7.wav"
	]
];
// need to be able to randomly select soundfile (by categories?),

~getSoundFiles = {
	arg space="exteriors";
	var listCopy, category, fns;
	// picks one sub array from ~sfFiles and fills an array with 8 filenames, wrapping as necessary
	if( space == "exteriors",
		{
			// choose only exteriors
			listCopy = ~sfFiles.copyRange(0, ~sfFiles.size-1);
			listCopy.removeAt(listCopy.size-1);
			category = listCopy.choose;
		},
		{
			// else it's interiors (grab the last batch only)
			category = ~sfFiles[~sfFiles.size-1];
	});
	fns = Array.fill(8, {
		arg i;
		category.wrapAt(i);
	});
	["FILES", fns].postln;
	fns;
};

~getAlarmWalls = {
	arg numAlarms=2;
	var choices, walls=Array.fill(8, { arg i; i });
	choices = Array.fill(numAlarms, {
		var choice;
		choice = walls.choose;
		walls.remove(choice);
		choice;
	});

};
)


