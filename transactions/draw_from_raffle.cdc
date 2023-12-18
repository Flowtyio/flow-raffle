import "FlowtyRaffles"

transaction(addr: Address, id: UInt64) {
    prepare(acct: AuthAccount) { 
        let manager = acct.borrow<&FlowtyRaffles.Manager>(from: FlowtyRaffles.ManagerStoragePath)
            ?? panic("raffles manager not found")
        let receiptID = manager.commitDrawing(raffleID: id)
        manager.revealDrawing(raffleID: id, receiptID: receiptID)
    }
}