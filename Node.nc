/*
 * ANDES Lab - University of California, Merced
 * This class provides the basic functions of a network node.
 *
 * @author UCM ANDES Lab
 * @date   2013/09/03
 *
 */
#include <Timer.h>
#include "includes/command.h"
#include "includes/packet.h"
#include "includes/CommandMsg.h"
#include "includes/sendInfo.h"
#include "includes/channels.h"

module Node{
   uses interface Boot;

   uses interface SplitControl as AMControl;
   uses interface Receive;

   uses interface SimpleSend as Sender;

   uses interface CommandHandler;
   //add this qaz
   uses interface NDiscovery;

   uses interface Flooding;

   // Project 2: Access the local routing table.
   uses interface Route;
}

implementation{
   pack sendPackage;

   // Prototypes tells the compiler that this helper function exists later in the file
   void makePack(pack *Package, uint16_t src, uint16_t dest, uint16_t TTL, uint16_t Protocol, uint16_t seq, uint8_t *payload, uint8_t length);
   
   // When node boots, start radio
   event void Boot.booted(){
      call AMControl.start();

      // dbg(GENERAL_CHANNEL, "Booted\n");
   }

   // This event is called when the radio is turned on.
   event void AMControl.startDone(error_t err){
      if(err == SUCCESS){
         // dbg(GENERAL_CHANNEL, "Radio On\n"); // dbg = debug
         call NDiscovery.start(); // add this qaz
         // Project 2: Initialize the routing table.
         call Route.start();
      }else{
         //Retry until successful
         call AMControl.start();
      }
   }
   // This event is called when the radio is turned off.
   event void AMControl.stopDone(error_t err){}
   // This event is called when the radio receives a packet.
   event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len){
      // dbg(GENERAL_CHANNEL, "Packet Received\n");
      if(len==sizeof(pack)){
         pack* myMsg=(pack*) payload;
         call NDiscovery.receive(*myMsg); //added this qaz
         call Flooding.receive(*myMsg); 
         // dbg(GENERAL_CHANNEL, "Package Payload: %s\n", myMsg->payload);
         return msg;
      }
      dbg(GENERAL_CHANNEL, "Unknown Packet Type %d\n", len);
      return msg;
   }

   // This event is called when the radio receives a packet.
   event void CommandHandler.ping(uint16_t destination, uint8_t *payload){
      dbg(GENERAL_CHANNEL, "PING EVENT \n");
      // Create a new packet to send.
      makePack(&sendPackage,
         TOS_NODE_ID,
         destination,
         0,
         PROTOCOL_PING,
         0,
         payload,
         PACKET_MAX_PAYLOAD_SIZE);
      call Flooding.send(sendPackage);
   }

   event void CommandHandler.printNeighbors(){
      call NDiscovery.printNeighbors();
   }

   event void CommandHandler.printRouteTable(){
      call Route.printRoutingTable(); // project 2: print routing table
   }

   event void CommandHandler.printLinkState(){}

   event void CommandHandler.printDistanceVector(){}

   event void CommandHandler.setTestServer(){}

   event void CommandHandler.setTestClient(){}

   event void CommandHandler.setAppServer(){}

   event void CommandHandler.setAppClient(){}

   // fill in packet header
   void makePack(pack *Package, uint16_t src, uint16_t dest, uint16_t TTL, uint16_t protocol, uint16_t seq, uint8_t* payload, uint8_t length){
      Package->src = src;
      Package->dest = dest;
      Package->TTL = TTL;
      Package->seq = seq;
      Package->protocol = protocol;
      memcpy(Package->payload, payload, length); // copy actual app message bytes into packet payload
   }
}
