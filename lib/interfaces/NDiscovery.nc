#include "../../includes/packet.h"

interface NDiscovery {
    command void start();
    command void printNeighbors();

    // Give received network packets to the neighbor discovery module.
    command void receive(pack msg);

    // Project 2: copy active neighbor IDs into buffer
    command uint8_t getNeighbors(
        uint16_t* buffer,
        uint8_t capacity
    );

    // Project 2: check if a node is a direct neighbor
    command bool isNeighbor(uint16_t nodeID);
}