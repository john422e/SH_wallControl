 // sender.ck
// John Eagle, expanding on Eric Heep's sender.ck, 2015

// constants
512 => int BUFFER_SIZE;


// --------------------------------------------------------------
// osc out ------------------------------------------------------
// --------------------------------------------------------------

// ip address
//"eagle2018.local" => string IP;
"pione.local" => string IP;

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
adc => Envelope micEnv => ResonZ res => Delay del => blackhole;
// env follower
micEnv => OnePole pole => blackhole;
// delay of sig
100::ms => dur delayLength;
5::ms => delayLength;
del.max(100::ms);
del.delay(100::ms);

// following
3 => pole.op; // mul mode
0.9999 => pole.pole;

// thresholds in decibels
1 => float threshold;

// this determines how much audio is send through in milliseconds
100::ms => dur packetLength;

// set ip and port for osc out
out.dest(IP, OUT_PORT);

// set buffer_size
out.start("/bufferSize");
out.add(BUFFER_SIZE);
out.send();


// this runs the show
spork ~ envelopeFollower();




// envelope follower
fun void envelopeFollower() {
    // loops until the db limit is reached
    while( true ) {
        while( Std.rmstodb(pole.last()) < threshold ) {
            1::samp => now;
        }
        <<< "SOUND", "" >>>;
        send();
        now => time past;
        
        while( now < past + packetLength ) {
            send();
        }
    }
}


// sends out audio in 512 sample blocks

fun void send() {
	// add address to message
	out.start(ADDRESS);
	
	// add last 512 samples from del
	for (0 => int j; j < BUFFER_SIZE; j++) {
        out.add( del.last() );
		1::samp => now;
    }
	// send it
    out.send();
}


micEnv.keyOn();
// loop it
while (true) {
    1::ms => now;
	//100::ms => now;
}
