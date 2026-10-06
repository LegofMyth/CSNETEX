#include "../../includes/packet.h"

interface NDiscovery {
    command void start();
    command void printNeighbors();

    // Give received network packets to the neighbor discovery module.
    command void receive(pack msg);
}