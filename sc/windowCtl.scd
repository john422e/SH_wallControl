(
var wWidth=1700, wHeight=130, title="SOUND HOUSE";
var netState, sensorState, sensorPingingState, ternaryState, pulseState, roomPitchState, fieldPlayState, feedbackState, alarmState, shutdown;
var modeButtons;


//-----------------------------------------------------------------------------------
// BUILD WINDOW
//-----------------------------------------------------------------------------------
Window.closeAll;
w = Window(title, Rect(0, 0, wWidth, wHeight))
.front
.alwaysOnTop_(true);
w.onClose_( {
	"FILE CLOSED".postln;
	} );
w.view.decorator_(FlowLayout(w.bounds, 10@10, 10@10));

//-----------------------------------------------------------------------------------
// STATE BUTTONS
//-----------------------------------------------------------------------------------

// 1. NETWORK STATE MODE
netState = ListView(w, 200@70)
.items_(
	["NONE", "DEV MODE—local", "DEV MODE—pione", "PERFORMANCE MODE—8 pis"])
.background_(Color.clear)
.hiliteColor_(Color.green(alpha:0.6))
.action_({
	arg sel;
	switch (sel.value,
		1, { ~hostnames = ["127.0.0.1"]},
		2, { ~hostnames = ["pione.local"]},
		3, { ~hostnames = [
			"pione.local",
			"pitwo.local",
			"pithree.local",
			"pifour.local",
			"pifive.local",
			"pisix.local",
			"piseven.local",
			"pieight.local"
		]}
	);
	// reset all buttons
	modeButtons.do( {
		arg butt, i;
		butt.valueAction_(0);
	});
	// some way to free NetAddr? is it needed?
	~hosts = ~makeHosts.(~hostnames);
});

// 1. SENSOR PROGRAM STATE
sensorState = Button(w, 170@30)
.states_([
	["SENSORS ARE INACTIVE", Color.black, Color.red],
	["SENSORS ARE ACTIVE", Color.black, Color.green]
])
.action_( {
	arg butt;
	if( butt.value == 1,
		{
			// TURN ON
			~sensorInit.();
		},
		{
			// TURN OFF
			~sensorShutdown.();
	});
	["SENSOR STATE:", butt.value].postln;
});

// 2. SENSOR PINGING STATE
sensorPingingState = Button(w, 190@30)
.states_([
	["SENSORS ARE NOT PINGING", Color.black, Color.red],
	["SENSORS ARE PINGING", Color.black, Color.green]
])
.action_( {
	arg butt;
	// ONLY ACTIVATE IF SENSORS ARE ALREADY TURNED ON
	if( sensorState.value == 1,
		{
			if( butt.value == 1,
				{
					// TURN ON
					~pingSensors.();
				},
				{
					// TURN OFF
					~unpingSensors.();
			});
		},
		{
			"TURN SENSORS ON FIRST".postln;
			butt.value_(0);
	});
	["SENSOR PINGING STATE:", butt.value].postln;
});

// 2. PULSE MODE
pulseState = Button(w, 170@30)
.states_([
	["PULSE MODE IS OFF", Color.black, Color.red],
	["PULSE MODE IS ON", Color.black, Color.green]
])
.action_( {
	arg butt;
	if( butt.value == 1,
		{
			// TURN ON
			~setAndTurnPulseOn.();
			// TURN ALL THE OTHER MODES OFF
			modeButtons.do( {
				arg modeButts, i;
				var thisIndex;
				thisIndex = modeButtons.indexOf(butt);
				if( (i > 1) && (i != thisIndex), { modeButts.valueAction_(0)});
			});
		},
		{
			// TURN OFF
			~turnPulseOff.();
	});
	["PULSE STATE:", butt.value].postln;
});

// 3. TERNARY CODE
ternaryState = Button(w, 160@30)
.states_([
	["TERNARY MODE IS OFF", Color.black, Color.red],
	["TERNARY MODE IS ON", Color.black, Color.green]
])
.action_( {
	arg butt;
	// ONLY ACTIVATE IF SENSORS ARE ALREADY TURNED ON
	if( sensorState.value == 1,
		{
			if( butt.value == 1,
				{
					var synthNum=1, gain=0.5; // change this if needed
					// TURN ON
					// TURN ALL THE OTHER MODES OFF
					modeButtons.do( {
						arg modeButts, i;
						var thisIndex;
						thisIndex = modeButtons.indexOf(butt);
						if( (i > 1) && (i != thisIndex), { modeButts.valueAction_(0)});
					});
					// activate sensor button if not already
					if( sensorPingingState.value == 0, { sensorPingingState.valueAction_(1) });
					~sendSines.(~ternaryFreqs, synthNum, 1, gain);
				},
				{
					// TURN OFF
					// deactivate sensor button if not already
					if( sensorPingingState.value == 1, { sensorPingingState.valueAction_(0) });
					~turnSinesOff.(0); // turn off both synths
					~turnSinesOff.(1);
			});
		},
		{
			"TURN SENSORS ON FIRST".postln;
			butt.value_(0);
	});
	["TERNARY STATE:", ~ternaryState].postln;
});

// 4. ROOM PITCH/BLUEPRINT MODE
roomPitchState = Button(w, 180@30)
.states_([
	["ROOM PITCH MODE IS OFF", Color.black, Color.red],
	["ROOM PITCH MODE IS ON", Color.black, Color.green]
])
.action_( {
	arg butt;
	// ONLY ACTIVATE IF SENSORS ARE ALREADY TURNED ON
	if( sensorState.value == 1,
		{
			if( butt.value == 1,
				{
					var synthNum=0, gain=0.5, freqs; // change this if needed
					// TURN ON
					// TURN ALL THE OTHER MODES OFF
					modeButtons.do( {
						arg modeButts, i;
						var thisIndex;
						thisIndex = modeButtons.indexOf(butt);
						if( (i > 1) && (i != thisIndex), { modeButts.valueAction_(0)});
					});
					// activate sensor button if not already
					if( sensorPingingState.value == 0, { sensorPingingState.valueAction_(1) });
					// get random freqs
					freqs = ~getRoomPitches.();
					~sendSines.(freqs, synthNum, 2, gain); // try 2 harmonic synth?
				},
				{
					// TURN OFF
					// deactivate sensor button if not already
					if( sensorPingingState.value == 1, { sensorPingingState.valueAction_(0) });
					~turnSinesOff.(0); // turn off both synths
					~turnSinesOff.(1);
			});
		},
		{
			"TURN SENSORS ON FIRST".postln;
			butt.value_(0);
	});
	["TERNARY STATE:", butt.value].postln;
});

// 5. FIELD RECORDING MODE
fieldPlayState = Button(w, 170@30)
.states_([
	["FIELDPLAY MODE IS OFF", Color.black, Color.red],
	["FIELDPLAY MODE IS ON", Color.black, Color.green]
])
.action_( {
	arg butt;
	// ONLY ACTIVATE IF SENSORS ARE ALREADY TURNED ON
	if( sensorState.value == 1,
		{
			if( butt.value == 1,
				{
					// TURN ON
					// TURN ALL THE OTHER MODES OFF
					modeButtons.do( {
						arg modeButts, i;
						var thisIndex;
						thisIndex = modeButtons.indexOf(butt);
						if( (i > 1) && (i != thisIndex), { modeButts.valueAction_(0)});
					});
					// activate sensor button if not already
					if( sensorPingingState.value == 0, { sensorPingingState.valueAction_(1) });
					~turnFieldPlayOn.(~getSoundFiles.("interiors"), 0);
					~turnFieldPlayOn.(~getSoundFiles.("exteriors"), 1);
					~setFieldPlayRandUpdates.(true, 0);
					~setFieldPlayRandUpdates.(true, 1);
				},
				{
					// TURN OFF
					// deactivate sensor button if not already
					if( sensorPingingState.value == 1, { sensorPingingState.valueAction_(0) });
					~setFieldPlayRandUpdates.(false, 0);
					~setFieldPlayRandUpdates.(false, 1);
					~turnFieldPlayOff.(0);
					~turnFieldPlayOff.(1);
			});
		},
		{
			"TURN SENSORS ON FIRST".postln;
			butt.value_(0);
	});
	["FIELDPLAY STATE:", butt.value].postln;
});

// 6. FEEDBACK MODE
feedbackState = Button(w, 170@30)
.states_([
	["FEEDBACK MODE IS OFF", Color.black, Color.red],
	["FEEDBACK MODE IS ON", Color.black, Color.green]
])
.action_( {
	arg butt;
	if( butt.value == 1,
		{
			// TURN ON
			// TURN ALL THE OTHER MODES OFF
			modeButtons.do( {
				arg modeButts, i;
				var thisIndex;
				thisIndex = modeButtons.indexOf(butt);
				if( (i > 1) && (i != thisIndex), { modeButts.valueAction_(0)});
			});
			// SEND WHATEVER UPDATE IS NEEDED TO PIS HERE
			"FEEDBACK ON".postln;
		},
		{
			// TURN OFF
			// SEND WHATEVER UPDATE IS NEEDED TO PIS HERE
			"FEEDBACK OFF".postln;
	});
	["FEEDBACK STATE:", butt.value].postln;
});

// 7. ALARM MODE
alarmState = Button(w, 170@30)
.states_([
	["ALARM MODE IS OFF", Color.black, Color.red],
	["ALARM MODE IS ON", Color.black, Color.green]
])
.action_( {
	arg butt;
	var numAlarms = rrand(2, 3);
	if( butt.value == 1,
		{
			// TURN ON
			// TURN ALL THE OTHER MODES OFF
			modeButtons.do( {
				arg modeButts, i;
				var thisIndex;
				thisIndex = modeButtons.indexOf(butt);
				if( (i > 1) && (i != thisIndex), { modeButts.valueAction_(0)});
			});
			~wallAlarms = ~getAlarmWalls.(numAlarms); // ~wallAlarms needs to be global to be turned off later
			~wallAlarms.postln;
			~turnAlarmOn.(~wallAlarms);
		},
		{
			// TURN OFF
			~turnAlarmOff.(~wallAlarms);
	});
	["ALARM STATE:", butt.value].postln;
});

// 8. SHUTDOWN BUTTON
shutdown = Button(w, 200@30)
.states_([
	["SHUTDOWN REMOTE SERVER", Color.black, Color.cyan]
])
.action_( {
	~shutdownRemoteServer.();
	// TURN ALL THE OTHER MODES
	modeButtons.do( {
		arg modeButts, i;
		modeButts.valueAction_(0);
	});
	// reset netState
	netState.valueAction_(0);
	"SHUTTING DOWN REMOTE SERVER".postln;
});

// put all buttons in a list
modeButtons = [sensorState, sensorPingingState, pulseState, ternaryState, roomPitchState, fieldPlayState, feedbackState, alarmState];
)