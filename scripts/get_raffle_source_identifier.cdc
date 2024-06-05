import "FlowtyRaffles"

access(all) fun main(addr: Address, path: StoragePath): String {
    let acct = getAuthAccount<auth(Storage) &Account>(addr)
    let source = acct.storage.borrow<&{FlowtyRaffles.RaffleSourcePublic, FlowtyRaffles.RaffleSourcePrivate}>(from: path)
    return source!.getType().identifier
}