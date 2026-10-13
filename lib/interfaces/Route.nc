
#include "../../includes/packet.h"

// Interface for Project 2 Distance Vector Routing
interface Route {

    // Initialize the routing table and routing process.
    command void start();

    // Find the next hop and cost for a destination.
    // Returns TRUE if a usable route exists.
    command bool getRoute(
        uint16_t destination,
        uint16_t* nextHop,
        uint8_t* cost
    );

    // Print the current routing table.
    command void printRoutingTable();
}