/*
ADD THIS AS A LOCAL HOST IN SC
ADD STATE VAR FOR SENDER
ADD FUNCTION FOR FB MODE TO START SENDING/STOP SENDING
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

// constants
512 => int BUFFER_SIZE;

// --------------------------------------------------------------
// osc out ------------------------------------------------------
// --------------------------------------------------------------

// ip addresses
[
"127.0.0.1"
//"pione.local",
//"pitwo.local",
//"pithree.local",
//"pifour.local",
//"pifive.local",
//"pisix.local",
//"piseven.local",
//"pieight.local"
] @=> string IP[];

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
7400 => in.port;
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

// we'll try this out
dur delayLength[NUM_PIS];
float threshold[NUM_PIS];


// --------------------------------------------------------------
// FUNCTIONS
// --------------------------------------------------------------

// envelope follower
fun void envelopeFollower(int i) {
	// loops until the decibel limit is reached
	while (true) {
		while (Std.rmstodb(pole[i].last()) < threshold[i]) {
			1::samp => now;
		}
		<<< "Sound.", "" >>>;

		send(i);
		now => time past;

		while (now < past + packetLength[i]) {
			send(i);
		}
	}
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

// --------------------------------------------------------------
// initialize ---------------------------------------------------
// --------------------------------------------------------------

for (0 => int i; i < NUM_PIS; i++) {
	// sound chain
	//SinOsc mic => gain[i] => res[i] => del[i] => blackhole;
    adc => gain[i] => res[i] => del[i] => blackhole;
	//mic => gain[i] => lp[i] => hp[i] => del[i] => blackhole;
	//mic => gain[i] => del[i] => blackhole;
	adc => pole[i] => blackhole;

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
	10 => threshold[i];

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

// --------------------------------------------------------------
// loop forever
// --------------------------------------------------------------

while (true) {
	1::ms => now;
}
