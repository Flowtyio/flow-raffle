import "FlowtyRaffles"

pub fun main(addr: Address, id: UInt64): FlowtyRaffles.Details? {
    let acct = getAuthAccount(addr)
    let manager = acct.borrow<&FlowtyRaffles.Manager>(from: FlowtyRaffles.ManagerStoragePath)
        ?? panic("raffles manager not found")

    if let raffle = manager.borrowRafflePublic(id: id) {
        return raffle.getDetails()
    }

    return nil
}