
configuration RouteC {

    // Provide the Route interface to other modules.
    provides interface Route;

    // Use the existing Neighbor Discovery service.
    uses interface NDiscovery;
}

implementation {

    // Routing implementation.
    components RouteP;

    // Timer for checking changes in direct neighbors.
    components new TimerMilliC() as RouteTimer;

    // Expose RouteP's interface through RouteC.
    Route = RouteP.Route;

    // Give RouteP access to Neighbor Discovery.
    RouteP.NDiscovery -> NDiscovery;

    // Connect RouteP to its periodic timer.
    RouteP.RouteTimer -> RouteTimer;
}
