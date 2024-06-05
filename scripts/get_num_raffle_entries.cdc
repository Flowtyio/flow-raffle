import "FlowtyRaffles"

access(all) fun main(addr: Address, id: UInt64): Int {
    let acct = getAuthAccount<auth(Storage) &Account>(addr)
    let manager = acct.storage.borrow<&{FlowtyRaffles.ManagerPublic}>(from: FlowtyRaffles.ManagerStoragePath)
        ?? panic("raffles manager not found")
    let raffle = manager.borrowRafflePublic(id: id)
        ?? panic("raffle not found")
    let source = raffle.borrowSourcePublic()
        ?? panic("raffle source is invaid")
    return source.getEntryCount()
}