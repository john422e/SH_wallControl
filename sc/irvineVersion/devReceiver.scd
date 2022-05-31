(
var listenPort=10000, addresses; // only does 1/8 ports for now. need to make array to do all 8 if needed

addresses = [
	// sensor stuff
	'/sensorInit',
	'/sensorClose',
	'/sensorOn',
	'/sensorOff',
	// std synth stuff
	'/synthOn',
	'/synthOff',
	'/synthFreq',
	'/synthHarmonics',
	'/synthGain',
	// phase pulse stuff
	'/pulseOn',
	'/pulseOff',
	'/carrFreq',
	'/carrHarmonics',
	'/modFreq',
	'/pulseGain'

];

OSCdef.freeAll;
addresses.do( {
	arg address, i;
	address.postln;
	OSCdef.new(
		"listener" ++ i,
		// function to be evaluated upon receiving qualifying OSC message
		{
			arg msg, time, addr, port; // these are the messages passed on
			["RECEIVED ON PORT:", port, msg].postln;
			//[msg, time, addr, port].postln; // action to be executed
		},
		address,
		recvPort: listenPort,
	);
});
)


