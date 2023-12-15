import "Raffles"

pub fun main(addr: Address, path: StoragePath): String {
    let acct = getAuthAccount(addr)
    let source = acct.borrow<&{Raffles.RaffleSource}>(from: path)
    return source!.getType().identifier
}