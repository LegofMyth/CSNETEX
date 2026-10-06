configuration NDiscoveryC {
    provides interface NDiscovery;
}

implementation {
    // Neighbor discovery module implementation
    components NDiscoveryP;
    NDiscovery = NDiscoveryP;

    // Timer and number generator used for periodic,
    // randomized neighbor discovery.
    components new TimerMilliC() as neighborTimer;
    components RandomC as Random;
    
    NDiscoveryP.neighborTimer -> neighborTimer;
    NDiscoveryP.Random -> Random;

    // Neighbor table:
    // key = node ID
    // value = age
    // Asks for hashmap on P and then the hashmap gets created here 
    // it holds 20 entried that stores unit16_t values
    components new HashmapC(uint16_t, 20) as NeighborTable;
    // Connect the hashmap that NDiscoveryP needs to this actual hashmap component
    NDiscoveryP.NeighborTable -> NeighborTable;

    // Connect the sender to the neighbor discovery module
    components new SimpleSendC(AM_PACK) as NeighborSender;
    NDiscoveryP.Sender -> NeighborSender;
}
