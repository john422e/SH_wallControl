"""
dummyDistance.py

imitates the behavior of oscDistance.py for testing:
waits for ping and sends back value

NEED TO UPDATE oscDistance.py with some of the cleaning up I did here
"""

# standard imports
import socket, argparse, random, time
from datetime import datetime, timedelta
import asyncio

# osc imports
from pythonosc import dispatcher, osc_server, osc_message_builder, udp_client


dummyDistance = 0
step = 1

def send(self, synthNum):
    print("PYTHON: PING!")
    min = 0
    max = 300

    #global dummyDistance
    #global step



    dummyDistance = random.randrange(0, 300)
    """
    if dummyDistance == min:
        step = 1
    elif dummyDistance == max:
        step = -1
    """
    packet = osc_message_builder.OscMessageBuilder(address=sendAddress)

    # adds distance reading to the OSC message
    packet.add_arg(synthNum, arg_type='i')
    packet.add_arg(dummyDistance, arg_type='f')

    # completes the OSC message
    packet = packet.build()

    # sends distance back to the host
    client.send(packet)

    #dummyDistance += step

def shutdown(self):
    global server
    print("SHUTTING DOWN FROM PYTHON")
    #server.shutdown()
    server.server_close()

if __name__ == "__main__":
    # osc vars
    pingAddress = "/w"
    sendAddress = "/distance"
    localIP = "127.0.0.1"
    rcvPort = 5000
    sendPort = 10000

    # sets up arguments for the dispatcher
    hostParser = argparse.ArgumentParser()
    hostParser.add_argument("--hostIp",
                        type=str, default=localIP, help="The IP address to send back to")
    hostParser.add_argument("--hostPort",
                        type=int, default=sendPort, help="The port to send back to")
    args = hostParser.parse_args()

    # this IP is set to send out
    client = udp_client.UDPClient(args.hostIp, args.hostPort)

    # server args
    serverParser = argparse.ArgumentParser()
    serverParser.add_argument("--ip", type=str, default=localIP, help="LISTEN")
    serverParser.add_argument("--port", type=int, default=rcvPort, help="LISTEN")
    serverArgs = serverParser.parse_args()

    # the thread that listens for the OSC messages
    dispatcher = dispatcher.Dispatcher()
    dispatcher.map(pingAddress, send) # runs send() when receiving "/w"
    dispatcher.map("/shutdown", shutdown)

    # the server we're listening on
    server = osc_server.ThreadingOSCUDPServer((serverArgs.ip, serverArgs.port), dispatcher)
    #server = osc_server.BlockingOSCUDPServer((localIP, rcvPort), dispatcher)
    #server = osc_server.ForkingOSCUDPServer((localIP, rcvPort), dispatcher)

    print(f"dummyDistance.py serving on {localIP} on port {rcvPort}")
    print(f"Sending back to {localIP} to port {sendPort}")

    # here we go!
    server.serve_forever()
