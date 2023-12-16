import "FlowtyRaffles"

pub fun main(addr: Address) {
    getAccount(addr).getCapability<&FlowtyRaffles.Manager{FlowtyRaffles.ManagerPublic}>(FlowtyRaffles.ManagerPublicPath).borrow()
        ?? panic("unable to borrow manager")
}