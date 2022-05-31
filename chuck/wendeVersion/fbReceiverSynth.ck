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
"fbReceiverSynth.ck" => string fn;
1 => int synthState; // DEFAULT TO ON SINCE IT WILL BE TURNED ON/OFF BY serverMaster.ck

// -----------------------------------------------------------------------------
// OSC
// -----------------------------------------------------------------------------
OscIn inData;
OscIn inSound;
OscMsg msgData;
OscMsg msgSound;

10000 => int dataPort;
dataPort => inData.port;
10001 => int soundPort;
soundPort => inSound.port;
inData.listenAll();
inSound.listenAll();

// -----------------------------------------------------------------------------
// AUDIO
// -----------------------------------------------------------------------------

Step st => Envelope stEnv => JCRev rev => Gain stGain => Dyno limiter => Pan2 stPan => dac;
//Step st => Envelope stEnv => Gain stGain => Dyno limiter => JCRev rev => Pan2 stPan => dac; // put rev later in chain
0.9 => dac.gain;

// CAN PLAY WITH THESE SETTINGS
0.5 => rev.mix;
0.3 => stGain.gain;
limiter.limit();
0.2 => limiter.thresh;

// constant
512 => int bufferSize;

// -----------------------------------------------------------------------------
// RECEIVER FUNC
// -----------------------------------------------------------------------------

fun void oscListenerData() {
    <<< fn, "FB RECEIVER SYNTH LISTENING FOR DATA ON PORT:", dataPort >>>;
    while (running) {
        inData => now;
        while (inData.recv(msgData)) {
            <<< fn, "DATA", msgData.address >>>;
            // set synthState
            if( msgData.address == "/fbSynthState" ) {
                <<< msgData.address, msgData.getInt(0) >>>;
                msgData.getInt(0) => synthState;
            };
            if( msgData.address == "/masterGain") msgData.getFloat(0) => dac.gain;
            // end program
            if( msgData.address == "/endProgram" ) 0 => running;
            1::samp => now;
        }
    }
}

fun void oscListenerSound() {
    <<< fn, "FB RECEIVER SYNTH LISTENING FOR SOUND ON PORT:", soundPort >>>;
    while( running) {
        inSound => now;
        while( inSound.recv(msgSound)) {
            <<< fn, "SOUND", msgSound.address >>>;
            // ONLY CHECK IF synthState == 1
            if( synthState == 1 ) {
                // receive packet of audio samples
                if (msgSound.address == "/m") {
                    <<< "received sound" >>>;

                    // turn it on
                    stGain.gain(1.0);
                    stEnv.keyOn();

                    // start the sample playback
                    for (0 => int i; i < bufferSize; i++) {
                        msgSound.getFloat(i) => st.next;
                        1::samp => now;
                    }

                    // turn it off
                    //stGain.gain(0.0);
                    stEnv.keyOff();
                }

                if (msgSound.address == "/bufferSize") {
                    msgSound.getInt(0) => bufferSize;
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

spork ~ oscListenerData();
spork ~ oscListenerSound();

while( running ) {
    1::second => now;
}

<<< fn, "stopping" >>>;
