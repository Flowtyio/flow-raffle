import "FlowtyRaffles"

transaction {
    prepare(acct: AuthAccount) {
        let manager <- FlowtyRaffles.createManager()
        acct.save(<-manager, to: FlowtyRaffles.ManagerStoragePath)
        acct.link<&FlowtyRaffles.Manager{FlowtyRaffles.ManagerPublic}>(FlowtyRaffles.ManagerPublicPath, target: FlowtyRaffles.ManagerStoragePath)
    }
}