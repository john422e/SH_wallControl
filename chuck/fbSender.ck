/*

*/


// sender.ck
// Eric Heep

/*
sine tone freq per pi
sine tone gain per pi

mic volume per pi
lookback delay time per pi
packet length per pi
threshold per pi

cutoff freq per pi
resonance Q per pi
envelope length
*/

// -----------------------------------------------------------------------------
// GLOBALS
// -----------------------------------------------------------------------------

"fbSender.ck" => string thisFile;
1 => int running;
0 => int senderState;

// constants
512 => int BUFFER_SIZE;

// --------------------------------------------------------------
// osc out ------------------------------------------------------
// --------------------------------------------------------------

// ip addresses

[
"pione.local",
"pitwo.local",
"pithree.local",
"pifour.local",
"pifive.local",
"pisix.local"
//"piseven.local",
//"pieight.local"
] @=> string IP[];

//[ "127.0.0.1" ] @=> string IP[];

IP.size() => int NUM_IPS;
IP.size() => int NUM_PIS;

// port is the same for all outgoing messages
10000 => int OUT_PORT;

// address is the same for all outgoing messages
"/m" => string ADDRESS;

// osc out to Raspberry Pis
OscOut out[NUM_PIS];

// determines our packet length for outgoing messages
dur packetLength[NUM_PIS];

// --------------------------------------------------------------
// osc in -------------------------------------------------------
// --------------------------------------------------------------

OscIn in;
OscMsg msg;

// the port for the incoming messages
7400 => int IN_PORT;
IN_PORT => in.port;
in.listenAll();

// --------------------------------------------------------------
// microphone audio ---------------------------------------------
// --------------------------------------------------------------

Gain micGain;
Gain gain[NUM_PIS];
HPF hp[NUM_PIS];
LPF lp[NUM_PIS];
ResonZ res[NUM_PIS];
Delay del[NUM_PIS];
OnePole pole[NUM_PIS];
Shred envFollow;

// we'll try this out
dur delayLength[NUM_PIS];
float threshold[NUM_PIS];


// --------------------------------------------------------------
// FUNCTIONS
// --------------------------------------------------------------

// envelope follower
fun void envelopeFollower(int i) {
	// loops until the decibel limit is reached
	while (running) {
        //<<< senderState >>>;
        // this loop is working UNTIL senderState gets updated once, then it gets stuck in block below
        <<< "SENDING" >>>;
        while (Std.rmstodb(pole[i].last()) < threshold[i]) {
            // advance time while mic is below threshold val
            1::samp => now;
        }
        <<< "Sound.", "" >>>;
        
        send(i); // send to one pi at a time
        now => time past;
        // keep sending until whole packet is sent
        while (now < past + packetLength[i]) send(i);
        //1::ms => now;
	}
	//1::ms => now;
}

// sends out audio in 512 sample blocks
fun void send(int i) {
	out[i].start(ADDRESS);

	for (0 => int j; j < BUFFER_SIZE; j++) {
		out[i].add(del[i].last());
		1::samp => now;
	}

	out[i].send();
}

fun void endProgram() {
    <<< thisFile, "END PROGRAM" >>>;
    // ends loop and stops program
    0 => running;
}

// receiver function -> everything is triggered from this
fun void oscListener() {
  <<< thisFile, "FEEDBACK SENDER LISTENING ON PORT:", IN_PORT >>>;

  while( true ) {
    in => now; // wait for a message
    while( in.recv(msg)) {
        //<<< thisFile, msg.address, msg.getInt(0) >>>;

        // global state, arg = 0 or 1 for on/off
        if( msg.address == "/senderState" ) msg.getInt(0) => senderState;

        // end program
        if( msg.address == "/endProgram" ) endProgram();

    }
  }
}

// --------------------------------------------------------------
// initialize ---------------------------------------------------
// --------------------------------------------------------------

for (0 => int i; i < NUM_PIS; i++) {
    // sound chain
	//SinOsc mic => gain[i] => res[i] => del[i] => blackhole;
    adc.chan(0) => gain[i] => res[i] => del[i] => blackhole;
    adc.chan(1) => gain[i];
	//mic => gain[i] => lp[i] => hp[i] => del[i] => blackhole;
	//mic => gain[i] => del[i] => blackhole;
	adc.chan(0) => pole[i] => blackhole;
    adc.chan(1) => pole[i] => blackhole;

	// delay of adc
	100::ms => delayLength[i];

	// delay stuff
	del[i].max(100::ms);
	del[i].delay(100::ms);

	hp[i].freq(0.1);
	lp[i].freq(10000.0);

	// following
	3 => pole[i].op;
	0.9999 => pole[i].pole;

	// thresholds in decibels
	25 => threshold[i]; // started at 10, try going higher?

	// this determines how much audio is send through in milliseconds
	500::ms => packetLength[i];
}

for (0 => int i; i < NUM_IPS; i++) {
	// start the envelope follower
	spork ~ envelopeFollower(i);

	// set ip and port for each osc out
	out[i].dest(IP[i], OUT_PORT);

	// set buffer_size
	out[i].start("/bufferSize");
	out[i].add(BUFFER_SIZE);
	out[i].send();

}

// start OSC server
spork ~ oscListener();

// --------------------------------------------------------------
// loop forever
// --------------------------------------------------------------

while (running) {
	1::second => now;
}
