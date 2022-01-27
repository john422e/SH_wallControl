from osc4py3.as_eventloop import *
from osc4py3 import oscmethod as osm
from osc4py3 import oscbuildparse
from random import randrange
import time

# GLOBALS
running = True
localIP = "127.0.0.1"
sendPort = 10000
rcvPort = 5000
pingAddress = "/setPing"
shutdownAddress = "/shutdown"

dummyDistance = 0
step = 1


pingInterval = 0.25 # in seconds
pingState = 0

def setPing(newPingState):
    # sets ping state to 0 or 1
    print("PYTHON: PING!")

    global pingStates
    pingState = newPingState

def sendDistance(self):
    # sends distance to proper synthNum
    dummyDistance = randrange(0.0, 300.0)
    dummyDistance = float(dummyDistance)
    # build message
    print(dummyDistance)
    msg = oscbuildparse.OSCMessage("/distance", None, [dummyDistance])
    osc_send(msg, "SENDER CLIENT")

def shutdown(self):
    print("SHUTTING SENSOR DOWN")
    running = False

# start the system
osc_startup()

# SERVER-----------------------------------------------
# make server channels to receive packets
osc_udp_server(localIP, rcvPort, "SENSOR PING SERVER")
# assign functions
osc_method(pingAddress, setPing)
osc_method(shutdownAddress, shutdown)
print("d2.py SERVING ON PORT", rcvPort)

# CLIENT-----------------------------------------------
osc_udp_client(localIP, sendPort, "SENDER CLIENT")

# loop and listen
while running:
    osc_process()
    # only fetch distance and send when pingState == 1
    if pingState == 1:
        sendDistance(i)
    time.sleep(pingInterval)

print("EXITING")
# properly close the system
osc_terminate()
