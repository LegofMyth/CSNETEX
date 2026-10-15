/**
 * ANDES Lab - University of California, Merced
 * This class provides the basic functions of a network node.
 *
 * @author UCM ANDES Lab
 * @date   2013/09/03
 *
 */

#include <Timer.h>
#include "includes/CommandMsg.h"
#include "includes/packet.h"

configuration NodeC{
}
implementation {
    components MainC;
    components Node;
    components new AMReceiverC(AM_PACK) as GeneralReceive;

    Node -> MainC.Boot;

    Node.Receive -> GeneralReceive;

    components ActiveMessageC;
    Node.AMControl -> ActiveMessageC;

    components new SimpleSendC(AM_PACK);
    Node.Sender -> SimpleSendC;

    components CommandHandlerC;
    Node.CommandHandler -> CommandHandlerC;

    components NDiscoveryC;
    Node.NDiscovery -> NDiscoveryC;

    components FloodingC;
    Node.Flooding -> FloodingC;

    // Project 2: Local Routing State
    components RouteC;
    
    // Give Node access to the Route interface.
    Node.Route -> RouteC.Route;
    
    // Give RouteP access to the SAME Neighbor Discovery module.
    RouteC.NDiscovery -> NDiscoveryC.NDiscovery;
}
