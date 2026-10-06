#include "../../includes/packet.h"
#include "../../includes/channels.h"

module FloodingP {

    provides interface Flooding;
    // The flooding module will use the SimpleSend interface to broadcast flooded packets.
    uses interface SimpleSend as Sender;

}

implementation {
    // Sequence number for new floods is created by this node.
    uint16_t sequenceNumber = 0;
    // The maximum number of hops a flood can travel before it is dropped.
    enum {
        SEEN_CACHE_SIZE = 20
    };
    uint32_t seenPackets[SEEN_CACHE_SIZE];
    uint8_t seenCount = 0; // Current valid cache
    uint8_t seenNext = 0; // Next packet key will be stored

    uint32_t getPacketKey(pack msg) {
        // Combine the source and sequence number into one unique value.
        return ((uint32_t) msg.src << 16) | msg.seq;
    }
    // Checks whether we've already processed this flood
    bool hasSeen(pack msg) {
    
        uint32_t key;
        uint8_t i;
        key = getPacketKey(msg);
        for(i = 0; i < seenCount; i++) {
        
            if(seenPackets[i] == key) {
                return TRUE;
            }
        }
        return FALSE;
    }
    // This records a flood that we've processed
    void rememberPacket(pack msg) {
    
        seenPackets[seenNext] = getPacketKey(msg); //stores ID
        seenNext++;
        if(seenNext >= SEEN_CACHE_SIZE) { // when array full start at 0
            seenNext = 0;
        }
        if(seenCount < SEEN_CACHE_SIZE) {
            seenCount++;
        }
    }
    
    command error_t Flooding.send(pack msg) {

        // This node is the original source of the flood.
        msg.src = TOS_NODE_ID;

        // Give every new flood from this node a unique sequence number.
        msg.seq = sequenceNumber;
        sequenceNumber++;

        // Allow the packet to travel through multiple hops.
        msg.TTL = MAX_TTL;

        // Remember this packet so we do not forward it
        // if it eventually comes back to us.
        rememberPacket(msg);

        dbg(FLOODING_CHANNEL,
            "Node %d starting flood to %d seq=%d\n",
            TOS_NODE_ID,
            msg.dest,
            msg.seq);

        // Flooding begins by broadcasting to all direct neighbors.
        return call Sender.send(msg, AM_BROADCAST_ADDR);
    }
    
    command void Flooding.receive(pack msg) {

        pack replyPacket;

        // Neighbor Discovery uses a broadcast PING with payload "ND".
        // It should not participate in flooding.
        if(msg.dest == AM_BROADCAST_ADDR &&
           msg.protocol == PROTOCOL_PING &&
           msg.payload[0] == 'N' &&
           msg.payload[1] == 'D') {

            return;
        }


        // If this exact source + sequence number was already seen,
        // do not process or forward it again.
        if(hasSeen(msg)) {

            // dbg(FLOODING_CHANNEL,
            //     "Node %d dropping duplicate from %d seq=%d\n",
            //     TOS_NODE_ID,
            //     msg.src,
            //     msg.seq);

            return;
        }

        // First time seeing this packet.
        rememberPacket(msg);


        // dbg(FLOODING_CHANNEL,
        //     "Node %d received flood from %d to %d seq=%d TTL=%d\n",
        //     TOS_NODE_ID,
        //     msg.src,
        //     msg.dest,
        //     msg.seq,
        //     msg.TTL);

        dbg(FLOODING_CHANNEL,
            "FLOOD PACKET -> src: %d, dst: %d, seq: %d, ttl: %d, protocol: %d, payload: %s\n",
            msg.src,
            msg.dest,
            msg.seq,
            msg.TTL,
            msg.protocol,
            msg.payload);

        // We reached the final destination.
        if(msg.dest == TOS_NODE_ID) {
        
            dbg(FLOODING_CHANNEL,
                "Node %d flood reached destination from %d seq=%d\n",
                TOS_NODE_ID,
                msg.src,
                msg.seq);


            // If this was a PING, create a PINGREPLY
            // and flood it back to the original source.
            if(msg.protocol == PROTOCOL_PING) {
            
                // Copy the original packet so the payload is preserved.
                replyPacket = msg;

                // The reply is going back to the original sender.
                replyPacket.dest = msg.src;

                // This node is now the source of the reply.
                replyPacket.src = TOS_NODE_ID;

                // A reply is a new flooded packet, so give it
                // this node's next sequence number.
                replyPacket.seq = sequenceNumber;
                sequenceNumber++;

                // Give the reply a fresh TTL.
                replyPacket.TTL = MAX_TTL;

                // Mark this packet as a ping reply.
                replyPacket.protocol = PROTOCOL_PINGREPLY;

                // Remember our own reply so we do not forward it
                // if it comes back to us.
                rememberPacket(replyPacket);

                dbg(FLOODING_CHANNEL,
                    "Node %d starting PINGREPLY to %d seq=%d\n",
                    TOS_NODE_ID,
                    replyPacket.dest,
                    replyPacket.seq);
                
                call Sender.send(replyPacket, AM_BROADCAST_ADDR);
            }


            // A PINGREPLY has reached the node that originally pinged.
            else if(msg.protocol == PROTOCOL_PINGREPLY) {
            
                dbg(FLOODING_CHANNEL,
                    "Node %d received PINGREPLY from %d seq=%d\n",
                    TOS_NODE_ID,
                    msg.src,
                    msg.seq);
            }

            return;
        }

        // No more hops are allowed.
        if(msg.TTL <= 1) {

            dbg(FLOODING_CHANNEL,
                "Node %d dropping packet because TTL expired\n",
                TOS_NODE_ID);

            return;
        }

        // The packet is not for us, so forward it.
        msg.TTL--;

        dbg(FLOODING_CHANNEL,
            "Node %d forwarding flood from %d to %d seq=%d TTL=%d\n",
            TOS_NODE_ID,
            msg.src,
            msg.dest,
            msg.seq,
            msg.TTL);

        // Forwards the packet to this node's neighbors
        call Sender.send(msg, AM_BROADCAST_ADDR);
    }

}