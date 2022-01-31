
(
// FUNCTION FOR GENERATING EVENTS DURING EACH SHIFT
~getEventTimes = {
	var time, shiftDur=20, shiftEndBuffer=1.5, pulseRange = [1.5, 3.0], pulseDur, numModes=4, modes=Array.new(numModes), alarmEvent=0.5.coin, returnList=Array.new(numModes+2); // numModes= # of modes in a shift (excl. shift change + alarm), must be even num
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
	returnList; // [ [time, mode], .... ]
};


// GLOBAL TIME VARS
~shifts = 8;
~minutes = 20;
~currentState = "";


// SHIFT CLOCK ROUTINE
r = Routine {
	~shifts.do{
		// iterate for # of shifts
		arg i;
		var minuteDivisions=4;
		var eventCounter=0, events = ~getEventTimes.();
		var waitTime = 60/minuteDivisions;

		["EVENTS THIS SHIFT", events].postln;


		(~minutes*minuteDivisions).do{
			// iterate for every time division of a minute
			arg j;
			var time=(j/minuteDivisions);
			//time.postln;

			// CHECK FOR EVENT
			if( time == events[eventCounter][0], {
				var thisEvent=events[eventCounter][1];
				//[eventCounter, events.size].postln;
				format("MODE CHANGE: %, TIME: %", thisEvent, time).postln;
				//[time, thisEvent].postln;
				~currentState = thisEvent;

				// put logic for updating functions here
				/*
				needs to be logic that state only changes if NOT in ternary mode or blueprint mode
				*/

				// iterate
				if( eventCounter < (events.size-1), { eventCounter = eventCounter + 1 });
			});

			// POST TIME/STATE UPDATE EVERY MINUTE
			if( time.mod(1) == 0, {
				format("SCORE LOG: shift: % time: %:00., current state: %", i, time.asInteger, ~currentState).postln;
				//["SHIFT:", i, "MINUTES:", time.asInteger, "CURRENT STATE:", ~currentState].postln;
			},
			{
				format("SCORE LOG: time: %:% seconds", time.asInteger, (time*60).mod(60).asInteger).postln;
				//["TIME:", time.mod(1).round(1).asInteger, (time*60).asInteger].postln;
			});

			// WAIT
			waitTime.wait;
			//0.25.wait;

		};
	};
};


// RUN IT
r.play;

)

a = "asdf";
"Hello {}".format(a).postln;