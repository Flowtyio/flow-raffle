import "FlowtyRaffles"

pub contract FlowtyRaffleSource {
    pub resource AnyStructRaffleSource: FlowtyRaffles.RaffleSourcePublic, FlowtyRaffles.RaffleSourcePrivate {
        pub let entries: [AnyStruct]
        pub let entryType: Type
        pub let removeAfterReveal: Bool

        pub fun getEntryType(): Type {
            return self.entryType
        }

        pub fun getEntryAt(index: Int): AnyStruct {
            return self.entries[index]
        }

        pub fun getEntries(): [AnyStruct] {
            return self.entries
        }

        pub fun getEntryCount(): Int {
            return self.entries.length
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

        pub fun revealCallback(drawingResult: FlowtyRaffles.DrawingResult) {
            if !self.removeAfterReveal {
                return 
            }

            self.entries.remove(at: drawingResult.index)
        }

        init(entryType: Type, removeAfterReveal: Bool) {
            self.entries = []
            self.entryType = entryType
            self.removeAfterReveal = removeAfterReveal
        }
    }

    pub fun createRaffleSource(entryType: Type, removeAfterReveal: Bool): @AnyStructRaffleSource  {
        pre {
            entryType.isSubtype(of: Type<AnyStruct>()): "entry type must be a subtype of AnyStruct"
        }

        return <- create AnyStructRaffleSource(entryType: entryType, removeAfterReveal: removeAfterReveal)
    }
}