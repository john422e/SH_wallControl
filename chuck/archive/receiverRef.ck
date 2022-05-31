// receiver.ck
// Eric Heep

// osc stuff
OscIn in;
OscMsg msg;

10001 => in.port;
in.listenAll();

Step st => Envelope stEnv => Gain stGain => dac;

// because of distortion
dac.gain(0.9);
stEnv.keyOn();

// constant
512 => int bufferSize;

// loop it
while (true) {
    in => now;
    while (in.recv(msg)) {
        
        // receive packet of audio samples
        if (msg.address == "/m") {
            <<< "received sound", "" >>>;
            stGain.gain(1.0);
            // start the sample playback
            for (0 => int i; i < bufferSize; i++) {
                msg.getFloat(i) => st.next;
                1::samp => now;
            }
            
            //stGain.gain(0.0);
            
        }
        
        if (msg.address == "/bufferSize") {
            msg.getInt(0) => bufferSize;
            <<< "Buffer size set to", bufferSize, "" >>>;
        }
    }
    //1::samp => now;
}
