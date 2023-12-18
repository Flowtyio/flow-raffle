import "FlowtyRaffles"
import "FLOAT"

pub contract FLOATRaffleSource {
    pub resource RaffleSource {
        pub let eventCap: Capability<&FLOAT.FLOATEvents{FLOAT.FLOATEventsPublic}>
        pub let eventId: UInt64

        pub fun getEntries(): [AnyStruct] {
            return self.borrowEvent().getClaims().values
        }

        pub fun getEntryCount(): Int {
            return self.borrowEvent().getClaims().length
        }

        pub fun getEntryAt(index: Int): AnyStruct {
            return self.borrowEvent().getClaims()[UInt64(index)]
        }

        pub fun revealCallback(drawingResult: FlowtyRaffles.DrawingResult) {
            return
        }

        pub fun addEntry(_ v: AnyStruct) {
            panic("addEntry is not supported on FLOATRaffleSource")
        }

        pub fun addEntries(_ v: [AnyStruct]) {
            panic("addEntries is not supported on FLOATRaffleSource")
        }

        pub fun borrowEvent(): &FLOAT.FLOATEvent{FLOAT.FLOATEventPublic} {
            let cap = self.eventCap.borrow() ?? panic("eventCap is not valid")
            return cap.borrowPublicEventRef(eventId: self.eventId) ?? panic("invalid event id")
        }
        
        init(eventCap: Capability<&FLOAT.FLOATEvents{FLOAT.FLOATEventsPublic}>, eventId: UInt64) {
            self.eventCap = eventCap
            self.eventId = eventId

            // ensure we can borrow the event. This will panic if the we aren't able to
            self.borrowEvent()
        }
    }

    pub fun createRaffleSource(eventCap: Capability<&FLOAT.FLOATEvents{FLOAT.FLOATEventsPublic}>, eventId: UInt64): @RaffleSource {
        return <- create RaffleSource(eventCap: eventCap, eventId: eventId)
    }
}