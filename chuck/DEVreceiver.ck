// receiver.ck
// John Eagle, expanding on Eric Heep's receiver.ck, 2015

// osc stuff
OscIn in;
OscMsg msg;

10001 => in.port;
in.listenAll();

Step st => Gain stGain => dac;

// constant
512 => int bufferSize;

// loop it
while (true) {
    in => now;
    while (in.recv(msg)) {
        // receive packet of audio samples
        if (msg.address == "/m") {
			<<< "received sound" >>>;
			
			// turn it on
            stGain.gain(1.0);
            
            // start the sample playback
            for (0 => int i; i < bufferSize; i++) {
                msg.getFloat(i) => st.next;
                1::samp => now;
            }
			
			// turn it off
            stGain.gain(0.0);
        }

        if (msg.address == "/bufferSize") {
            msg.getInt(0) => bufferSize;
            <<< "Buffer size set to", bufferSize, "" >>>;
        }


    }
    1::samp => now;
}
