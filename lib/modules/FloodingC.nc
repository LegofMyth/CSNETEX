configuration FloodingC {
    provides interface Flooding;
}

implementation {

    components FloodingP;
    components new SimpleSendC(AM_PACK) as FloodSender;

    Flooding = FloodingP;
    FloodingP.Sender -> FloodSender;
}