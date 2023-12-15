import "Raffles"

pub contract RaffleSources {
    pub resource GenericRaffleSource: Raffles.RaffleSource {
        pub let entries: [AnyStruct]
        pub let entryType: Type

        pub fun getEntryType(): Type {
            return self.entryType
        }

        pub fun getEntryAt(index: Int): AnyStruct {
            return self.entries[index]
        }

        pub fun addEntry(_ v: AnyStruct) {
            pre {
                v.getType() == self.entryType: "incorrect entry type"
            }

            self.entries.append(v)
        }

        pub fun addEntries(_ v: [AnyStruct]) {
            pre { 
                VariableSizedArrayType(self.entryType) == v.getType(): "incorrect array type"
            }

            self.entries.appendAll(v)
        }

        pub fun getNumEntries(): Int {
            return self.entries.length
        }

        pub fun getEntries(): [AnyStruct] {
            return self.entries
        }

        init(_ entryType: Type) {
            self.entries = []
            self.entryType = entryType
        }
    }

    pub fun createRaffleSource(_ type: Type): @GenericRaffleSource {
        return <- create GenericRaffleSource(type)
    }
}