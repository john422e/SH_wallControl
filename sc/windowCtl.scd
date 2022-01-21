(
var wWidth=1000, wHeight=800, title="SOUND HOUSE";
var ternaryStateButton, fmPulseStateButton, fieldPlayStateButton, feedbackStateButton;

//-----------------------------------------------------------------------------------
// BUILD WINDOW
//-----------------------------------------------------------------------------------
Window.closeAll;
w = Window(title, Rect(0, 200, wWidth, wHeight))
.front
.alwaysOnTop_(true);
w.onClose_( {
	"FILE CLOSED".postln;
	} );
w.view.decorator_(FlowLayout(w.bounds, 10@10, 10@10));

//-----------------------------------------------------------------------------------
// STATE BUTTONS
//-----------------------------------------------------------------------------------

// set a global binary var for each mode
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
			var synthNum; // change this if needed
			// TURN ON
			~ternaryState = 1;
			// SEND WHATEVER UPDATE IS NEEDED TO PIS HERE
			~sendSines.(~ternaryFreqs, Array.fill(8, { synthNum }), Array.fill(8, { 1 }), Array.fill(8, { 1.0 }));
		},
		{
			var synthNum; // change this if needed
			// TURN OFF
			~ternaryState = 0;
			// SEND WHATEVER UPDATE IS NEEDED TO PIS HERE
			~turnSinesOff.(Array.fill(8, { synthNum }));

	});
	["TERNARY STATE:", ~ternaryState].postln;
});

~fmPulseState = 0;
fmPulseStateButton = Button(w, 170@30)
.states_([
	["FM PULSE MODE IS OFF", Color.black, Color.red],
	["FM PULSE MODE IS ON", Color.black, Color.green]
])
.action_( {
	arg butt;
	if( ~fmPulseState == 0,
		{
			// TURN ON
			~fmPulseState = 1;
			// SEND WHATEVER UPDATE IS NEEDED TO PIS HERE
			~getAndSendPhasePulse.();
		},
		{
			// TURN OFF
			~fmPulseState = 0;
			// SEND WHATEVER UPDATE IS NEEDED TO PIS HERE
			~turnPulseOff.();
	});
	["FM PULSE STATE:", ~fmPulseState].postln;
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
		},
		{
			// TURN OFF
			~fieldPlayState = 0;
			// SEND WHATEVER UPDATE IS NEEDED TO PIS HERE
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
)