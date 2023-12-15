import "RaffleSources"

transaction(identifier: String, path: StoragePath) {
    prepare(acct: AuthAccount) {
        let ct = CompositeType(identifier)!
        let source <- RaffleSources.createRaffleSource(ct)

        assert(source.getType() == ct, message: "mismatched raffle source type")
        acct.save(<-source, to: path)
    }
}