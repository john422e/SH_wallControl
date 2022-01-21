"""
dummyDistance.py

imitates the behavior of oscDistance.py for testing:
waits for ping and sends back value

NEED TO UPDATE oscDistance.py with some of the cleaning up I did here
"""

# standard imports
import socket, argparse, random, time
from datetime import datetime, timedelta

# osc imports
from pythonosc import dispatcher, osc_server, osc_message_builder, udp_client

def send(self):
    packet = osc_message_builder.OscMessageBuilder(address=sendAddress)

    # adds distance reading to the OSC message
    packet.add_arg(100.0, arg_type='f')

    # completes the OSC message
    packet = packet.build()

    # sends distance back to the host
    client.send(packet)


if __name__ == "__main__":
    # osc vars
    pingAddress = "/w"
    sendAddress = "/distance"
    localIP = "127.0.0.1"
    rcvPort = 5000
    sendPort = 12345

    # sets up arguments for the dispatcher
    parser = argparse.ArgumentParser()
    parser.add_argument("--hostIp",
                        type=str, default=localIP, help="The IP address to send back to")
    parser.add_argument("--hostPort",
                        type=int, default=sendPort, help="The port to send back to")
    args = parser.parse_args()

    # this IP is set to send out
    client = udp_client.UDPClient(args.hostIp, args.hostPort)

    # the thread that listens for the OSC messages
    dispatcher = dispatcher.Dispatcher()
    dispatcher.map(pingAddress, send) # runs send() when receiving "/w"

    # the server we're listening on
    server = osc_server.ThreadingOSCUDPServer(
        (localIP, rcvPort), dispatcher)

    print(f"Serving on {localIP} on port {rcvPort}")
    print(f"Sending back to {localIP} to port {sendPort}")

    # here we go!
    server.serve_forever()
