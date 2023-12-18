import "FlowtyRaffles"

/*
FlowtyRaffleSource - Contains a basic implementation of RaffleSource which can be used for all `AnyStruct`
types. For example, if a consumer of this resource wanted to make a raffle that uses an array of Addresses as the pool
to draw from, they could use the AnyStructRaffleSource with an entry type of Type<Address>() and would be guaranteed to only
be able to put addresses in their array of entries.

This is enforced so that consumers of that source can have safety when reading entries from the array in case they want to handle any additional
logic alongside the raffle itself, such as distributing a prize when a raffle is drawn

In addition to entryType, a field called `removeAfterReveal` is also provided, which, if enabled, will remove an entry
from the entries array any time a reveal is performed. This is useful for cases where you don't want the same entry to be able to be drawn
multiple times.
*/
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