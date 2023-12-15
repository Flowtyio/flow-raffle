import "MetadataViews"

pub contract Raffles {
    pub let ManagerStoragePath: StoragePath
    pub let ManagerPublicPath: PublicPath

    pub event RaffleCreated(address: Address?, raffleID: UInt64, sourceType: Type)
    pub event RaffleDrawn(address: Address?, raffleID: UInt64, sourceType: Type, index: Int, value: String, valueType: Type)

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

    pub struct DrawingSelection {
        pub let index: Int
        pub let value: AnyStruct

        init(_ index: Int, _ value: AnyStruct) {
            self.index = index
            self.value = value
        }
    }

    pub resource interface RafflePublic {
        pub fun getEntryAt(index: Int): AnyStruct
        pub fun getDetails(): Details
        pub fun getNumEntries(): Int
        pub fun getEntries(): [AnyStruct]
        pub fun draw(): DrawingSelection
    }

    pub resource interface RaffleSource {
        pub fun getEntryAt(index: Int): AnyStruct
        pub fun addEntry(_ v: AnyStruct)
        pub fun addEntries(_ v: [AnyStruct])
        pub fun getNumEntries(): Int
        pub fun getEntries(): [AnyStruct]
    }

    pub resource Raffle: RafflePublic, MetadataViews.Resolver {
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

            Raffles.emitDrawing(self.owner?.address, self.uuid, self.source.getType(), index, value)
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