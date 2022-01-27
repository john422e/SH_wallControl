(
var wWidth=1200, wHeight=50, title="SOUND HOUSE";
var ternaryStateButton, pulseStateButton, fieldPlayStateButton, feedbackStateButton, alarmStateButton;

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

// 1. PULSE MODE
~pulseState = 0; // set a global binary var for each mode
pulseStateButton = Button(w, 170@30)
.states_([
	["PULSE MODE IS OFF", Color.black, Color.red],
	["PULSE MODE IS ON", Color.black, Color.green]
])
.action_( {
	arg butt;
	if( ~pulseState == 0,
		{
			// TURN ON
			~pulseState = 1;
			// SEND WHATEVER UPDATE IS N EEDED TO PIS HERE
			~setAndTurnPulseOn.();
		},
		{
			// TURN OFF
			~pulseState = 0;
			// SEND WHATEVER UPDATE IS NEEDED TO PIS HERE
			~turnPulseOff.();
	});
	["PULSE STATE:", ~pulseState].postln;
});

// 2. TERNARY CODE
~ternaryState = 0;
ternaryStateButton = Button(w, 160@30)
.states_([
	["TERNARY MODE IS OFF", Color.black, Color.red],
	["TERNARY MODE IS ON", Color.black, Color.green]
])
.action_( {
	arg butt;
	if( ~ternaryState == 0,
		{
			var synthNum=1, gain=0.5; // change this if needed
			// TURN ON
			~ternaryState = 1;
			// SEND WHATEVER UPDATE IS NEEDED TO PIS HERE
			~sendSines.(~ternaryFreqs, synthNum, 1, gain);
		},
		{
			// TURN OFF
			~ternaryState = 0;
			// SEND WHATEVER UPDATE IS NEEDED TO PIS HERE
			~turnSinesOff.(0); // turn off both synths
			~turnSinesOff.(1);

	});
	["TERNARY STATE:", ~ternaryState].postln;
});

// 3. ROOM PITCH/BLUEPRINT MODE
~roomPitchState = 0;
ternaryStateButton = Button(w, 180@30)
.states_([
	["ROOM PITCH MODE IS OFF", Color.black, Color.red],
	["ROOM PITCH MODE IS ON", Color.black, Color.green]
])
.action_( {
	arg butt;
	if( ~roomPitchState == 0,
		{
			var synthNum=0, gain=0.5, freqs; // change this if needed
			// TURN ON
			~roomPitchState = 1;
			// SEND WHATEVER UPDATE IS NEEDED TO PIS HERE
			// get random freqs
			freqs = ~getRoomPitches.();
			~sendSines.(freqs, synthNum, 2, gain); // try 2 harmonic synth?
		},
		{
			// TURN OFF
			~roomPitchState = 0;
			// SEND WHATEVER UPDATE IS NEEDED TO PIS HERE
			~turnSinesOff.(0); // turn off both synths
			~turnSinesOff.(1);

	});
	["TERNARY STATE:", ~ternaryState].postln;
});

~fieldPlayState = 0;
fieldPlayStateButton = Button(w, 170@30)
.states_([
	["FIELDPLAY MODE IS OFF", Color.black, Color.red],
	["FIELDPLAY MODE IS ON", Color.black, Color.green]
])
.action_( {
	arg butt;
	if( ~fieldPlayState == 0,
		{
			// TURN ON
			~fieldPlayState = 1;
			// SEND WHATEVER UPDATE IS NEEDED TO PIS HERE
			~turnFieldPlayOn.(~getSoundFiles.("interiors"), 0);
			~turnFieldPlayOn.(~getSoundFiles.("exteriors"), 1);
			~setFieldPlayRandUpdates.(true, 0);
			~setFieldPlayRandUpdates.(true, 1);
		},
		{
			// TURN OFF
			~fieldPlayState = 0;
			// SEND WHATEVER UPDATE IS NEEDED TO PIS HERE
			~setFieldPlayRandUpdates.(false, 0);
			~setFieldPlayRandUpdates.(false, 1);
			~turnFieldPlayOff.(0);
			~turnFieldPlayOff.(1);
	});
	["FIELDPLAY STATE:", ~fieldPlayState].postln;
});


~feedbackState = 0;
feedbackStateButton = Button(w, 170@30)
.states_([
	["FEEDBACK MODE IS OFF", Color.black, Color.red],
	["FEEDBACK MODE IS ON", Color.black, Color.green]
])
.action_( {
	arg butt;
	if( ~feedbackState == 0,
		{
			// TURN ON
			~feedbackState = 1;
			// SEND WHATEVER UPDATE IS NEEDED TO PIS HERE
		},
		{
			// TURN OFF
			~feedbackState = 0;
			// SEND WHATEVER UPDATE IS NEEDED TO PIS HERE
	});
	["FEEDBACK STATE:", ~feedbackState].postln;
});

~alarmState = 0;
alarmStateButton = Button(w, 170@30)
.states_([
	["ALARM MODE IS OFF", Color.black, Color.red],
	["ALARM MODE IS ON", Color.black, Color.green]
])
.action_( {
	var numAlarms = rrand(2, 3);
	if( ~alarmState == 0,
		{
			// TURN ON
			~alarmState = 1;
			~wallAlarms = ~getAlarmWalls.(numAlarms); // ~wallAlarms needs to be global to be turned off later
			~wallAlarms.postln;
			~turnAlarmOn.(~wallAlarms);
		},
		{
			// TURN OFF
			~alarmState = 0;
			~turnAlarmOff.(~wallAlarms);
	});
});
)