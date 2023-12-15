import "Raffles"
import "MetadataViews"


transaction(raffleId: UInt64) {
    prepare(acct: AuthAccount) {
        let manager = acct.borrow<&Raffles.Manager>(from: Raffles.ManagerStoragePath)
            ?? panic("Could not borrow a reference to the Manager")
        
        manager.draw(id: raffleId)
    }
}