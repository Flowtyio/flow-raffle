import "Raffles"
import "RaffleSources"
import "MetadataViews"

transaction(sourceIdentifier: String, start: UInt64?, end: UInt64?, name: String, description: String, thumbnail: String) {
    prepare(acct: AuthAccount) {
        let ct = CompositeType(sourceIdentifier) ?? panic("invalid source identifier")
        let source <- RaffleSources.createRaffleSource(ct)

        if acct.borrow<&AnyResource>(from: Raffles.ManagerStoragePath) == nil {
            acct.save(<-Raffles.createManager(), to: Raffles.ManagerStoragePath)
            acct.link<&Raffles.Manager{Raffles.ManagerPublic}>(Raffles.ManagerPublicPath, target: Raffles.ManagerStoragePath)
        }

        let manager = acct.borrow<&Raffles.Manager>(from: Raffles.ManagerStoragePath)
            ?? panic("raffles manager not found")

        let display = MetadataViews.Display(
            name: name,
            description: description,
            thumbnail: MetadataViews.HTTPFile(thumbnail)
        )
        let details = Raffles.Details(start, end, display)
        let id = manager.createRaffle(source: <-source, details: details)

        // make sure you can borrow the raffle back
        manager.borrowRafflePublic(id: id) ?? panic("raffle not found")
    }
}