import "Raffles"
import "MetadataViews"

transaction(raffleStart: UInt64?, raffleEnd: UInt64?, raffleTitle: String, raffleDescription: String, raffleImageUrl: String) {
    prepare(acct: AuthAccount) {
        let manager = acct.borrow<&Raffles.Manager>(from: Raffles.ManagerStoragePath)
            ?? panic("Could not borrow a reference to the Manager")
        
        let addressRaffleSource <- manager.createAddressRaffleSource()

        let details = Raffles.Details(
            start: raffleStart,
            end: raffleEnd!,
            display: MetadataViews.Display(
                title: raffleTitle,
                description: raffleDescription,
                media: MetadataViews.HTTPFile(
                                url: raffleImageUrl
                            )
            )
        )

        manager.createRaffle(source: <- addressRaffleSource, details: details)
    }
}