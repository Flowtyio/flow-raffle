import "Raffles"

pub fun main(addr: Address): [UInt64] {
    let manager = getAccount(addr).getCapability<&Raffles.Manager{Raffles.ManagerPublic}>(Raffles.ManagerPublicPath).borrow()
        ?? panic("unable to borrow manager")
    return manager.getIDs()
}