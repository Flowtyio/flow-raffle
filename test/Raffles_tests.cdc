import Test
import "test_helpers.cdc"

import "Raffles"


pub fun setup() {
    let err = Test.deployContract(name: "Raffles", path: "../contracts/Raffles.cdc", arguments: [])
    Test.expect(err, Test.beNil())
}

pub fun setupManager() {
    let acct = Test.createAccount()
    txExecutor("setup_manager", [acct], [], nil)
    scriptExecutor("borrow_manager.cdc", [acct.address])
}