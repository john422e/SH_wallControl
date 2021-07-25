SinOsc s1 => dac.chan(0);
SinOsc s2 => dac.chan(1);

0.2 => s1.gain => s2.gain;

330 => s1.freq;
440 => s2.freq;

60::second => now;