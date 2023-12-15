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

    pub struct Result {
        pub let index: Int
        pub let value: AnyStruct

        init(
            _ index: Int,
            _ value: AnyStruct
        ) {
            self.index = index
            self.value = value
        }
    }

    pub resource interface RafflePublic {
        pub fun getEntryAt(index: Int): AnyStruct
    }

    pub resource Raffle: RafflePublic, MetadataViews.Resolver {
        pub let source: @{RaffleSource}
        pub let details: Details

        pub fun getSourceType(): Type {
            return self.source.getType()
        }

        pub fun getAddressSource(): &AddressRaffleSource {
            let source = &self.source as auth &{RaffleSource}
            return source as! &AddressRaffleSource
        }

        pub fun draw(): Int {
            return self.source.draw()
        }

        pub fun getAddresses(): [Address] {
            return self.getAddressSource().getAddresses()
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
            details: Details
        ) {
            self.source <- source
            self.details = details
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
            return Int(r % UInt64(self.addresses.length))
        }

        pub fun getEntryAt(index: Int): AnyStruct {
            return self.addresses[index]
        }

        pub fun getAddresses(): [Address] {
            return self.addresses
        }

        pub fun addAddress(address: Address) {
            self.addresses.append(address)
        }

        init() {
            self.addresses = []
        }
    }

    pub resource interface ManagerPublic {
        pub fun borrowRafflePublic(id: UInt64): &{RafflePublic}?
        pub fun getIDs(): [UInt64]
        pub fun getRaffleAddresses(id: UInt64): [Address]
    }

    pub resource Manager: ManagerPublic {
        access(self) let raffles: @{UInt64: Raffle}

        pub fun getIDs(): [UInt64] {
            return self.raffles.keys
        }

        pub fun getRaffleAddresses(id: UInt64): [Address] {
            return (&self.raffles[id] as &Raffle?)!.getAddresses() 
        }

        pub fun borrowRafflePublic(id: UInt64): &{RafflePublic}? {
            if self.raffles[id] == nil {
                return nil
            }

            return &self.raffles[id] as &Raffle?
        }

        pub fun addAddressToRaffle(id: UInt64, address: Address) {
            let raffle = &self.raffles[id] as &Raffle?
            if raffle == nil {
                panic("raffle with id ".concat(id.toString()).concat(" does not exist"))
            }

            let source = raffle!.getAddressSource()
            source.addAddress(address: address)
        }

        pub fun createAddressRaffleSource(): @AddressRaffleSource {
            return <- create Raffles.AddressRaffleSource()
        }

        pub fun createRaffle(source: @{RaffleSource}, details: Details) {
            let id = UInt64(self.raffles.length)
            let sourceType = source.getType()

            let raffle <- create Raffle(source: <- source, details: details)
            self.raffles[id] <-! raffle

            emit RaffleCreated(address: self.owner!.address, raffleID: id, sourceType: sourceType)
        }

        pub fun draw(id: UInt64) {
            let raffle: &Raffles.Raffle? = &self.raffles[id] as &Raffle?
            if raffle == nil {
                panic("raffle with id ".concat(id.toString()).concat(" does not exist"))
            }

            let index = raffle!.draw()
            let value = raffle!.getEntryAt(index: index)

            Raffles.emitDrawing(address: self.owner!.address, raffleID: id, sourceType: raffle!.getSourceType() ,index: index, value: value)
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

    pub fun createRaffle(source: @{RaffleSource}, details: Details): @Raffle {
        return <- create Raffle(source: <- source, details: details)        
    }

    pub fun createRaffleSource(_ type: Type): @{RaffleSource} {
        switch type {
            case Type<@AddressRaffleSource>():
                return <- create AddressRaffleSource()
        }

        panic("raffle source type ".concat(type.identifier).concat(" is not valid"))
    }

    init() {
        let identifier = "Raffle_".concat(self.account.address.toString())
        self.ManagerStoragePath = StoragePath(identifier: identifier)!
        self.ManagerPublicPath = PublicPath(identifier: identifier)!
    }
}