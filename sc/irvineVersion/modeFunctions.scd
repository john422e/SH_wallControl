//-----------------------------------------------------------------------------------
// MODE FUNCTIONS
//-----------------------------------------------------------------------------------
(

// FUNCTION FOR GENERATING EVENTS DURING EACH SHIFT
~getEventTimes = {
	var time, shiftDur=20, shiftEndBuffer=1.5, pulseRange = [1.5, 2.5], pulseDur, numModes=4, modes=Array.new(numModes), alarmEvent=0.5.coin, returnList=Array.new(numModes+2); // numModes= # of modes in a shift (excl. shift change + alarm), must be even num
	pulseDur = rrand(pulseRange[0], pulseRange[1]).round(0.25);
	//pulseDur.postln;
	// fill modes list;
	if( alarmEvent, {
		//"ALARM ADDED".postln;
		modes = Array.new(numModes+1);
		modes.add("alarm");
	}); // resize modes and add alarm
	// add fieldplay
	(numModes/2).do( { modes.add("fieldplay") });
	// add FB
	(numModes/2).do( { modes.add("FB") });

	// add shift change/pulse at the beginning every time
	returnList.add( [0.0, "shift change"]);

	time = pulseDur; // set current time to end of pulseDur
	while( {time < (shiftDur-shiftEndBuffer)} ) {
		var thisMode, modeRange = [2.5, 6.0], modeDur;
		thisMode = modes.choose; // select a mode
		modes.remove(thisMode); // remove it from available modes
		if( thisMode == "alarm", { modeDur = 2.0 }, { modeDur = rrand(modeRange[0], modeRange[1]).round(0.25) });
		//["TIME:", time, "NEW MODE:", thisMode].postln;

		// add to returnList
		returnList.add( [time, thisMode]);
		// advance time
		time = time + modeDur;
	};
	// return

	// TESTING ONLY
	returnList = [
		[0.0, "shift change"],
		[0.25, "FB"],
		[0.5, "fieldplay"],
		[0.75, "alarm"],
		[1.0, "FB"],
		[1.25, "FB"],
		[1.5, "fieldplay"],
		[1.75, "alarm"],
		[2.0, "FB"],
		[2.25, "FB"],
		[2.5, "fieldplay"],
		[2.75, "alarm"],
		[3.0, "FB"],
	];


	// FOR RECORDING ONLY
	/*
	returnList = [
		[0.0, "shift change"],
		[3.0, "FB"],
		[13.5, "fieldplay"],
		[16.25, "alarm"],
		[17.75, "FB"]
	];
	*/
	// COMMENT THIS OUT FOR REAL SHOW


	format("SHIFT EVENTS: %", returnList).postln;
	returnList; // [ [time, mode], .... ]
};

// TERNARY MODE
~setFreqsFromChain = {
	arg chain, primePair;
	var baseFreq = 140.0, primes = [primePair[0], primePair[1], 1/primePair[0], 1/primePair[1]], thisFreq, polars, directions, orientation, freqs=Array.new(8), muls;
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
	while( { freqs.minItem < 140.0 },
		{
			["TOO LOW", freqs.minItem].postln;
			freqs = freqs.collect( {
				arg freq;
				freq * (9/8);
			});
	});
	format("FREQS %", freqs).postln;
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
			if( i == 1, { freqMin = 150 }, { freqMin = i * 100 });
			//freqMin = i * 100;
			freqMax = freqMin.pow(power);
			//[freqMin, freqMax].postln; // range
			freq = rrand(freqMin, freqMax);
	});

	//startFreqs.postln;
	freqs = Array.new(8);

	startFreqs.do(
		{
			arg freq;
			//['freq', freq].postln;
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
	//["PULSE RATE:", pulseRate].postln;
	// return pulse rate
	pulseRate;
};

// PITCH ROOM/BLUEPRINT
~getRoomPitches = {
	var minFreq=200.0, maxFreq=400.0;
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
		"../../audio/desertNight/1.wav",
		"../../audio/desertNight/2.wav",
		"../../audio/desertNight/3.wav",
		"../../audio/desertNight/4.wav"
	],
	[
		"../../audio/desertQuiet/1.wav",
		"../../audio/desertQuiet/2.wav"
	],
	[
		"../../audio/desertTraffic/1.wav",
		"../../audio/desertTraffic/2.wav",
		"../../audio/desertTraffic/3.wav",
		"../../audio/desertTraffic/4.wav"
	],
	[
		"../../audio/interiors/1.wav",
		"../../audio/interiors/2.wav",
		"../../audio/interiors/3.wav",
		"../../audio/interiors/4.wav",
		"../../audio/interiors/5.wav",
		"../../audio/interiors/6.wav",
		"../../audio/interiors/7.wav"
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



			// TROUBLESHOOT AMP LEVELS HERE, ITERATE THROUGH EACH SET OF FIELD RECORDINGS

			// each one seems ok, but maybe need to narrow randFilter range

			category = listCopy.choose;
			//category = listCopy[2];





		},
		{
			// else it's interiors (grab the last batch only)
			category = ~sfFiles[~sfFiles.size-1];
	});
	fns = Array.fill(8, {
		arg i;
		category.wrapAt(i);
	});
	//["FILES", fns].postln;
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


