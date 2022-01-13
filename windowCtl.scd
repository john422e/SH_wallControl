(
var wWidth=1000, wHeight=800, title="SOUND HOUSE";
var modeButton;

~modes = ['ternaryCode', 'fieldPlay', 'feedback'];
~currentMode = ~modes[0];

// BUILD WINDOW -----------------------------------------------------------------------------------
Window.closeAll;
w = Window(title, Rect(0, 200, wWidth, wHeight))
.front
.alwaysOnTop_(true);
w.onClose_( {
	"FILE CLOSED".postln;
	} );
w.view.decorator_(FlowLayout(w.bounds, 10@10, 10@10));

modeButton = Button(w, Rect(20, 20, 100, 20))
.states_([
	["TERNARY CODE", Color.black, Color.red],
	["FIELD PLAY", Color.black, Color.blue],
	["FEEDBACK", Color.black, Color.orange]
])
.action_( {
	arg butt;


)


(
w = Window.new("The Four Noble Truths");

b = Button(w, Rect(20, 20, 340, 30))
        .states_([
            ["there is suffering", Color.black, Color.red],
            ["the origin of suffering", Color.white, Color.black],
            ["the cessation of suffering", Color.red, Color.white],
            ["there is a path to cessation of suffering", Color.blue, Color.clear]
        ])
        .action_({ arg butt;
            butt.value.postln;
        });
w.front;
)

b.value_(3);