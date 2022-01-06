(
var port=10002;
~hostnames = [
	//"eagle2018.local"
	"pione.local",
	"pitwo.local",
	"pithree.local",
	"pifour.local",
	"pifive.local",
	"pisix.local",
	"piseven.local",
	"pieight.local",
	//"eagle2018.local"
];
~hosts = Array.new(1);
// set up each host with hostname and port

for( 0, ~hostnames.size-1, {
	arg i;
	var host;
	[~hostnames[i], port].postln;
	host = NetAddr.new(~hostnames[i], port);
	~hosts.add(host);
});
)

~hosts[0].postln;
~hosts[0].sendMsg( '/gain', 1.0);
NetAddr.disconnectAll;
~hosts[0].disconnect;
~hosts;
(
~hostname = "eagle2018.local";
~hosts = [NetAddr.new(~hostname, 10002), NetAddr.new(~hostname, 10003)]
)


~hosts[0].sendMsg( '/sineFreq', 200.0);
~hosts[0].sendMsg( '/sineGain', 0.5);
~hosts[0].sendMsg( '/sinePhase', -8pi); // +- 8pi
~hosts[1].sendMsg( '/print', "SOMETHING");
(
~hosts.do( {
	arg host;
	host.sendMsg( '/modFreq', 1.0);
	//host.sendMsg( '/carrFreq', 800.0);
	host.sendMsg( '/gain', 0.4);
	host.sendMsg( '/sinModOn' );
	host.sendMsg( '/pulseModOn' );
	host.sendMsg( '/noteOn' );
	host.sendMsg( '/noteOff' );
});
)
~hosts
~hosts[0].sendMsg( '/noteOn' );
~hosts[1].sendMsg( '/noteOn' );

~hosts[0].sendMsg( '/carrFreq', 700.0 );
~hosts[1].sendMsg( '/carrFreq', 800.0 );

~hosts[1].sendMsg( 'mod1Phase', -pi );

~hosts[0].sendMsg( '/modFreq', 2.0);
~hosts[1].sendMsg( '/modFreq', 2.0);
~hosts[0].sendMsg( '/carrFreq', 830.0);
~hosts[0].sendMsg( '/modFreq', 3.0);
~hosts[0].sendMsg( '/gain', 0.15);
~hosts[0].sendMsg( '/sinModOn' );
~hosts[0].sendMsg( '/pulseModOn' );
~hosts[0].sendMsg( '/noteOn' );
~hosts[0].sendMsg( '/noteOff' );
~hosts[0].sendMsg( '/modPhase', 8pi);

-pi.postln;

(
~hostname = "eagle2018.local";
~host = NetAddr.new(~hostname, 10001);
)

~host.sendMsg( '/distance', 45.0);
~host.sendMsg( '/distance', (35/2) + 10);
~host.sendMsg( '/distance', rrand(10.0, 45.0) );
~host.sendMsg( '/newGroup' );