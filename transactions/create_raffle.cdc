import "FlowtyRaffles"
import "FlowtyRaffleSource"
import "MetadataViews"

transaction(type: Type, start: UInt64?, end: UInt64?, name: String, description: String, thumbnail: String, externalURL: String, commitBlocksAhead: UInt64) {
    prepare(acct: AuthAccount) {
        let source <- FlowtyRaffleSource.createRaffleSource(entryType: type, removeAfterReveal: false)

        if acct.borrow<&AnyResource>(from: FlowtyRaffles.ManagerStoragePath) == nil {
            acct.save(<-FlowtyRaffles.createManager(), to: FlowtyRaffles.ManagerStoragePath)
            acct.link<&FlowtyRaffles.Manager{FlowtyRaffles.ManagerPublic}>(FlowtyRaffles.ManagerPublicPath, target: FlowtyRaffles.ManagerStoragePath)
        }

        let manager = acct.borrow<&FlowtyRaffles.Manager>(from: FlowtyRaffles.ManagerStoragePath)
            ?? panic("raffles manager not found")

        let display = MetadataViews.Display(
            name: name,
            description: description,
            thumbnail: MetadataViews.HTTPFile(thumbnail)
        )
        let details = FlowtyRaffles.Details(start, end, display, MetadataViews.ExternalURL(externalURL))
        let id = manager.createRaffle(source: <-source, details: details, commitBlocksAhead: commitBlocksAhead)

        // make sure you can borrow the raffle back
        manager.borrowRafflePublic(id: id) ?? panic("raffle not found")
    }
}