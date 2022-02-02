SinOsc s => Envelope e => Pan2 p => dac;

0.9 => dac.gain;

1.0 => p.pan;

while( true ) {
    e.keyOn();
    2::second => now;
    e.keyOff();
    1::second => now;
    p.pan() * -1 => p.pan;
}