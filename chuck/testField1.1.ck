// just throw a limiter at the end and it should be fine
// the sensor could be simply mapped to Q as the gain would already be maxed out and the limiter would automatically engage less as it can

SndBuf buf => Envelope bufEnv => BPF filter => Gain makeUpGain => Dyno limiter => dac;

me.dir() + "../audio/interiors/3.wav" => buf.read;


90.0 => makeUpGain.gain;
filter.set(500.0, 0.58); // 0.58 def
//comp.compress();
limiter.limit();

bufEnv.keyOn();
while( true ) {
    2::second => now;
    Math.random2f(250.0, 5000.0) => filter.freq;
    Math.random2f(2.0, 9.0) => filter.Q;
    makeUpGain.gain() + 0.5 => makeUpGain.gain;
    <<< filter.freq(), filter.Q() >>>;
}
