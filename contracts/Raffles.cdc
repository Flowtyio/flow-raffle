import "MetadataViews"

pub contract Raffles {
    pub let ManagerStoragePath: StoragePath
    pub let ManagerPublicPath: PublicPath

    pub event RaffleCreated(address: Address, raffleID: UInt64, sourceType: Type)
    pub event RaffleDrawn(address: Address, raffleID: UInt64, sourceType: Type, index: Int, value: String)

    pub struct Details {
        pub let start: UInt64?
        pub let end: UInt64?
        pub let display: MetadataViews.Display

        init(
            _ start: UInt64?,
            _ end: UInt64,
            _ display: MetadataViews.Display
            
        ) {
            self.start = start
            self.end = end
            self.display = display
        }
    }

    pub resource interface RafflePublic {
        pub fun getEntryAt(index: Int): AnyStruct
    }

    pub resource Raffle: RafflePublic, MetadataViews.Resolver {
        pub let source: @{RaffleSource}
        pub let details: Details

        pub fun draw(): Int {
            return self.source.draw()
        }

        pub fun getEntryAt(index: Int): AnyStruct {
            return self.source.getEntryAt(index: index)
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
            start: UInt64?,
            end: UInt64,
            display: MetadataViews.Display
        ) {
            self.source <- source
            self.details = Details(start, end, display)
        }

        destroy() {
            destroy self.source
        }
    }

    pub resource interface RaffleSource {
        pub fun draw(): Int
        pub fun getEntryAt(index: Int): AnyStruct
    }

    pub resource AddressRaffleSource: RaffleSource {
        pub let addresses: [Address]

        pub fun draw(): Int {
            let r = revertibleRandom()
            return Int(UInt64(self.addresses.length) % r)
        }

        pub fun getEntryAt(index: Int): AnyStruct {
            return self.addresses[index]
        }

        init() {
            self.addresses = []
        }
    }

    pub resource interface ManagerPublic {
        pub fun borrowRafflePublic(id: UInt64): &{RafflePublic}?
    }

    pub resource Manager: ManagerPublic {
        access(self) let raffles: @{UInt64: Raffle}

        pub fun borrowRafflePublic(id: UInt64): &{RafflePublic}? {
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

    access(contract) fun emitDrawing(address: Address, raffleID: UInt64, sourceType: Type, index: Int, value: AnyStruct) {
        var v = "UNKNOWN"
        switch value.getType() {
            case Type<Address>():
                v = (value as! Address).toString()
                break
            case Type<UInt64>():
                v = (value as! UInt64).toString()
                break
        }

        emit RaffleDrawn(address: address, raffleID: raffleID, sourceType: sourceType, index: index, value: v)
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