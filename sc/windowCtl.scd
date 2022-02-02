~hosts[0].sendMsg("/m", 0.4);

(
var wWidth=1700, wHeight=150, title="SOUND HOUSE";
var netView, buttonsRowsView, modeButtonsView, fbButtonsView, gainView;
var netState, sensorState, sensorPingingState, ternaryState, pulseState, roomPitchState, fieldPlayState, feedbackState, alarmState, hybridState, shutdown;
var modeButtons, fbButtons, gainCtl, masterGain;
var resetAll, turnOffOtherModes;

// RESET FUNCTION
resetAll = {
	arg buttons;
	buttons.do({
		arg butt;
		butt.valueAction_(0);
	});
};

turnOffOtherModes = {
	arg butt, buttons;
	var thisIndex;
	thisIndex = buttons.indexOf(butt);
	buttons.do{
		arg otherButt, i;
		if( (i != thisIndex) && (i > 1), {otherButt.valueAction_(0)});
	};
};


//-----------------------------------------------------------------------------------
// BUILD WINDOW
//-----------------------------------------------------------------------------------
Window.closeAll;
w = Window(title, Rect(0, 0, wWidth, wHeight))
.alwaysOnTop_(true);
w.onClose_( {
	"FILE CLOSED".postln;
})
.view.decorator_(FlowLayout(w.bounds, 10@10, 10@10))
.front;
w.drawFunc = {
	var fbSenderButton;
	// remove all children (reset)
	fbButtonsView.removeAll;

	// add fbSender
	fbSenderButton = Button()
	.states_( [
		["FB SENDER IS ON", Color.black, Color.red],
		["FB SENDER IS OFF", Color.black, Color.green]
	])
	.action_( {
		arg butt;
		if( butt.value == 1,
			{
				// TURN ON FB SENDER
				"TURNING ON LOCAL FB SENDER".postln;
			},
			{
				// TURN OFF FB SENDER
				"TURNING OFF LOCAL FB SENDER".postln;
			}
		);
	});
	// add to layout
	fbButtonsView.layout.add(fbSenderButton);

	// recreate button array every refresh for netstate change
	fbButtons = Array.fill(~hosts.size, {
		arg i;
		var newButt;
		newButt = Button()
		.states_( [
			[i, Color.black, Color.red],
			[i, Color.black, Color.green]
		])
		.action_( {
			arg butt;
			if( butt.value == 1,
				{
					// TURN ON FB
					format("FB % ON", i).postln;
					~hosts[i].sendMsg("/fbReceiverState", 1);
				},
				{
					// TURN OFF FB
					format("FB % OFF", i).postln;
					~hosts[i].sendMsg("/fbReceiverState", 0);
			});
		});
	});

	// add to layout
	fbButtons.do{
		arg butt;
		fbButtonsView.layout.add(butt);
	};
};


// CREATE SUB VIEWS
netView = View(w, Rect(0, 0, wWidth/8, wHeight-20));
buttonsRowsView = View(w, Rect(0, 0, (wWidth/8)*6.8, wHeight))
.layout_(VLayout())
.font_("Monaco");

modeButtonsView = View(buttonsRowsView, Rect(0, 0, (wWidth/8)*6.8, wHeight/2));
fbButtonsView = View(buttonsRowsView, Rect(0, 0, (wWidth/8)*6, wHeight/2));
gainView = View(buttonsRowsView, Rect(0, 0, (wWidth/8)*6, wHeight/2));


// ADD NET VIEW LAYOUTS AND ITEMS
netView.layout_( VLayout(
	// ITEMS:
	// 1. NETWORK STATE MODE
	netState = ListView()
	.items_(
		["NONE", "DEV MODE—local", "pione", "pitwo", "pithree", "pifour", "pifive", "pisix", "piseven", "pieight", "PERF MODE—8 pis", "TEST"])
	.background_(Color.clear)
	.hiliteColor_(Color.green(alpha:0.6))
	.action_({
		arg sel;
		switch (sel.value,
			1, { ~hostnames = ["127.0.0.1"]},
			2, { ~hostnames = ["pione.local"]},
			3, { ~hostnames = ["pitwo.local"]},
			4, { ~hostnames = ["pithree.local"]},
			5, { ~hostnames = ["pifour.local"]},
			6, { ~hostnames = ["pifive.local"]},
			7, { ~hostnames = ["pisix.local"]},
			8, { ~hostnames = ["piseven.local"]},
			9, { ~hostnames = ["pieight.local"]},
			10, { ~hostnames = [
				"pione.local",
				"pitwo.local",
				"pithree.local",
				"pifour.local",
				"pifive.local",
				"pisix.local",
				"piseven.local",
				"pieight.local"
			]},
			11, { ~hostnames = ["127.0.0.1", "127.0.0.1", "127.0.0.1", "127.0.0.1", "127.0.0.1", "127.0.0.1", "127.0.0.1", "127.0.0.1"]}
		);

		resetAll.(modeButtons);

		// some way to free NetAddr? is it needed?
		~hosts = ~makeHosts.(~hostnames);
		// make local host for fbSender
		~localHost = ~makeLocalHost.();

		// refresh window
		w.refresh;
	}),

	// 8. SHUTDOWN BUTTON
	shutdown = Button()
	.states_([
		["SHUTDOWN REMOTE SERVER", Color.black, Color.cyan]
	])
	.action_( {
		~shutdownRemoteServer.();
		// TURN OFF ALL MODES
		resetAll.(modeButtons);
		// turn off local sender
		~localHost.sendMsg( "/endProgram");
		// reset netState
		netState.valueAction_(0);
		"SHUTTING DOWN REMOTE SERVER".postln;
	});
));

// ADD BUTTONVIEW LAYOUT AND ITEMS

modeButtonsView.layout_( HLayout());

modeButtons = [

	// 1. SENSOR PROGRAM STATE
	sensorState = Button()
	.states_([
		["SENSOR PRGM IS ON ", Color.black, Color.red],
		["SENSOR PRGM IS OFF", Color.black, Color.green]
	])
	.action_( {
		arg butt;
		// TURN SENSOR PROGRAM ON/OFF
		if( butt.value == 1, { ~sensorInit.() }, { ~sensorShutdown.() } );
		["SENSOR PROGRAM STATE:", butt.value].postln;
	}),

	// 2. SENSOR PINGING STATE
	sensorPingingState = Button()
	.states_([
		["SENSORS NOT PINGING", Color.black, Color.red],
		["SENSORS PINGING    ", Color.black, Color.green]
	])
	.action_( {
		arg butt;
		// ONLY ACTIVATE IF SENSORS ARE ALREADY TURNED ON
		if( sensorState.value == 1,
			{
				// TURN PINGING ON/OFF
				if( butt.value == 1, { ~pingSensors.() }, { ~unpingSensors.() });
			},
			{
				"TURN SENSORS ON FIRST".postln;
				butt.value_(0);
		});
		["SENSOR PINGING STATE:", butt.value].postln;
	}),

	// 2. PULSE MODE
	pulseState = Button()
	.states_([
		["PULSE MODE IS OFF", Color.black, Color.red],
		["PULSE MODE IS ON ", Color.black, Color.green]
	])
	.action_( {
		arg butt;
		if( butt.value == 1,
			{
				// TURN ON
				~setAndTurnPulseOn.();
				// TURN ALL THE OTHER MODES OFF
				turnOffOtherModes.(butt, modeButtons);
			},
			{
				// TURN OFF
				~turnPulseOff.();
		});
		["PULSE STATE:", butt.value].postln;
	}),

	// 3. TERNARY CODE
	ternaryState = Button()
	.states_([
		["TERNARY MODE IS OFF", Color.black, Color.red],
		["TERNARY MODE IS ON ", Color.black, Color.green]
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
						turnOffOtherModes.(butt, modeButtons);
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
	}),

	// 4. ROOM PITCH/BLUEPRINT MODE
	roomPitchState = Button()
	.states_([
		["ROOM MODE IS OFF", Color.black, Color.red],
		["ROOM MODE IS ON ", Color.black, Color.green]
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
						turnOffOtherModes.(butt, modeButtons);
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
	}),

	// 5. FIELD RECORDING MODE
	fieldPlayState = Button()
	.states_([
		["FIELDPLAY MODE IS OFF", Color.black, Color.red],
		["FIELDPLAY MODE IS ON ", Color.black, Color.green]
	])
	.action_( {
		arg butt;
		// ONLY ACTIVATE IF SENSORS ARE ALREADY TURNED ON
		if( sensorState.value == 1,
			{
				if( butt.value == 1,
					{
						// TURN ON
						turnOffOtherModes.(butt, modeButtons);
						// INSERT FUNC HERE
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
	}),

	// 6. FEEDBACK MODE
	feedbackState = Button()
	.states_([
		["FB MODE IS OFF", Color.black, Color.red],
		["FB MODE IS ON ", Color.black, Color.green]
	])
	.action_( {
		arg butt;
		if( butt.value == 1,
			{
				// TURN ON
				// TURN ALL THE OTHER MODES OFF
				turnOffOtherModes.(butt, modeButtons);
				// SEND WHATEVER UPDATE IS NEEDED TO PIS HERE
				"FEEDBACK ON".postln;
				// turn on pi receivers
				~setFeedbackReceivers.(1);
				fbButtonsView.children.do( { arg fbButt; fbButt.valueAction_(1); });
				// turn on sender
				~setLocalSender.(~localHost, 1);

			},
			{
				// TURN OFF
				// SEND WHATEVER UPDATE IS NEEDED TO PIS HERE
				"FEEDBACK OFF".postln;
				// turn off pi receivers
				~setFeedbackReceivers.(0);
				fbButtonsView.children.do( { arg fbButt; fbButt.valueAction_(0); });
				// turn off sender
				~setLocalSender.(~localHost, 0);
		});
		["FEEDBACK STATE:", butt.value].postln;
	}),

	// 7. ALARM MODE
	alarmState = Button()
	.states_([
		["ALARM MODE IS OFF", Color.black, Color.red],
		["ALARM MODE IS ON ", Color.black, Color.green]
	])
	.action_( {
		arg butt;
		var numAlarms = rrand(1, 2); // 1 or 2
		if( butt.value == 1,
			{
				// TURN ON
				turnOffOtherModes.(butt, modeButtons);
				// INSERT FUNC HERE
				~wallAlarms = ~getAlarmWalls.(numAlarms); // ~wallAlarms needs to be global to be turned off later
				~wallAlarms.postln;
				~turnAlarmOn.(~wallAlarms);
			},
			{
				// TURN OFF
				~turnAlarmOff.(~wallAlarms);
		});
		["ALARM STATE:", butt.value].postln;
	}),

	// 8. ADD ANY HYBRID MODES LIKE THIS
	hybridState = Button()
	.states_([
		["HYBRID MODE IS OFF", Color.black, Color.red],
		["HYBRID MODE IS ON ", Color.black, Color.green]
	])
	.action_( {
		arg butt;
		var numAlarms = rrand(2, 3);
		if( butt.value == 1,
			{
				// TURN ON
				// TURN ALL THE OTHER MODES OFF
				turnOffOtherModes.(butt, modeButtons);
			},
			{
				// TURN OFF
				"TURNING OFF".postln;
		});
		["HYBRID STATE:", butt.value].postln;
	})
];

// add them all to the view
modeButtons.do{
	arg butt, i;
	modeButtonsView.layout.add(butt);
};


fbButtonsView.layout_( HLayout());
// make buttons for individual FB state control

//
gainView.layout_( HLayout() );

gainCtl = ControlSpec(0.0001, 0.9, \lin, 0.0001, 0.9);

masterGain = Slider.new()
.orientation_(\horizontal)
.thumbSize_(50)
.value_(0.9)
.action_({
	arg slider;
	var gainVal;
	gainVal = gainCtl.map(slider.value);

	// send function
	~setMasterGain.(gainVal);
});

// add master gain slider
gainView.layout.add(masterGain);


//-----------------------------------------------------------------------------------
// STATE BUTTONS
//-----------------------------------------------------------------------------------

//-----------------------------------------------------------------------------------
// MIDI
//-----------------------------------------------------------------------------------


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
	if( (num == sendCtl) && (val==127),
		{
			var synthNum = 1, gain=0.2; // change this if needed

			// compute freqs and send USING BUTTON ACTION
			{sensorState.valueAction_(1)}.defer;
			{Routine{
				0.5.wait;
				{ternaryState.valueAction_(1)}.defer;
			}.play;
			}.defer;
		};
	);

	// add a control for ternary mode on/off here
});


MIDIdef.cc( \bpCtl, {
	// ctl 42
	arg val, num, chan, src;
	var ctlOffset=0, sendCtl=41, freqs;
	if( (num == 42 && val==127), {
		// CALL BUTTON ACTION
		{sensorState.valueAction_(1)}.defer;
			{Routine{
				0.5.wait;
				{roomPitchState.valueAction_(1)}.defer;
			}.play;
			}.defer;
	});
});
)