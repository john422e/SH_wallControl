
(
// -----------------------------------------------------
// OSC FUNCTIONS
// -----------------------------------------------------

~delayTime = 0.5;

// BUILD HOST ARRAY
~makeHosts = {
	arg hostnames, port=10000;
	var hosts;
	hosts = Array.fill( hostnames.size, { arg i; NetAddr.new( hostnames[i], port)});
	hosts;
};

~makeLocalHost = {
	arg hostname = "127.0.0.1", port=9998;
	var host;
	host = NetAddr.new( hostname, port);
	host;
};

// general use func
~setOneParam = {
	// expects an array of 8 integers
	arg synth=0, address='/carrFreq', vals=Array.fill(8, {440.0});
	[address, vals].postln;
	~hostsParams.do( {
		arg host, i;
		host.sendMsg( address, synth, vals[i]);
	});
};

~setMasterGain = {
	arg val;
	~hostsParams.do( {
		arg host, i;
		format("SETTING MASTER GAIN %", val).postln;
		host.sendMsg( "/masterGain", val);
	});
};

// start python sensor program
~sensorInit = {
	Task {
		// 1. add sensorSender.ck to remote server
		~hostsMaster.do( {
			arg host;
			host.sendMsg( '/sensorState', 1);
		});
		// delay
		(~delayTime + 1).wait; // allow extra time for sensorSender startup
		// 2. initiate sensors
		~hostsParams.do( {
			arg host;
			host.sendMsg( '/sensorInit');
		});
	}.start;
};

// exit python sensor program
~sensorShutdown = {
	Task {
		// 1. shutdown sensors
		~hostsParams.do( {
		arg host;
		host.sendMsg( '/sensorShutdown');
		});

		// delay
		~delayTime.wait;

		// 2. remove sensorSender.ck to remote server
		~hostsMaster.do( {
			arg host;
			host.sendMsg( '/sensorState', 0);
		});
	}.start;
};

// exits chuck server
~shutdownRemoteServer = {
	~hostsMaster.do( {
		arg host;
		host.sendMsg( '/endProgram');
	});
};

// start sensors pinging
~pingSensors = {  // deprecated???
	~hostsParams.do( {
		arg host;
		host.sendMsg( '/sensorOn');
	});
};

// stop sensors pinging
~unpingSensors = { // deprecated???
	~hostsParams.do( {
		arg host;
		host.sendMsg( '/sensorOff');
	});
};

// FOR TERNARY MODE AND BP ROOM MODE: TURN SYNTH ON/OFF
~setStdSynth = {
	arg address, state = 1;
	~hostsMaster.do( {
		arg host;
		//"------------SETTING STD SYNTH".postln;
		//state.postln;
		host.sendMsg(address, state);
	});
};

// FOR TERNARY MODE: SET ALL SINE FREQS AND TURN ON
~sendSines = {
	arg freqs = Array.fill(8, { 440.0}), synthNum=1, numHarms=1, amp=0.2;
	// synthNum = 0 or 1 (transducer or spkr)
	// all messages must have this order: address, synthNum, value
	~hostsParams.do( {
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
	~hostsParams.do( {
		arg host, i;
		// turn off synth state
		host.sendMsg( '/stdSynthState', synthNum, 0);
		host.sendMsg( '/synthOff', synthNum); // turn off
		//Routine {

			//1.wait;
			// do it again to catch stragglers
			//"2nd off".postln;
			//host.sendMsg( '/stdSynthState', synthNum, 0);
			//host.sendMsg( '/synthOff', synthNum); // turn off
		//}.play;
	});
};

// FOR PULSE MODE: SET AND TURN ALL PULSE OSCS ON
~setAndTurnPulseOn = {
	arg synthNums = Array.fill(8, {1}), numHarms = Array.fill(8, {1}), amps = Array.fill(8, {0.6}); // SET DEFAULT GAIN HERE
	var freqs, pulseRate;
	// synthNum = 0 or 1 (transducer or spkr), default is 1 (speaker)
	// all messages have this order: address, synthNum, value
	freqs = ~getPulseFreqs.();
	pulseRate = ~getPulseRate.();

	Task {
		// 1. add pulseSynth.ck to remote server
		~hostsMaster.do( {
			arg host, i;
			host.sendMsg('/pulseState', 1);
		});

		// add delay here
		~delayTime.wait;

		// 2. set params
		~hostsParams.do( {
			arg host, i;
			// set params
			host.sendMsg('/modFreq', synthNums[i], pulseRate); // set pulseRate
			host.sendMsg('/carrFreq', synthNums[i], freqs[i]); // set freq
			host.sendMsg('/harmonics', synthNums[i], numHarms[i]); // set numHarms
			host.sendMsg('/pulseGain', synthNums[i], amps[i]); // set gain
			// turn on
			host.sendMsg('/pulseOn', synthNums[i]);

		});
	}.start;
};

// TURN PULSE OSCS OFF
~turnPulseOff = {
	arg synthNums = Array.fill(8, {1}); // default to speaker (synth 1)
	Task {
		// 1. turn off synth envs
		~hostsParams.do( {
			arg host, i;
			// turn off
			host.sendMsg( '/pulseOff', synthNums[i]);
			//host.sendMsg( '/endProgram', synthNums[i]);
		});

		// delay
		~delayTime.wait;

		// 2. remove pulseSynth.ck from remote server
		~hostsMaster.do( {
			arg host, i;
			// remove pulseSynth.ck from remote server
			//"SENDING PULSE OFF".postln;
			host.sendMsg('/pulseState', 0);
		});
	}.start;
};

// FOR FIELDPLAY MODE: INIT FILES, TURN ON, AND START RANDOM BPF UPDATING
~setFieldPlaySynth = { arg state;
	~hostsMaster.do( {
		arg host, i;
		host.sendMsg('/fieldplayState', state);
	});
};

~turnFieldPlayOn = {
	arg fns, synthNum=1; // 8 sound file names, default to speaker (synth 1)
	~hostsParams.do( {
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
	if( update == true, { updates=Array.fill(8, {1}); gain=1.5}, { updates=Array.fill(8, {0}); gain=1.5});  // set default gain here (in first array!)!
	~hostsParams.do( {
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
	~hostsParams.do( {
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
~setFeedbackReceivers = {
	// DEPRICATED? using individual buttons for now due to segment faults
	arg state=1;
	~hostsMaster.do( {
		arg host, i;
		host.sendMsg('/fbSynthState', state);
	});
};

~setLocalSender = {
	arg host, state; // 0 or 1 off/on
	if( host.isNil == false,
		{host.sendMsg('/fbSenderState', state)},
		{"NO HOST YET".postln;}
	);
};

// FOR ALARM MODE: GET WALLS AND TURN ON THOSE (2 or 3)
~turnAlarmOn = {
	arg wallChoices, gain=0.15;
	wallChoices.do( {
		arg wallNum;
		if( ~hostsMaster.size == 8,
			{
				Task {
					// 1. add alarmSynth.ck to remote server
					~hostsMaster[wallNum].sendMsg( '/alarmState', 1);

					~delayTime.wait;

					// 2. Turn alarm on
					// send to both? for funsies?
					~hostsParams[wallNum].sendMsg( '/alarmOn', 0, gain);
					~hostsParams[wallNum].sendMsg( '/alarmOn', 1, gain);
				}.start;
			},
			{
				//"sending to host 0".postln;
				Task {
					// 1. add alarmSynth.ck to remote server
					~hostsMaster[0].sendMsg( '/alarmState', 1);

					~delayTime.wait;

					// 2. Turn alarm on
					// send to both? for funsies?
					~hostsParams[0].sendMsg( '/alarmOn', 0, gain);
					~hostsParams[0].sendMsg( '/alarmOn', 1, gain);
				}.start;
		});
	});
};

// TURN ALARM OFF
~turnAlarmOff = {
	arg wallChoices;
	wallChoices.do( {
		arg wallNum;
		if( ~hostsMaster.size == 8,
			{
				Task {
					// 1. turn off alarm
					~hostsParams[wallNum].sendMsg( '/alarmOff');

					~delayTime.wait;

					// 2. remove alarmSynth.ck from remote server
					~hostsMaster[wallNum].sendMsg( '/alarmState', 0);
				}.start;
			},
			{
				//"sending to host 0".postln;
				Task {
					// 1. turn off alarm
					~hostsParams[0].sendMsg( '/alarmOff');

					~delayTime.wait;

					// 2. remove alarmSynth.ck from remote server
					~hostsMaster[0].sendMsg( '/alarmState', 0);
				}.start;
		});
	});
};

)