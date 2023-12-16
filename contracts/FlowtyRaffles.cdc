import "MetadataViews"

/*
FlowtyRaffles - The main contract which contains a definition for:

1. Raffles - A resource which encapsulates an ongoing raffle
2. RaffleSource - A resource interface which specified how a raffle will attempt to select a winner
3. Manager - A container resource for raffles to be stored in

The Raffles resource takes no view on what kind of item should be randomly drawn. Because of that, there is no
mechanism to distribute prizes when a drawing is made. This is intentional, and is meant to separate the act of 
drawing an item from a raffle source, and sending it so that there are no restrictions on what kind of item might
need to be randomly drawn.

For example, a raffle could be made which draws a random post from a social media platform. In that case, only the 
post itself needs to be randomly drawn. Action based on that drawing would likely need to be done separately.

Similarly one could make a raffle which distributes prizes in real-time by drawing a winner and then could:

1. Distribute the prize in a second operation in the same transaction
2. Send the item to lost and found for the winner to redeem (https://github.com/Flowtyio/lost-and-found)
*/
pub contract FlowtyRaffles {
    pub let ManagerStoragePath: StoragePath
    pub let ManagerPublicPath: PublicPath

    pub event RaffleCreated(address: Address?, raffleID: UInt64, sourceType: Type)
    pub event RaffleDrawn(address: Address?, raffleID: UInt64, sourceType: Type, index: Int, value: String, valueType: Type)

    // Details - Info about the raffle. This currently includes when the raffle starts, ends, and how to display it.
    pub struct Details {
        pub let start: UInt64?
        pub let end: UInt64?
        pub let display: MetadataViews.Display

        init(
            _ start: UInt64?,
            _ end: UInt64?,
            _ display: MetadataViews.Display
            
        ) {
            self.start = start
            self.end = end
            self.display = display
        }
    }

    // DrawingSelection - Returned when a raffle is drawn from. We will return the index that was selected and the 
    // value underneath it. This should assist with letting anyone using raffles to take action on them in the same transaction
    // without the raffle itself needing to worry about those details.
    pub struct DrawingSelection {
        pub let index: Int
        pub let value: AnyStruct

        init(_ index: Int, _ value: AnyStruct) {
            self.index = index
            self.value = value
        }
    }

    pub resource interface RafflePublic {
        // Return the value of a raffle source at a given index
        pub fun getEntryAt(index: Int): AnyStruct

        // Return the details associated with this raffle
        pub fun getDetails(): Details

        // Return the number of entries in this raffle
        pub fun getNumEntries(): Int

        // Return all entries in this raffle
        // NOTE: If there are too many entries in a raffle, this method will exceed computation limits
        pub fun getEntries(): [AnyStruct]

        // Draws a random item from the RaffleSource and returns the index that was selected along with the 
        // value of the item underneath.
        pub fun draw(): DrawingSelection
    }

    pub resource interface RaffleSource {
        // Should return the entry of a raffle source at a given index.
        // NOTE: There is no way to enforce this on this contract, whatever RaffleSource resource
        // implementation you use, make sure you trust how it performs its drawing
        pub fun getEntryAt(index: Int): AnyStruct

        // Adds an entry to this RaffleSource resource
        // NOTE: Some raffle sources might not permit this action. For instance, using a FLOAT
        // as a raffle source would mean the only way to add an entry is to mint the FLOAT
        // a raffle corresponds to
        pub fun addEntry(_ v: AnyStruct)

        // Adds many entries at once to a given raffle source.
        // NOTE: Some raffle sources might not permit this action. For instance, using a FLOAT
        // as a raffle source would mean the only way to add an entry is to mint the FLOAT
        // a raffle corresponds to
        pub fun addEntries(_ v: [AnyStruct])

        // Should return the number of entries on a RaffleSource resource.
        // NOTE: There is no way to enforce this on this contract, whatever RaffleSource resource
        // implementation you use, make sure you trust how it performs its drawing
        pub fun getNumEntries(): Int

        // Should return all entries in a RaffleSource resource
        // NOTE: There is no way to enforce this on this contract, whatever RaffleSource resource
        // implementation you use, make sure you trust how it performs its drawing
        pub fun getEntries(): [AnyStruct]
    }

    pub resource Raffle: RafflePublic, MetadataViews.Resolver {
        // The source for drawing winners in a raffle. Anyone can implement their own version of a RaffleSource,
        // or they can use the GenericRaffleSource implementation found in FlowtyRaffleSource which can handle any 
        // primitive type found in cadence documentation here:
        // 
        pub let source: @{RaffleSource}
        pub let details: Details

        pub fun getDetails(): Details {
            return self.details
        }

        pub fun getNumEntries(): Int {
            return self.source.getNumEntries()
        }

        pub fun getEntries(): [AnyStruct] {
            return self.source.getEntries()
        }

        pub fun draw(): DrawingSelection {
            let numEntries = self.source.getNumEntries()
            let r = revertibleRandom()
            let index = Int(r % UInt64(numEntries))
            let value = self.source.getEntryAt(index: index)

            FlowtyRaffles.emitDrawing(self.owner?.address, self.uuid, self.source.getType(), index, value)
            return DrawingSelection(index, value)
        }

        pub fun getEntryAt(index: Int): AnyStruct {
            return self.source.getEntryAt(index: index)
        }

        pub fun addEntry(_ v: AnyStruct) {
            self.source.addEntry(v)
        }

        pub fun addEntries(_ v: [AnyStruct]) {
            self.source.addEntries(v)
        }

        pub fun getViews(): [Type] {
            return [
                Type<MetadataViews.Display>()
            ]
        }

        pub fun resolveView(_ type: Type): AnyStruct? {
            switch type {
                case Type<MetadataViews.Display>():
                    return self.details.display
            }

            return nil
        }

        init(
            source: @{RaffleSource},
            details: Details
        ) {
            self.source <- source
            self.details = details
        }

        destroy() {
            destroy self.source
        }
    }

    pub resource interface ManagerPublic {
        pub fun borrowRafflePublic(id: UInt64): &{RafflePublic}?
    }

    pub resource Manager: ManagerPublic {
        access(self) let raffles: @{UInt64: Raffle}

        pub fun createRaffle(source: @{RaffleSource}, details: Details): UInt64 {
            let sourceType = source.getType()

            let raffle <- create Raffle(source: <- source, details: details)
            emit RaffleCreated(address: self.owner!.address, raffleID: raffle.uuid, sourceType: sourceType)

            let id = raffle.uuid
            destroy self.raffles.insert(key: id, <-raffle)

            return id
        }

        pub fun borrowRafflePublic(id: UInt64): &{RafflePublic}? {
            return self.borrowRaffle(id: id)
        }

        pub fun borrowRaffle(id: UInt64): &Raffle? {
            if self.raffles[id] == nil {
                return nil
            }

            return &self.raffles[id] as &Raffle?
        }

        init() {
            self.raffles <- {}
        }

        destroy () {
            destroy self.raffles
        }
    }

    access(contract) fun emitDrawing(_ address: Address?, _ raffleID: UInt64, _ sourceType: Type, _ index: Int, _ value: AnyStruct) {
        var v = "UNKNOWN"
        switch value.getType() {
            case Type<Address>():
                v = (value as! Address).toString()
                break
            case Type<UInt64>():
                v = (value as! UInt64).toString()
                break
        }

        emit RaffleDrawn(address: address, raffleID: raffleID, sourceType: sourceType, index: index, value: v, valueType: value.getType())
    }

    pub fun createManager(): @Manager {
        return <- create Manager()
    }

    init() {
        let identifier = "Raffle_".concat(self.account.address.toString())
        self.ManagerStoragePath = StoragePath(identifier: identifier)!
        self.ManagerPublicPath = PublicPath(identifier: identifier)!
    }
}