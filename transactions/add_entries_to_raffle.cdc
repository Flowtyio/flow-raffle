import "FlowtyRaffles"

transaction(raffleID: UInt64, entries: [AnyStruct]) {
    prepare(acct: AuthAccount) {
        let manager = acct.borrow<&FlowtyRaffles.Manager>(from: FlowtyRaffles.ManagerStoragePath)
            ?? panic("raffles manager not found")
        let raffle = manager.borrowRaffle(id: raffleID)
            ?? panic("raffle not found")
        raffle.addEntries(entries)
    }
}