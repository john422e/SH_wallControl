(
// -----------------------------------------------------
// OSC FUNCTIONS
// -----------------------------------------------------

// BUILD HOST ARRAY
~makeHosts = {
	arg hostnames, port=10000;
	var hosts;
	hosts = Array.fill( hostnames.size, { arg i; NetAddr.new( hostnames[i], port)});
	hosts;
};

~makeLocalHost = {
	arg hostname = "127.0.0.1", port=7400;
	var host;
	host = NetAddr.new( hostname, port);
	host;
};

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

// start python sensor program
~sensorInit = {
	~hosts.do( {
		arg host;
		host.sendMsg( '/sensorInit');
	});
};

// exit python sensor program
~sensorShutdown = {
	~hosts.do( {
		arg host;
		host.sendMsg( '/sensorShutdown');
	});
};

// exits chuck server
~shutdownRemoteServer = {
	~hosts.do( {
		arg host;
		host.sendMsg( '/endProgram');
	});
};

// start sensors pinging
~pingSensors = {
	~hosts.do( {
		arg host;
		host.sendMsg( '/sensorOn');
	});
};

// stop sensors pinging
~unpingSensors = {
	~hosts.do( {
		arg host;
		host.sendMsg( '/sensorOff');
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

// FOR FEEDBACK MODE
~setLocalSender = {
	arg host, state; // 0 or 1 off/on
	host.sendMsg('/senderState', state);
};

// FOR ALARM MODE: GET WALLS AND TURN ON THOSE (2 or 3)
~turnAlarmOn = {
	arg wallChoices, gain=0.2;
	wallChoices.do( {
		arg wallNum;
		if( ~hosts.size == 8,
			{
				~hosts[wallNum].sendMsg( '/alarmOn', 1, gain);
			},
			{
				"can only run alarm with all 8 pis online".postln;
		});
	});
};

// TURN ALARM OFF
~turnAlarmOff = {
	arg wallChoices;
	wallChoices.do( {
		arg wallNum;
		if( ~hosts.size == 8,
			{
				~hosts[wallNum].sendMsg( '/alarmOff');
			},
			{
				"can only run alarm with all 8 pis online".postln;
		});
	});
};

)