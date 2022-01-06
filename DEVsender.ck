 // sender.ck
// John Eagle, expanding on Eric Heep's sender.ck, 2015

// constants
512 => int BUFFER_SIZE;

// --------------------------------------------------------------
// osc out ------------------------------------------------------
// --------------------------------------------------------------

// ip address
"eagle2018.local" => string IP;

// port is the same for all outgoing messages
10001 => int OUT_PORT;

// address is the same for all outgoing messages
"/m" => string ADDRESS;

// osc out to Raspberry Pis
OscOut out;


// --------------------------------------------------------------
// initialize ---------------------------------------------------
// --------------------------------------------------------------

// sound chain

//adc 
SinOsc s => Gain micGain => Envelope micEnv => Delay del => blackhole;

// env follower
micGain => OnePole pole => blackhole;
// delayed signal
// add HPF and LPF later


//0.5 => gain.gain;
// delay stuff
100::ms => dur delayLength;
del.max(100::ms);
del.delay(100::ms);

// following
3 => pole.op; // mul mode
0.9999 => pole.pole;

// thresholds in decibels
//10 => float threshold;

// this determines how much audio is send through in milliseconds
500::ms => dur packetLength;

// set ip and port for osc out
out.dest(IP, OUT_PORT);

// set buffer_size
out.start("/bufferSize");
out.add(BUFFER_SIZE);
out.send();


fun void envFollower() {
	while( true ) {
		if( pole.last() > 0.01 ) {
			<<< "BANG" >>>;
			80::ms => now;
		}
		//else <<< pole.last() >>>;
		20::ms => now;
	}
}

//spork ~ envFollower();

// sends out audio in 512 sample blocks

fun void send() {
	// add address to message
	out.start(ADDRESS);
	
	// add last 512 samples from del
	for (0 => int j; j < BUFFER_SIZE; j++) {
        out.add( pole.last() );
		1::samp => now; // 2::samp => now;
    }
	// send it
    out.send();
}


micEnv.keyOn();
// loop it
while (true) {
	send();
	//100::ms => now;
}
