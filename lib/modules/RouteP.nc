
#include "../../includes/packet.h"
#include "../../includes/channels.h"

module RouteP {

    provides interface Route;

    // Use the existing Project 1 neighbor discovery service.
    uses interface NDiscovery;

    // Periodically check the current direct neighbors.
    uses interface Timer<TMilli> as RouteTimer;
}

implementation {

    enum {
        ROUTE_INFINITY = 16,
        MAX_ROUTES = 32,
        MAX_NEIGHBORS = 20,
        ROUTE_CHECK_INTERVAL = 1000,
        NO_NEXT_HOP = 0xFFFF
    };

    // One entry in the routing table.
    typedef struct {
        uint16_t destination;
        uint16_t nextHop;
        uint8_t cost;

        bool valid;
        bool direct;

        // Time when this route was last refreshed.
        uint32_t lastUpdatedMs;
    } route_entry_t;

    route_entry_t routingTable[MAX_ROUTES];

    uint8_t routeCount = 0;
    bool started = FALSE;


    // Find an existing destination in the routing table.
    // Return -1 if the destination is not known.
    int16_t findRoute(uint16_t destination) {
        uint8_t i;

        for (i = 0; i < routeCount; i++) {
            if (routingTable[i].destination == destination) {
                return i;
            }
        }

        return -1;
    }


    // Check whether a node appears in the current neighbor list.
    bool inNeighborList(
        uint16_t nodeID,
        uint16_t* neighbors,
        uint8_t count
    ) {
        uint8_t i;

        for (i = 0; i < count; i++) {
            if (neighbors[i] == nodeID) {
                return TRUE;
            }
        }

        return FALSE;
    }


    // Synchronize direct routes with Neighbor Discovery.
    void updateDirectNeighbors() {

        uint16_t neighbors[MAX_NEIGHBORS];
        uint8_t neighborCount;
        uint8_t i;

        int16_t routeIndex;
        uint16_t neighborID;
        uint32_t now;

        neighborCount = call NDiscovery.getNeighbors(
            neighbors,
            MAX_NEIGHBORS
        );

        now = call RouteTimer.getNow();

        // First, check whether any direct neighbor disappeared.
        for (i = 0; i < routeCount; i++) {

            if (routingTable[i].direct &&
                routingTable[i].valid &&
                !inNeighborList(
                    routingTable[i].destination,
                    neighbors,
                    neighborCount
                )) {

                routingTable[i].valid = FALSE;
                routingTable[i].cost = ROUTE_INFINITY;
                routingTable[i].nextHop = NO_NEXT_HOP;
                routingTable[i].lastUpdatedMs = now;

                dbg(ROUTING_CHANNEL,
                    "Node %d lost direct route to %d\n",
                    TOS_NODE_ID,
                    routingTable[i].destination);
            }
        }

        // Next, add or refresh currently active neighbors.
        for (i = 0; i < neighborCount; i++) {

            neighborID = neighbors[i];

            if (neighborID == TOS_NODE_ID) {
                continue;
            }

            routeIndex = findRoute(neighborID);

            if (routeIndex >= 0) {

                // Existing neighbor or recovered direct link.
                if (!routingTable[routeIndex].valid ||
                    !routingTable[routeIndex].direct ||
                    routingTable[routeIndex].cost != 1) {

                    dbg(ROUTING_CHANNEL,
                        "Node %d restored direct route to %d\n",
                        TOS_NODE_ID,
                        neighborID);
                }

                routingTable[routeIndex].nextHop = neighborID;
                routingTable[routeIndex].cost = 1;
                routingTable[routeIndex].valid = TRUE;
                routingTable[routeIndex].direct = TRUE;
                routingTable[routeIndex].lastUpdatedMs = now;

            } else {

                // Do not write outside our routing table.
                if (routeCount >= MAX_ROUTES) {

                    dbg(ROUTING_CHANNEL,
                        "Node %d routing table full\n",
                        TOS_NODE_ID);

                    continue;
                }

                routingTable[routeCount].destination = neighborID;
                routingTable[routeCount].nextHop = neighborID;
                routingTable[routeCount].cost = 1;
                routingTable[routeCount].valid = TRUE;
                routingTable[routeCount].direct = TRUE;
                routingTable[routeCount].lastUpdatedMs = now;

                routeCount++;

                dbg(ROUTING_CHANNEL,
                    "Node %d added direct route to %d cost=1\n",
                    TOS_NODE_ID,
                    neighborID);
            }
        }
    }


    // Initialize Local Routing State.
    command void Route.start() {

        if (started) {
            return;
        }

        started = TRUE;
        routeCount = 0;

        // A node always has a route to itself with cost 0.
        routingTable[0].destination = TOS_NODE_ID;
        routingTable[0].nextHop = TOS_NODE_ID;
        routingTable[0].cost = 0;
        routingTable[0].valid = TRUE;
        routingTable[0].direct = FALSE;
        routingTable[0].lastUpdatedMs = 0;

        routeCount = 1;

        dbg(ROUTING_CHANNEL,
            "Node %d initialized routing table\n",
            TOS_NODE_ID);

        call RouteTimer.startPeriodic(ROUTE_CHECK_INTERVAL);

        updateDirectNeighbors();
    }


    // Periodically check for neighbor changes.
    event void RouteTimer.fired() {

        updateDirectNeighbors();
    }


    // Return the selected next hop and cost for a destination.
    command bool Route.getRoute(
        uint16_t destination,
        uint16_t* nextHop,
        uint8_t* cost
    ) {
        int16_t routeIndex;

        if (nextHop == NULL || cost == NULL) {
            return FALSE;
        }

        *nextHop = NO_NEXT_HOP;
        *cost = ROUTE_INFINITY;

        routeIndex = findRoute(destination);

        if (routeIndex < 0) {
            return FALSE;
        }

        if (!routingTable[routeIndex].valid ||
            routingTable[routeIndex].cost >= ROUTE_INFINITY) {
            return FALSE;
        }

        *nextHop = routingTable[routeIndex].nextHop;
        *cost = routingTable[routeIndex].cost;

        return TRUE;
    }


    // Print the local routing table.
    command void Route.printRoutingTable() {

        uint8_t i;

        dbg(ROUTING_CHANNEL,
            "Node %d Routing Table:\n",
            TOS_NODE_ID);

        dbg(ROUTING_CHANNEL,
            "Dest  NextHop  Cost  State\n");

        for (i = 0; i < routeCount; i++) {

            if (routingTable[i].valid) {

                dbg(ROUTING_CHANNEL,
                    "%d     %d        %d     VALID\n",
                    routingTable[i].destination,
                    routingTable[i].nextHop,
                    routingTable[i].cost);

            } else {

                dbg(ROUTING_CHANNEL,
                    "%d     -        INF    UNREACHABLE\n",
                    routingTable[i].destination);
            }
        }

        dbg(ROUTING_CHANNEL,
            "--------------------------------------\n");
    }
}
