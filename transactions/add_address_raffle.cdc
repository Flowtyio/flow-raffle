import "Raffles"
import "MetadataViews"

transaction(raffleId: UInt64, addressToAdd: Address) {
    prepare(acct: AuthAccount) {
        let manager = acct.borrow<&Raffles.Manager>(from: Raffles.ManagerStoragePath)
            ?? panic("Could not borrow a reference to the Manager")
        
        manager.addAddressToRaffle(id: raffleId, address: addressToAdd)
    }
}