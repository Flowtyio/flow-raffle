import "FlowtyRaffles"

access(all) fun main(addr: Address, id: UInt64): FlowtyRaffles.Details? {
    let acct = getAuthAccount<auth(Storage) &Account>(addr)
    let manager = acct.storage.borrow<&FlowtyRaffles.Manager>(from: FlowtyRaffles.ManagerStoragePath)
        ?? panic("raffles manager not found")

    if let raffle = manager.borrowRafflePublic(id: id) {
        return raffle.getDetails()
    }

    return nil
}