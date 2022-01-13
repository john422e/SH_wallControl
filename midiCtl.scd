(
// connect MIDI devices
MIDIIn.connectAll;
//MIDIFunc.trace(true);
//MIDIFunc.trace(false);
// run this so that MIDI controller will update list (set ctlOffset for any 7 sliders in a row and sendCtl for button)
~chain = Array.fill(7, { 0 } ); // 0 = down
~primePair = [3/2, 5/4];
~ternaryFreqs;



// MIDI defs
MIDIdef.cc( \ternaryCtl, {
	// ctl num 41-47
	arg val, num, chan, src;
	var ctlOffset=41, sendCtl=105;
	if( ~ternaryState == 1,
		{
			//amp = val.linlin(0, 127, -60, 0);
			//// amps, controls 0-7
			if( (num >= ctlOffset) && (num <= (ctlOffset+7)),
				{
					var ctl=num-ctlOffset;
					//[ctl, val].postln;
					~chain[ctl] = case
					{ val >= 117 } { 2 }
					{ val <= 10 } { 0 }
					{ (val > 10) && (val < 117) } { 1 };
					//~chain[ctl].postln;
					~chain.postln;
				}
			);
			if( (num == sendCtl) && (val>0),
				{
					~ternaryFreqs = ~setFreqsFromChain.(~chain, ~primePair);
					~ternaryFreqs.postln;
					// add network send function here
				};
			);

			// add a control for ternary mode on/off here
	});
});


MIDIdef.cc( \fieldPlay, {
	// ctl nums ___ (two banks of 8--sliders and knobs--16 total)
	arg val, num, chan, src;
	var freqCtlOffset=41, qGainCtlOffset=21, sendCtl=105;
	if( ~fieldPlayMode == 1,
		{
			// filter freq control
			if( (num >= freqCtlOffset ) && (num <= (freqCtlOffset+8)),
				{
					var ctl=num-freqCtlOffset, filterFreq;
					filterFreq = val.linexp(0, 127, 100, 10000);
					[ctl, filterFreq].postln;
					// call function for sending filterFreq
					// HERE
			});
			// filter gain/Q control
			if( (num >= qGainCtlOffset) && (num <= (qGainCtlOffset+8) ),
				{
					var ctl=num-qGainCtlOffset, qVal, gain;
					gain = val.linlin(0, 127, 0, 10.0);
					qVal = val.linlin(0, 127, 0, 20.0);
					[ctl, gain, qVal].postln;
					// call function for sending Q and gain
					// HERE
			});

	});
			// set ctl actions here use a switch for ctls
			// use slider for freq
			// use knob for a dual control on Q/gain (inverse?)
			// also something to bring overall gain up/down?


});
)


(

// FUNCTIONS
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
	freqs;
};
)

// set this as the button action for a MIDI button
~setFreqsFromChain.(~chain, [3/2, 5/4]);