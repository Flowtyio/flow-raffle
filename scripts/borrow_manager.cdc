import "Raffles"

pub fun main(addr: Address) {
    getAccount(addr).getCapability<&Raffles.Manager{Raffles.ManagerPublic}>(Raffles.ManagerPublicPath).borrow()
        ?? panic("unable to borrow manager")
}