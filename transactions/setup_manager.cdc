import "Raffles"

transaction {
    prepare(acct: AuthAccount) {
        let manager <- Raffles.createManager()
        acct.save(<-manager, to: Raffles.ManagerStoragePath)
        acct.link<&Raffles.Manager{Raffles.ManagerPublic}>(Raffles.ManagerPublicPath, target: Raffles.ManagerStoragePath)
    }
}