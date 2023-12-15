import "Raffles"

pub fun main(addr: Address, id: UInt64): Raffles.Details? {
    let acct = getAuthAccount(addr)
    let manager = acct.borrow<&Raffles.Manager>(from: Raffles.ManagerStoragePath)
        ?? panic("raffles manager not found")

    if let raffle = manager.borrowRafflePublic(id: id) {
        return raffle.getDetails()
    }

    return nil
}