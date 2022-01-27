// -----------------------------------------------------
// HOST SETUP
// -----------------------------------------------------



// EVALUATE ONE OF THESE FIRST
~devMode = false;
~devMode = true;





// THEN RUN THIS BLOCK
(
if( ~devMode == true,
	{
		// set up a local host on 8 different ports
		var ports = Array.fill(8, { arg i; 10000 + i });
		~localIP = "127.0.0.1";
		//~localIP = "eagle2018.local";
		~hosts = Array.fill(8, { arg i; NetAddr.new(~localIP, ports[i])});
	},
	{
		// else, set up 8 pi hosts on the same port
		var port=10000;
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



// chuck sensor ctl with --caution-to-the-wind flag
~hosts[0].sendMsg( '/sensorInit'); // do first: start python program
~hosts[0].sendMsg( '/rebootSensor' );
~hosts[0].sendMsg( '/sensorClose'); // do last: close python and chuck programs, make them all match "/endProgram"
~hosts[0].sendMsg( '/endProgram');
~hosts[0].sendMsg( '/sensorOn'); // start pinging
~hosts[0].sendMsg( '/sensorOff'); // stop pinging


~hosts[0].sendMsg( '/stdSynthState', 0); // turn synth off/on
~hosts[0].sendMsg( '/stdSynthState', 1); // turn synth off/on
~hosts[0].sendMsg( '/alarmOn');
~hosts[0].sendMsg( '/alarmOff');

~setOneParam.( 1, '/bufGain', Array.fill(8, { 3.99 }));

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


~hosts[1].sendMsg( '/synthOn', 0);
~hosts[1].sendMsg( '/synthOff', 0);



~hosts[0].sendMsg( '/synthGain', 0, 0.0); // 0.99
~hosts[1].sendMsg( '/synthGain', 0, 0.0); // 0.7
~hosts[2].sendMsg( '/synthGain', 0, 0.0); // 0.65
~hosts[3].sendMsg( '/synthGain', 0, 0.0); // 0.7
~hosts[4].sendMsg( '/synthGain', 0, 0.0); // 0.8
~hosts[5].sendMsg( '/synthGain', 0, 0.0); // 0.7
~hosts[6].sendMsg( '/synthGain', 0, 0.0); // 0.6
~hosts[7].sendMsg( '/synthGain', 0, 0.0); // 0.8

~hosts[7].sendMsg( '/synthGain', 1, 0.2);


~gains = [0];
~setOneParam.( 0, '/alarmGain', Array.fill(8, { 0.0 }));
~setOneParam.( 1, '/alarmGain', Array.fill(8, { 0.002 }));
~hosts[7].sendMsg( '/alarmGain', 0, 0.00);

~hosts[7].sendMsg( '/pulseOn', 1);
~hosts[7].sendMsg( '/carrFreq', 1, 200.0);
~hosts[7].sendMsg( '/modFreq', 1, 1.0);
~hosts[7].sendMsg( '/pulseGain', 1, 0.5);

~hosts[6].sendMsg( '/stdSynthState', 1);
~hosts[6].sendMsg( '/synthOn', 1);
~hosts[6].sendMsg( '/synthFreq', 1, 440.0);
~hosts[6].sendMsg( '/synthGain', 1, 0.01);

~hosts[0].sendMsg( '/bufSynthState', 0, 1);
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
);


/*
// MASTER PI AMP LEVELS
~trLevels = [1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0];
~spkrLevels = [1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0];


~trLevels[0];
~spkrLevels[0];

~setLevels.(~trLevels, ~spkrLevels, 330.0);
*/

(
// PI FUNCS

// general use func
~setOneParam = {
	// expects an array of 8 integers
	arg synth=0, address='/carrFreq', vals=Array.fill(8, {440.0});
	[address, vals].postln;
	~hosts.do( {
		arg host, i;
		host.sendMsg( address, synth, vals[i]);
	});
};

// SET AMP LEVELS ON EACH PI
~setLevels = {
	arg spkrs, trans, freq=220.0;
	~hosts.do( {
		arg host, i;
		// set freq
		host.sendMsg( '/synthFreq', 0, freq);
		host.sendMsg( '/synthFreq', 1, freq);
		// set transducer level
		host.sendMsg( '/synthGain', 0, ~trLevels[i]);
		// set speaker level
		host.sendMsg( '/synthGain', 1, ~spkrLevels[i]);
	});
};

// FOR TERNARY MODE: SET ALL SINE FREQS AND TURN ON
~sendSines = {
	arg freqs = Array.fill(8, { 440.0}), synthNum=1, numHarms=1, amp=0.2;
	// synthNum = 0 or 1 (transducer or spkr)
	// all messages must have this order: address, synthNum, value
	~hosts.do( {
		arg host, i;
		// turn on synth state
		host.sendMsg( '/stdSynthState', synthNum, 1);
		// set vals
		host.sendMsg( '/synthFreq', synthNum, freqs[i]); // send freq
		host.sendMsg( '/synthHarmonics', synthNum, numHarms); // send numHarms
		host.sendMsg( '/synthGain', synthNum, amp); // set gain
		host.sendMsg( '/synthOn', synthNum); // turn on
	});
};

// TURN SINES OFF
~turnSinesOff = {
	arg synthNum=1;
	~hosts.do( {
		arg host, i;
		// turn off synth state
		host.sendMsg( '/stdSynthState', synthNum, 0);
		host.sendMsg( '/synthOff', synthNum); // turn off
	});
};

// FOR PULSE MODE: SET AND TURN ALL PULSE OSCS ON
~setAndTurnPulseOn = {
	arg synthNums = Array.fill(8, {1}), numHarms = Array.fill(8, {1}), amps = Array.fill(8, {0.2});
	var freqs, pulseRate;
	// synthNum = 0 or 1 (transducer or spkr), default is 1 (speaker)
	// all messages have this order: address, synthNum, value
	freqs = ~getPulseFreqs.();
	pulseRate = ~getPulseRate.();
	~hosts.do( {
		arg host, i;
		// set params
		host.sendMsg('/modFreq', synthNums[i], pulseRate); // set pulseRate
		host.sendMsg('/carrFreq', synthNums[i], freqs[i]); // set freq
		host.sendMsg('/harmonics', synthNums[i], numHarms[i]); // set numHarms
		host.sendMsg('/pulseGain', synthNums[i], amps[i]); // set gain
		// turn on
		host.sendMsg('/pulseOn', synthNums[i]);


	});
};

// TURN PULSE OSCS OFF
~turnPulseOff = {
	arg synthNums = Array.fill(8, {1}); // default to speaker (synth 1)
	~hosts.do( {
		arg host, i;
		// turn off
		host.sendMsg( '/pulseOff', synthNums[i]);
	});
};

// FOR FIELDPLAY MODE: INIT FILES, TURN ON, AND START RANDOM BPF UPDATING
~turnFieldPlayOn = {
	arg fns, synthNum=1; // 8 sound file names, default to speaker (synth 1)
	~hosts.do( {
		arg host, i;
		// turn on synth state
		host.sendMsg('/bufSynthState', synthNum, 1);
		// init
		host.sendMsg('/bufRead', synthNum, fns[i]);
		// turn on
		host.sendMsg('/bufOn', synthNum);
	});
};

~setFieldPlayRandUpdates = {
	arg update=true, synthNum=1; // default to on (1) and speaker ( synth1 1)
	var updates, gain;
	// address, synthnum, state, seed (0-7)
	if( update == true, { updates=Array.fill(8, {1}); gain=3.0}, { updates=Array.fill(8, {0}); gain=1.0});
	~hosts.do( {
		arg host, i;
		// set
		host.sendMsg('/randUpdates', synthNum, updates[i], i);
		// up gain as well
		host.sendMsg('/bufGain', synthNum, gain);
	});
};

// TURN FIELDPLAY MODE OFF
~turnFieldPlayOff = {
	arg synthNum=1; // default to speaker (synth 1)
	~hosts.do( {
		arg host, i;
		// turn off synth state
		host.sendMsg('/bufSynthState', synthNum, 0);
		// turn off
		host.sendMsg( '/bufOff', synthNum);
	});
	// turn off rand updates too
	~setFieldPlayRandUpdates.(false, synthNum);
};

// FOR ALARM MODE: GET WALLS AND TURN ON THOSE (2 or 3)
~turnAlarmOn = {
	arg wallChoices, gain=0.2;
	wallChoices.do( {
		arg wallNum;
		~hosts[wallNum].sendMsg( '/alarmOn', 1, gain);
	});
};

// TURN ALARM OFF
~turnAlarmOff = {
	arg wallChoices;
	wallChoices.do( {
		arg wallNum;
		~hosts[wallNum].sendMsg( '/alarmOff');
	});
};

)

~turnAlarmOff.([0, 1, 2, 3, 4, 5, 6, 7]);

// -----------------------------------------------------
// EVENTS
// -----------------------------------------------------


/*
run:
-stdSynth.ck for sustained tones
-pulseSynth.ck for fm/pulsing tones

make a mode with sensor mapped to modFreq

ring modulation mode

fieldPlay mode (add BP filters on each synth)

try master patch

*/