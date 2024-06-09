import "FlowtyRaffles"

access(all) fun main(addr: Address) {
    getAccount(addr).capabilities.get<&{FlowtyRaffles.ManagerPublic}>(FlowtyRaffles.ManagerPublicPath).borrow()
        ?? panic("unable to borrow manager")
}