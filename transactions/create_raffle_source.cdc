import "FlowtyRaffleSource"

transaction(type: Type, path: StoragePath) {
    prepare(acct: AuthAccount) {
        let source <- FlowtyRaffleSource.createRaffleSource(type)
        let t = source.getEntryType()
        assert(t == type)

        acct.save(<-source, to: path)
    }
}