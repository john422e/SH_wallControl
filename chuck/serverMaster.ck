<<< "ADDING ALL SYNTHS TO SERVER" >>>;

1 => int running;
"serverMaster.ck" => string fn;

me.dir() => string dir;


// ADD ALL OF THESE FIRST, THEY'RE MANAGED SEPARATELY AFTERWARDS
<<< "STARTING SENSOR CONTROL" >>>;
// sensor control
Machine.add(dir + "sensorSender.ck");

<<< "STARTING PULSE SYNTH" >>>;
// pulse mode
Machine.add(dir + "pulseSynth.ck");

<<< "STARTING STD SYNTH" >>>;
// ternary code + pitch/blueprint mode
Machine.add(dir + "stdSynth.ck");

<<< "STARTING FIELDPLAY SYNTH" >>>;
// fieldplay mode
Machine.add(dir + "testField1.0.ck");
//Machine.add(dir + "fieldPlay.ck");

<<< "STARTING ALARM SYNTH" >>>;
// alarm mode
Machine.add(dir + "alarmSynth.ck");

//1::second => now;

// START A SERVER TO CONTROL FB RECEIVER

// OSC
OscIn in;
OscMsg msg;
10000 => int port;
port => in.port;
in.listenAll();

int fbState;
int fbid;

fun void oscListener() {
    <<< fn, "LISTENING ON PORT:", port >>>;
    while( true ) {
        in => now; // wait for message
        while( in.recv(msg) ) {
            if( msg.address == "/fbReceiverState" ) {
                msg.getInt(0) => fbState;
                if( fbState == 1 ) {
                    // FB MODE
                    Machine.add(dir + "fbReceiverSynth.ck") => fbid;
                }
                if( fbState == 0) {
                    // TURN FB OFF
                    Machine.remove(fbid);
                }
            }
            if( msg.address == "/endProgram" ) 0 => running;
        }
    }
}


// MAIN
spork ~ oscListener();

while( running ) {
    1::second => now;
}

<<< fn, "stopping" >>>;