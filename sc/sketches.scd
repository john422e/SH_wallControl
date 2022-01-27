// chuck sensor ctl with --caution-to-the-wind flag
~hosts[0].sendMsg( '/sensorInit'); // do first: start python program
~hosts[0].sendMsg( '/rebootSensor' ); // for emergencies only
~hosts[0].sendMsg( '/endProgram');  // do last: close python and chuck programs, make them all match "/endProgram"
~hosts[0].sendMsg( '/sensorOn'); // start pinging
~hosts[0].sendMsg( '/sensorOff'); // stop pinging


~hosts[0].sendMsg( '/stdSynthState', 0, 1); // turn first synth off/on
~hosts[0].sendMsg( '/stdSynthState', 1); // turn synth off/on
~hosts[0].sendMsg( '/alarmOn');
~hosts[0].sendMsg( '/alarmOff');

~setOneParam.( 1, '/bufGain', Array.fill(8, { 3.99 }));


~hosts[0].sendMsg( '/synthGain', 0, 0.0); // 0.99
~hosts[1].sendMsg( '/synthGain', 0, 0.0); // 0.7
~hosts[2].sendMsg( '/synthGain', 0, 0.0); // 0.65
~hosts[3].sendMsg( '/synthGain', 0, 0.0); // 0.7
~hosts[4].sendMsg( '/synthGain', 0, 0.0); // 0.8
~hosts[5].sendMsg( '/synthGain', 0, 0.0); // 0.7
~hosts[6].sendMsg( '/synthGain', 0, 0.0); // 0.6
~hosts[7].sendMsg( '/synthGain', 0, 0.0); // 0.8



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