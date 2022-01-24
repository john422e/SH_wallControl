from osc4py3.as_eventloop import *
from osc4py3 import oscmethod as osm
from osc4py3 import oscbuildparse
from random import randrange
import time

# GLOBALS
localIP = "127.0.0.1"
sendPort = 10000
rcvPort = 5000
pingAddress = "/w"

finished = False
dummyDistance = 0
step = 1


pingInterval = 0.25 # in seconds
pingStates = [0, 0]

def setPing(synthNum, newPingState):
    # sets ping state to 0 or 1
    print("PYTHON: PING!")

    global pingStates
    pingStates[synthNum] = newPingState

def sendDistance(synthNum):
    # sends distance to proper synthNum
    dummyDistance = randrange(0.0, 300.0)
    dummyDistance = float(dummyDistance)
    # build message
    print(dummyDistance)
    msg = oscbuildparse.OSCMessage("/distance", None, [synthNum, dummyDistance])
    osc_send(msg, "SENDER CLIENT")

def shutdown():
    print("SHUTTING SENSOR DOWN")
    finished = True

# start the system
osc_startup()

# SERVER-----------------------------------------------
# make server channels to receive packets
osc_udp_server(localIP, rcvPort, "SENSOR PING SERVER")
# assign functions
osc_method(pingAddress, setPing)
osc_method("/shutdown", shutdown)
print("SERVING ON PORT", rcvPort)

# CLIENT-----------------------------------------------
osc_udp_client(localIP, sendPort, "SENDER CLIENT")

# loop and listen
while not finished:
    osc_process()
    for i, pingState in enumerate(pingStates):
        if pingState == 1:
            sendDistance(i)
    time.sleep(pingInterval)

print("EXITING")
# properly close the system
osc_terminate()
