import "FlowtyRaffles"

pub fun main(addr: Address, path: StoragePath): String {
    let acct = getAuthAccount(addr)
    let source = acct.borrow<&{FlowtyRaffles.RaffleSource}>(from: path)
    return source!.getType().identifier
}