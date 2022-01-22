(
// connect MIDI devices
MIDIIn.connectAll;
//MIDIFunc.trace(true);
MIDIFunc.trace(false);
// run this so that MIDI controller will update list (set ctlOffset for any 7 sliders in a row and sendCtl for button)
~chain = Array.fill(7, { 0 } ); // 0 = down
~primePair = [3/2, 5/4];
~ternaryFreqs;



// MIDI defs
MIDIdef.cc( \ternaryCtl, {
	// ctl num 41-47
	arg val, num, chan, src;
	var ctlOffset=0, sendCtl=41;
	if( ~ternaryState == 1,
		{
			//amp = val.linlin(0, 127, -60, 0);
			//// amps, controls 0-7
			if( (num >= ctlOffset) && (num <= (ctlOffset+7)),
				{
					// set val to 0, 1, or 2 based on slider position
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
					var synthNum = 1, gain=0.5; // change this if needed
					// compute freqs and send
					~ternaryFreqs = ~setFreqsFromChain.(~chain, ~primePair);
					~ternaryFreqs.postln;
					// add network send function here
					~sendSines.(~ternaryFreqs, Array.fill(8, { synthNum }), Array.fill(8, { 1 }), Array.fill(8, { gain }));
				};
			);

			// add a control for ternary mode on/off here
	});
});


MIDIdef.cc( \fieldPlay, {
	// ctl nums ___ (two banks of 8--sliders and knobs--16 total)
	arg val, num, chan, src;
	var freqCtlOffset=0, qGainCtlOffset=16, sendCtl=41;
	if( ~fieldPlayState == 1,
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


// set this as the button action for a MIDI button
~setFreqsFromChain.(~chain, [3/2, 5/4]);