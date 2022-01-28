/*
receiver.ck
for SH@theWende, 2022 - john eagle
expanding on Eric Heep's receiver.ck, 2015
2 synths (chan 1, 2) on each pi
*/

// -----------------------------------------------------------------------------
// GLOBALS
// -----------------------------------------------------------------------------
1 => int running;
0 => int synthState;

// -----------------------------------------------------------------------------
// OSC
// -----------------------------------------------------------------------------
OscIn in;
OscMsg msg;

10001 => int port;
port => in.port;
in.listenAll();

// -----------------------------------------------------------------------------
// AUDIO
// -----------------------------------------------------------------------------

Step st => Envelope stEnv => Gain stGain => Pan2 stPan => dac; // out to both chans?

// constant
512 => int bufferSize;

// -----------------------------------------------------------------------------
// RECEIVER FUNC
// -----------------------------------------------------------------------------

fun void oscListener() {
    <<< "fbReceiverSynth.ck FB RECEIVER SYNTH LISTENING ON PORT:", port >>>;
    while (true) {
        in => now;
        while (in.recv(msg)) {
            // set synthState
            if( msg.address == "/fbSynthState" ) msg.getInt(0) => synthState;
            // end program
            if( msg.address == "/endProgram" ) 0 => running;
            
            // ONLY CHECK IF synthState == 1
            if( synthState == 1 ) {
                // receive packet of audio samples
                if (msg.address == "/m") {
                    <<< "received sound" >>>;
                    
                    // turn it on
                    stGain.gain(1.0);
                    stEnv.keyOn();
                    
                    // start the sample playback
                    for (0 => int i; i < bufferSize; i++) {
                        msg.getFloat(i) => st.next;
                        1::samp => now;
                    }
                    
                    // turn it off
                    stGain.gain(0.0);
                    stEnv.keyOff();
                }
                
                if (msg.address == "/bufferSize") {
                    msg.getInt(0) => bufferSize;
                    <<< "Buffer size set to", bufferSize, "" >>>;
                }
            }                
            1::samp => now;
        }
    }
}

// -----------------------------------------------------------------------------
// MAIN LOOP
// -----------------------------------------------------------------------------

// GET RID OF WHEN FINISHED TESTING
1 => synthState;



spork ~ oscListener();

while( running ) {
    1::second => now;
}

<<< "fbReceiverSynth.ck stopping" >>>;