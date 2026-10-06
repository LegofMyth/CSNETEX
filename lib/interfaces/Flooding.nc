#include "../../includes/packet.h"

interface Flooding {

    // Sends a packet using the flooding protocol.
    command error_t send(pack msg);
    // Receives a packet that has been flooded through the network.
    command void receive(pack msg);
}