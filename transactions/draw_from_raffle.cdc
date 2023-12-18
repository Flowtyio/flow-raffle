import "FlowtyRaffles"

transaction(addr: Address, id: UInt64) {
    prepare(acct: AuthAccount) { 
        let manager = acct.borrow<&FlowtyRaffles.Manager>(from: FlowtyRaffles.ManagerStoragePath)
            ?? panic("raffles manager not found")
        let receiptID = manager.commitDrawing(raffleID: id)

        let ref = manager as &FlowtyRaffles.Manager{FlowtyRaffles.ManagerPublic}
        manager.revealDrawing(manager: ref, raffleID: id, receiptID: receiptID)
    }
}