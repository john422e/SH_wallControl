// -----------------------------------------------------
// HOST SETUP
// -----------------------------------------------------
~devMode = false;
//~devMode = true;
(
if( ~devMode == true,
	{
		// set up a local host on 8 different ports
		var ports = Array.fill(8, { arg i; 10000 + i });
		~localIP = "127.0.0.1";
		~hosts = Array.fill(8, { arg i; NetAddr.new(~localIP, ports[i])});
	},
	{
		// else, set up 8 pi hosts on the same port
		var port=10002;
		~hostnames = [
			"pione.local",
			"pitwo.local",
			"pithree.local",
			"pifour.local",
			"pifive.local",
			"pisix.local",
			"piseven.local",
			"pieight.local"
		];
		~hosts = Array.fill( 8, { arg i; NetAddr.new( ~hostnames[i], port )});
	}
);
)




~hosts[0].sendMsg( '/sensorInit'); // do first: start python program
~hosts[0].sendMsg( '/sensorClose'); // do last: close python and chuck programs
~hosts[0].sendMsg( '/sensorOn'); // start pinging
~hosts[0].sendMsg( '/sensorOff'); // stop pinging

// -----------------------------------------------------
// FUNCTIONS
// -----------------------------------------------------

~hosts[0].sendMsg( '/synthOn', 0);
~hosts[0].sendMsg( '/synthOff', 0);
~hosts[0].sendMsg( '/synthOn', 1);
~hosts[0].sendMsg( '/synthOff', 1);
~hosts[0].sendMsg( '/synthHarmonics', 0, 1);
~hosts[0].sendMsg( '/synthHarmonics', 1, 1);
~hosts[0].sendMsg( '/synthFreq', 1, 440.0);

rrand(-1.0, 1.0);

(
Routine {
	8.do {
		arg i;
		i.postln;
		~hosts[0].sendMsg( '/bufPan', i, rrand(0.0, 0.0));
		~hosts[0].sendMsg( '/bufFilterFreq', i, rrand(100.0, 500.0));
		~res = rrand(20.0, 40.0).postln;
		~hosts[0].sendMsg( '/bufFilterQ', i, ~res); // 0.58 for flattish
		~hosts[0].sendMsg( '/bufGain', i, (~res/4));
		~hosts[0].sendMsg( '/bufOn', i);
		1.wait;
		~hosts[0].sendMsg( '/bufOff', i);
		0.25.wait;
	};
}.play;
)

(
~setOneParam = {
	// expects an array of 8 integers
	arg synth=0, address='/carrFreq', vals=Array.fill(8, {440.0});
	[address, vals].postln;
	~hosts.do( {
		arg host, i;
		host.sendMsg( address, synth, vals[i]);
	});
};

~setSineMode = {
	arg synth=0, gate=0; // 0 = set but don't turn on, 1 = set and turn on
	~hosts.do( {
		arg host;
		host.sendMsg( '/modFreq', synth, 0.0);
		host.sendMsg( '/modOn', synth);
		host.sendMsg( '/pulseWidth', synth, 1.0);
		host.sendMsg( '/pulseOn', synth);
		host.sendMsg( '/harmonics', synth, 1);
		host.sendMsg( '/carrOn', synth);
		if( gate == 1, { host.sendMsg( '/fmOn', synth) });
	});
};

~sendSines = {
	arg freqs = Array.fill(8, { 440.0}), synthNums = Array.fill(8, { 0 }), numHarms = Array.fill(8, { 1 }), amps = Array.fill(8, { 1.0});
	// synthNum = 0 or 1 (transducer or spkr)
	// all messages must have this order: address, synthNum, value
	~hosts.do( {
		arg host, i;
		host.sendMsg( '/synthFreq', synthNums[i], freqs[i]); // send freq
		host.sendMsg( '/synthHarmonics', synthNums[i], numHarms[i]); // send numHarms
		host.sendMsg( '/synthGain', synthNums[i], amps[i]); // set gain
		host.sendMsg( '/synthOn', synthNums[i]); // turn on
	});
};

~turnSinesOff = {
	arg synthNums = Array.fill(8, { 0 });
	~hosts.do( {
		arg host, i;
		host.sendMsg( '/synthOff', synthNums[i]); // turn off
	});
};

~getAndSendPhasePulse = {
	arg synthNums = Array.fill(8, {0}), numHarms = Array.fill(8, {1}), amps = Array.fill(8, {1.0});
	var freqs, pulseRate;
	// synthNum = 0 or 1 (transducer or spkr)
	// all messages have this order: address, synthNum, value
	freqs = ~getPhaseFreqs.();
	pulseRate = ~getPulseRate.();
	~hosts.do( {
		arg host, i;
		host.sendMsg('/pulseFreq', synthNums[i], pulseRate); // set pulseRate
		host.sendMsg('/carrFreq', synthNums[i], freqs[i]); // set freq
		host.sendMsg('/harmonics', synthNums[i], numHarms[i]); // set numHarms
		host.sendMsg('/fmGain', synthNums[i], numHarms[i]); // set gain

		// check to see if I need all of these?
		host.sendMsg('/fmOn', synthNums[i]);
		host.sendMsg('/modOn', synthNums[i]);
		host.sendMsg('/pulseOn', synthNums[i]);
	});
};

~turnPulseOff = {
	arg synthNums = Array.fill(8, {0});
	~hosts.do( {
		arg host, i;
		host.sendMsg( '/fmOff', synthNums[i]);
	});
};

)


// -----------------------------------------------------
// EVENTS
// -----------------------------------------------------
~setOneParam.(0, '/harmonics', [1, 1, 1, 2, 1, 2, 1, 2]);
~setOneParam.(0, '/carrFreq', Array.fill(8, { rrand(110.0, 330.0) }));
~setOneParam.(0, '/carrFreq', Array.fill(8, { 440.0 }));
~setOneParam.(0, '/modFreq', Array.fill(8, { 0.0 }));
~setOneParam.(0, '/modOff');
~setOneParam.(0, '/modOn');
~setOneParam.(0, '/pulseFreq', Array.fill(8, {3.0}));
~setOneParam.(0, '/pulseWidth', Array.fill(8, {0.25}));
~setOneParam.(0, '/fmOff');
~setOneParam.(0, '/fmOn');
~setOneParam.(0, '/pulseOn');
~setOneParam.(0, '/pulseOff');
~setSineMode.(0, 1);
~setSineMode.(1, 1);
~setOneParam.(0, '/modFreq', Array.fill(8, { 120.0 }));
~setOneParam.(0, '/fmGain', Array.fill(8, {1.0}));

/*
run:
-stdSynth.ck for sustained tones
-fmSynth.ck for fm/pulsing tones

make a mode with sensor mapped to modFreq

ring modulation mode

fieldPlay mode (add BP filters on each synth)

try master patch

*/