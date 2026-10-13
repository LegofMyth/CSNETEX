#include "../../includes/channels.h"
#include "../../includes/packet.h"

module NDiscoveryP {

    provides interface NDiscovery;

    uses interface Timer<TMilli> as neighborTimer;
    uses interface Random;

    // Stores:
    // key   = neighbor node ID
    // value = neighbor age
    // The age is incremented every time the neighborTimer fires.
    uses interface Hashmap<uint16_t> as NeighborTable; // packet.h uses 16
    // Used to send neighbor-discovery packets
    uses interface SimpleSend as Sender;
}

implementation {
    
    pack discoveryPacket;

    //remove a neighbor if it has missed several neighbor discovery broadcasts
    enum {
        NEIGHBOR_TIMEOUT = 5 
    };

    // Project 2:
    // Copy active neighbor IDs into a caller-provided buffer.
    command uint8_t NDiscovery.getNeighbors(
        uint16_t* buffer,
        uint8_t capacity
    ) {
        uint32_t* keys;
        uint16_t tableSize;
        uint16_t i;

        if (buffer == NULL || capacity == 0) {
            return 0;
        }

        keys = call NeighborTable.getKeys();
        tableSize = call NeighborTable.size();

        // Never write beyond the caller's buffer.
        if (tableSize > capacity) {
            tableSize = capacity;
        }

        for (i = 0; i < tableSize; i++) {
            buffer[i] = (uint16_t)keys[i];
        }

        return (uint8_t)tableSize;
    }

    // Project 2:
    // Check whether a node is currently a neighbor.
    command bool NDiscovery.isNeighbor(uint16_t nodeID) {
        return call NeighborTable.contains(nodeID);
    }

    command void NDiscovery.start() {

        call neighborTimer.startPeriodic(500 +(uint16_t) (call Random.rand16() % 997));
        
    }

    event void neighborTimer.fired(){

        uint32_t* keys;
        uint32_t neighborID;

        uint16_t i;
        uint16_t age;

        // Age currently known neighbors

        keys = call NeighborTable.getKeys();
        i = 0;

        while(i < call NeighborTable.size()) {

            neighborID = keys[i];

            age = call NeighborTable.get(neighborID);
            age++;

            // If we have not heard from this neighbor
            // for several discovery cycles, remove it.
            if(age >= NEIGHBOR_TIMEOUT) {

                dbg(NEIGHBOR_CHANNEL,
                    "Node %d removing stale neighbor %d\n",
                    TOS_NODE_ID,
                    (uint16_t)neighborID);

                call NeighborTable.remove(neighborID);

                /*
                 * Do NOT increment i here.
                 *
                 * Hashmap.remove() shifts the key list left,
                 * so a different neighbor may now be sitting
                 * at position i.
                 */
            }
            else {

                // Store the increased age.
                call NeighborTable.insert(neighborID, age);

                i++;
            }
        }

        // Send this node's own discovery message

        // dbg(NEIGHBOR_CHANNEL, "Node %d sending neighbor discovery\n", TOS_NODE_ID);

        discoveryPacket.src = TOS_NODE_ID;
        // Send this packet to every node that can hear me
        discoveryPacket.dest = AM_BROADCAST_ADDR;
    
        // Neighbor discovery should only concern directly connected nodes.
        discoveryPacket.TTL = 1;
    
        discoveryPacket.seq = 0;
        discoveryPacket.protocol = PROTOCOL_PING;
    
        discoveryPacket.payload[0] = 'N';
        discoveryPacket.payload[1] = 'D';
        discoveryPacket.payload[2] = '\0';
    
        call Sender.send(discoveryPacket, AM_BROADCAST_ADDR);
    }

    command void NDiscovery.printNeighbors() {
        
        // dbg(NEIGHBOR_CHANNEL, "Printing Neighbors\n");
        uint32_t* keys;
        uint16_t i;
        uint16_t tableSize;
    
        keys = call NeighborTable.getKeys(); // gets all keys from the table
        tableSize = call NeighborTable.size();
    
        dbg(NEIGHBOR_CHANNEL,
            "Node %d Neighbors:\n",
            TOS_NODE_ID);
    
        // for(i = 0; i < tableSize; i++) { // print each key
        
        //     dbg(NEIGHBOR_CHANNEL,
        //         "  Neighbor: %d\n", 
        //         (uint16_t)(keys[i]));
        // }

        if (tableSize == 0) {
            dbg(NEIGHBOR_CHANNEL, "  (No active neighbors)\n");
        } else {
            for(i = 0; i < tableSize; i++) {
                dbg(NEIGHBOR_CHANNEL, "  Neighbor: %d (Age: %d)\n", 
                  (uint16_t)(keys[i]), 
                  call NeighborTable.get(keys[i]));
            }
        }
        dbg(NEIGHBOR_CHANNEL, "--------------------------------------\n\n");
    }


    command void NDiscovery.receive(pack msg) {
    // dbg(NEIGHBOR_CHANNEL,
    //     "NDiscovery.receive node %d got packet from %d\n",
    //     TOS_NODE_ID,
    //     msg.src);

    // dbg(NEIGHBOR_CHANNEL,
    //     "ND CHECK node=%d src=%d dest=%d protocol=%d payload=%c%c\n",
    //     TOS_NODE_ID,
    //     msg.src,
    //     msg.dest,
    //     msg.protocol,
    //     msg.payload[0],
    //     msg.payload[1]);

    // Check whether this is one of our neighbor-discovery broadcasts.

    if(msg.dest == AM_BROADCAST_ADDR &&
       msg.protocol == PROTOCOL_PING &&
       msg.payload[0] == 'N' &&
       msg.payload[1] == 'D') {

        // A node should never add itself as its own neighbor.
        if(msg.src != TOS_NODE_ID) {

            // Print only when this is a newly discovered neighbor.
            // if(!call NeighborTable.contains(msg.src)) {
            //     dbg(NEIGHBOR_CHANNEL,
            //         "Node %d discovered neighbor %d\n",
            //         TOS_NODE_ID,
            //         msg.src);
            // }

            // key   = neighbor node ID
            // value = age, initially 0
            call NeighborTable.insert(msg.src, 0); // Add this neighbor to the neighbor table, with age 0.

            // dbg(NEIGHBOR_CHANNEL,
            //     "Node %d neighbor table size = %d\n",
            //     TOS_NODE_ID,
            //     call NeighborTable.size());
        }
    }
}

}