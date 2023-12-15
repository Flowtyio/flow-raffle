import "Raffles"

transaction(raffleID: UInt64, entry: AnyStruct) {
    prepare(acct: AuthAccount) {
        let manager = acct.borrow<&Raffles.Manager>(from: Raffles.ManagerStoragePath)
            ?? panic("raffles manager not found")
        let raffle = manager.borrowRaffle(id: raffleID)
            ?? panic("raffle not found")
        raffle.addEntry(entry)
    }
}