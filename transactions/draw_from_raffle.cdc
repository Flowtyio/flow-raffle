import "FlowtyRaffles"

transaction(addr: Address, id: UInt64) {
    prepare(acct: AuthAccount) { }
    execute {
        let manager = getAccount(addr).getCapability<&FlowtyRaffles.Manager{FlowtyRaffles.ManagerPublic}>(FlowtyRaffles.ManagerPublicPath).borrow()
            ?? panic("raffles manager not found")
        let raffle = manager.borrowRafflePublic(id: id)
            ?? panic("raffle not found")
        raffle.draw()
    }
}