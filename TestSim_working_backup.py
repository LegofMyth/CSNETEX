#ANDES Lab - University of California, Merced
#Author: UCM ANDES Lab
#$Author: abeltran2 $
#$LastChangedDate: 2014-08-31 16:06:26 -0700 (Sun, 31 Aug 2014) $
#! /usr/bin/python
import sys
from TOSSIM import *
from CommandMsg import *

class TestSim:
    moteids=[]
    # COMMAND TYPES
    CMD_PING = 0
    CMD_NEIGHBOR_DUMP = 1
    CMD_ROUTE_DUMP=3

    # CHANNELS - see includes/channels.h
    COMMAND_CHANNEL="command";
    GENERAL_CHANNEL="general";

    # Project 1
    NEIGHBOR_CHANNEL="neighbor";
    FLOODING_CHANNEL="flooding";

    # Project 2
    ROUTING_CHANNEL="routing";

    # Project 3
    TRANSPORT_CHANNEL="transport";

    # Personal Debuggin Channels for some of the additional models implemented.
    HASHMAP_CHANNEL="hashmap";

    # Initialize Vars
    numMote=0

    def __init__(self):
        self.t = Tossim([])
        self.r = self.t.radio()

        #Create a Command Packet
        self.msg = CommandMsg()
        self.pkt = self.t.newPacket()
        self.pkt.setType(self.msg.get_amType())

    # Load a topo file and use it.
    def loadTopo(self, topoFile):
        print 'Creating Topo!'
        # Read topology file.
        topoFile = 'topo/'+topoFile
        f = open(topoFile, "r")
        self.numMote = int(f.readline());
        print 'Number of Motes', self.numMote
        for line in f:
            s = line.split()
            if s:
                print " ", s[0], " ", s[1], " ", s[2];
                self.r.add(int(s[0]), int(s[1]), float(s[2]))
                if not int(s[0]) in self.moteids:
                    self.moteids=self.moteids+[int(s[0])]
                if not int(s[1]) in self.moteids:
                    self.moteids=self.moteids+[int(s[1])]

    # Load a noise file and apply it.
    def loadNoise(self, noiseFile):
        if self.numMote == 0:
            print "Create a topo first"
            return;

        # Get and Create a Noise Model
        noiseFile = 'noise/'+noiseFile;
        noise = open(noiseFile, "r")
        for line in noise:
            str1 = line.strip()
            if str1:
                val = int(str1)
            for i in self.moteids:
                self.t.getNode(i).addNoiseTraceReading(val)

        for i in self.moteids:
            print "Creating noise model for ",i;
            self.t.getNode(i).createNoiseModel()

    def bootNode(self, nodeID):
        if self.numMote == 0:
            print "Create a topo first"
            return;
        self.t.getNode(nodeID).bootAtTime(1333*nodeID);

    def bootAll(self):
        i=0;
        for i in self.moteids:
            self.bootNode(i);

    def moteOff(self, nodeID):
        self.t.getNode(nodeID).turnOff();

    def moteOn(self, nodeID):
        self.t.getNode(nodeID).turnOn();

    def run(self, ticks):
        for i in range(ticks):
            self.t.runNextEvent()

    # Rough run time. tickPerSecond does not work.
    def runTime(self, amount):
        self.run(amount*1000)

    # Generic Command
    def sendCMD(self, ID, dest, payloadStr):
        self.msg.set_dest(dest);
        self.msg.set_id(ID);
        self.msg.setString_payload(payloadStr)

        self.pkt.setData(self.msg.data)
        self.pkt.setDestination(dest)
        self.pkt.deliver(dest, self.t.time()+5)

    def ping(self, source, dest, msg):
        self.sendCMD(self.CMD_PING, source, "{0}{1}".format(chr(dest),msg));

    def neighborDMP(self, destination):
        self.sendCMD(self.CMD_NEIGHBOR_DUMP, destination, "neighbor command");

    def routeDMP(self, destination):
        self.sendCMD(self.CMD_ROUTE_DUMP, destination, "routing command");

    def addChannel(self, channelName, out=sys.stdout):
        print 'Adding Channel', channelName;
        self.t.addChannel(channelName, out);

def main():
    s = TestSim();
    # s.runTime(10);
    # s.loadTopo("long_line.topo");
    s.loadTopo("project1.topo")
    # Node 4 exists, but is intentionally isolated.
    # loadTopo() only adds nodes that appear in radio links,
    # so manually include Node 4 in the simulation.
    if 4 not in s.moteids:
        s.moteids.append(4) #added

    s.loadNoise("no_noise.txt");
    s.bootAll();
    # s.addChannel(s.COMMAND_CHANNEL);
    # s.addChannel(s.GENERAL_CHANNEL);
    s.addChannel(s.NEIGHBOR_CHANNEL);
    s.addChannel(s.FLOODING_CHANNEL);

    # s.runTime(20);
    # s.ping(1, 2, "Hello, World");
    # s.runTime(10);
    # s.ping(2, 1, "Back to Node 1") # i added this
    # s.runTime(10) # added this
    # s.ping(1, 3, "Hi!");
    # s.runTime(20);

    # # Before adding 3 <-> 4
    # s.neighborDMP(1)
    # s.neighborDMP(2)
    # s.neighborDMP(3)
    # s.neighborDMP(4)
    # s.runTime(5)

    # # --------------------------------------------------
    # # TEST: Dynamically connect Node 3 and Node 4
    # # --------------------------------------------------

    # print "Adding connection between Node 3 and Node 4"

    # # Add both directions so the connection is bidirectional.
    # # s.r.add(3, 4, -54.0)
    # # s.r.add(4, 3, -54.0)

    # s.runTime(10)

    # # Test Node 3 -> Node 4
    # s.ping(3, 4, "Node 3 to Node 4")
    # s.runTime(10)

    # # Test Node 4 -> Node 3
    # s.ping(4, 3, "Node 4 to Node 3")
    # s.runTime(10)

    # s.neighborDMP(3)
    # s.neighborDMP(4)
    # s.runTime(5)

    # # --------------------------------------------------
    # # TEST: Remove connection between Node 3 and Node 4
    # # --------------------------------------------------
    
    # print "Removing connection between Node 3 and Node 4"
    
    # # Remove both directions.
    # # s.r.remove(3, 4)
    # # s.r.remove(4, 3)
    
    # s.runTime(10)
    
    # # These should NOT arrive now.
    # s.ping(3, 4, "Should not reach Node 4")
    # s.runTime(10)
    
    # s.ping(4, 3, "Should not reach Node 3")
    # s.runTime(10)

    # # s.neighborDMP(1)
    # # s.runTime(1)
    
    # # s.neighborDMP(2)
    # # s.runTime(1)
    
    # # s.neighborDMP(3)
    # # s.runTime(1)
    
    # # s.neighborDMP(4)
    # # s.runTime(1)

    # # s.neighborDMP(3)
    # # s.neighborDMP(4)
    # # s.runTime(5)

    # # Check neighbor tables after removing 3 <-> 4
    # s.neighborDMP(1)
    # s.neighborDMP(2)
    # s.neighborDMP(3)
    # s.neighborDMP(4)

    # s.runTime(5)

    s.runTime(20)

    print "INTEGRATION TEST: Neighbor tables"

    s.neighborDMP(1)
    s.runTime(1)
    
    s.neighborDMP(2)
    s.runTime(1)
    
    s.neighborDMP(3)
    s.runTime(1)
    
    s.neighborDMP(4)
    s.runTime(1)

    print "INTEGRATION TEST: Flood Node 1 -> Node 3"

    s.ping(1, 3, "Integration Test")

    s.runTime(20)

if __name__ == '__main__':
    main()

# def main():

#     s = TestSim()

#     # Use the professor's long-line topology.
#     s.loadTopo("long_line.topo")

#     s.loadNoise("no_noise.txt")
#     s.bootAll()

#     # For this test, only show Flooding output.
#     s.addChannel(s.FLOODING_CHANNEL)

#     # Give all nodes time to boot and start.
#     s.runTime(20)


#     # --------------------------------------------------
#     # TEST 1: Normal multi-hop flooding
#     # Node 1 -> Node 5 = 4 hops
#     # --------------------------------------------------

#     print "TEST 1: Node 1 -> Node 5"

#     s.ping(1, 5, "1 to 5")

#     s.runTime(20)


#     # --------------------------------------------------
#     # TEST 2: Long flood that should still succeed
#     # Node 1 -> Node 16 = 15 hops
#     # --------------------------------------------------

#     print "TEST 2: Node 1 -> Node 16"

#     s.ping(1, 16, "1 to 16")

#     s.runTime(30)


#     # --------------------------------------------------
#     # TEST 3: TTL expiration
#     # Node 1 -> Node 17 = 16 hops
#     # MAX_TTL is only 15
#     # --------------------------------------------------

#     print "TEST 3: Node 1 -> Node 17 - TTL test"

#     s.ping(1, 17, "TTL test")

#     s.runTime(30)


# if __name__ == '__main__':

#     main()
