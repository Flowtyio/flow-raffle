import Test
import "test_helpers.cdc"

import "Raffles"
import "RaffleSources"
import "MetadataViews"

pub let RafflesContractAddress = Address(0x0000000000000007)
pub let RaffleSourcesContractAddress = Address(0x0000000000000008)

pub let GenericRaffleSourceIdentifier = "A.0000000000000008.RaffleSources.GenericRaffleSource"

pub fun setup() {
    var err = Test.deployContract(name: "Raffles", path: "../contracts/Raffles.cdc", arguments: [])
    Test.expect(err, Test.beNil())

    err = Test.deployContract(name: "RaffleSources", path: "../contracts/RaffleSources.cdc", arguments: [])
    Test.expect(err, Test.beNil())
}

pub fun testSetupManager() {
    let acct = Test.createAccount()
    txExecutor("setup_manager.cdc", [acct], [], nil)
    scriptExecutor("borrow_manager.cdc", [acct.address])
}

pub fun testCreateRaffleSource() {
    let acct = Test.createAccount()
    let path = StoragePath(identifier: "testCreateRaffleSource")!
    txExecutor("create_raffle_source.cdc", [acct], [Type<Address>(), path], nil)
    let res = scriptExecutor("get_raffle_source_identifier.cdc", [acct.address, path])
    assert(res! as! String == GenericRaffleSourceIdentifier, message: "unexpected raffle source identifier")
}

pub fun testCreateRaffle() {
    let acct = Test.createAccount()
    let name = "testCreateRaffle"
    let description = "testCreateRaffle desc"
    let thumbnail = "https://example.com/thumbnail"
    let start: UInt64? = nil
    let end: UInt64? = nil

    txExecutor("create_raffle.cdc", [acct], [Type<Address>(), start, end, name, description, thumbnail], nil)
    let createEvent = (Test.eventsOfType(Type<Raffles.RaffleCreated>()).removeLast() as! Raffles.RaffleCreated)
    assert(acct.address == createEvent.address)

    let details = getRaffleDetails(acct, createEvent.raffleID) ?? panic("raffle not found")

    assert(name == details.display.name)
    assert(description == details.display.description)
    assert(thumbnail == details.display.thumbnail.uri())
    assert(start == details.start)
    assert(end == details.end)
}

pub fun testAddToRaffle() {
    let acct = Test.createAccount()
    let id = createAddressRaffle(acct)
    let beforeEntries = getRaffleEntries(acct, id)!
    assert(beforeEntries.length == 0)

    addEntryToRaffle(acct, id, acct.address)

    
    let afterEntries = getRaffleEntries(acct, id)!
    assert(afterEntries.length == 1)
    assert(afterEntries[0] as! Address == acct.address)
}

pub fun testDrawFromRaffle() {
    let acct = Test.createAccount()
    let id = createAddressRaffle(acct)
    let beforeEntries = getRaffleEntries(acct, id)!
    addEntryToRaffle(acct, id, acct.address)

    // make sure we can draw an entry from the raffle, even when it only has a single item in it
    let drawing = drawFromRaffle(acct, acct.address, id)
    assert(drawing == acct.address.toString())

    // now let's add lots of additional entries
    let accounts: {String: Test.Account} = {
        acct.address.toString(): acct
    }
    var count = 0
    while count < 10 {
        count = count + 1
        let a = Test.createAccount()
        accounts[a.address.toString()] = a
    }

    // draw again, making sure that the winner is in our dictionary
    let drawing2 = drawFromRaffle(acct, acct.address, id)
    assert(accounts[drawing2] != nil)
}

pub fun getRaffleDetails(_ acct: Test.Account, _ id: UInt64): Raffles.Details? {
    if let res = scriptExecutor("get_raffle_details.cdc", [acct.address, id]) {
        return res as! Raffles.Details
    }
    return nil
}

pub fun getRaffleEntries(_ acct: Test.Account, _ id: UInt64): [AnyStruct]? {
    if let res = scriptExecutor("get_raffle_entries.cdc", [acct.address, id]) {
        return res as! [AnyStruct]
    }
    return nil
}

pub fun getRaffleEntriesCount(_ acct: Test.Account, _ id: UInt64): Int? {
    if let res = scriptExecutor("get_num_raffle_entries.cdc", [acct.address, id]) {
        return res as! Int
    }
    return nil
}

pub fun addEntryToRaffle(_ acct: Test.Account, _ id: UInt64, _ entry: AnyStruct) {
    txExecutor("add_entry_to_raffle.cdc", [acct], [id, entry], nil)
}

pub fun addEntriesToRaffle(_ acct: Test.Account, _ id: UInt64, _ entries: [AnyStruct]) {
    txExecutor("add_entries_to_raffle.cdc", [acct], [id, entries], nil)
}

pub fun createAddressRaffle(_ acct: Test.Account): UInt64 {
    let name = "address raffle"
    let description = "address raffle desc"
    let thumbnail = "https://example.com/thumbnail"
    let start: UInt64? = nil
    let end: UInt64? = nil

    txExecutor("create_raffle.cdc", [acct], [Type<Address>(), start, end, name, description, thumbnail], nil)
    let createEvent = (Test.eventsOfType(Type<Raffles.RaffleCreated>()).removeLast() as! Raffles.RaffleCreated)
    return createEvent.raffleID
}

pub fun drawFromRaffle(_ signer: Test.Account, _ addr: Address, _ id: UInt64): String {
    txExecutor("draw_from_raffle.cdc", [signer], [addr, id], nil)

    let drawingEvent = Test.eventsOfType(Type<Raffles.RaffleDrawn>()).removeLast() as! Raffles.RaffleDrawn
    return drawingEvent.value
}