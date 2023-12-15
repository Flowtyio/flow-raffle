import "Raffles"

pub contract RaffleSources {
    pub resource AddressRaffleSource: Raffles.RaffleSource {
        pub let addresses: [Address]

        pub fun getEntryAt(index: Int): AnyStruct {
            return self.addresses[index]
        }

        pub fun addEntry(_ v: AnyStruct) {
            let addr = v as! Address
            self.addresses.append(addr)
        }

        pub fun addEntries(_ v: [AnyStruct]) {
            let addrs = v as! [Address]
            self.addresses.appendAll(addrs)
        }

        pub fun getNumEntries(): Int {
            return self.addresses.length
        }

        pub fun getEntries(): [AnyStruct] {
            return self.addresses
        }

        init() {
            self.addresses = []
        }
    }

    pub fun createRaffleSource(_ type: Type): @{Raffles.RaffleSource} {
        switch type {
            case Type<@AddressRaffleSource>():
                return <- create AddressRaffleSource()
        }

        panic("raffle source type ".concat(type.identifier).concat(" is not valid"))
    }
}