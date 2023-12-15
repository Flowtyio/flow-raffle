import "Raffles"

pub fun main(addr: Address, id: UInt64): Int {
    let acct = getAuthAccount(addr)
    let manager = acct.borrow<&Raffles.Manager{Raffles.ManagerPublic}>(from: Raffles.ManagerStoragePath)
        ?? panic("raffles manager not found")
    let raffle = manager.borrowRafflePublic(id: id)
        ?? panic("raffle not found")

    return raffle.getNumEntries()
}