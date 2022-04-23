const truffleAssert = require('truffle-assertions') //npm i truffle-assertions
const { assert } = require('chai')


contract('Kittycontract', accounts => {
    describe('Testing kitty contract', () => {
        const Kittycontract = artifacts.require('Kittycontract')

        let instance;

        // we await the and get the deployed contranct before each it
        // so that we do not have to keep typing it
        beforeEach(async () => {
            instance = await Kittycontract.deployed()
        })

        // it("statement", async function...)
        // note: each it statements are dependent on each other
        // i.e. what happens in one function has an effect on the next function
        it("correct token name", async () => {
            let tokenName = await instance.name()
            assert.equal(tokenName, "Dkitties")
        })
        it("should create and get kitty properly", async () => {
            await instance.createKittyGen0(1001)
            let result = await instance.getKitty(0)
            assert.equal(result["genes"].toNumber(), 1001)
            assert.equal(result["generation"].toNumber(), 0)
        })
        it("minting should increase total supply and transfer to correct owner", async () => {
            let totalSupply = await instance.totalSupply()
            assert.equal(totalSupply.toNumber(), 1)

            let tokensOwned = await instance.balanceOf(accounts[0])
            assert.equal(tokensOwned.toNumber(), 1)

            let tokenOwner = await instance.ownerOf(0) //tokenId 0
            assert.equal(tokenOwner.toString(), accounts[0])
        })

    })

})


// const truffleAssert = require('truffle-assertions') //npm i truffle-assertions
// const Kittycontract = artifacts.require('Kittycontract')

// contract('Kittycontract', accounts => {
//     // it("statement", async function...)
//     // note: each it statements are dependent on each other
//     // i.e. what happens in one function has an effect on the next function
//     it("correct token name", async () => {
//         let instance = await Kittycontract.deployed()
//         let tokenName = await instance.name()
//         assert.equal(tokenName, "Dkitties")
//     })
//     it("should create and get kitty properly", async () => {
//         let instance = await Kittycontract.deployed()
//         await instance.createKittyGen0(1001)
//         let result = await instance.getKitty(0)
//         assert.equal(result["genes"].toNumber(), 1001)
//         assert.equal(result["generation"].toNumber(), 0)
//     })
//     it("minting should increase total supply and transfer to correct owner", async () => {
//         let instance = await Kittycontract.deployed()

//         let totalSupply = await instance.totalSupply()
//         assert.equal(totalSupply.toNumber(), 1)

//         let tokensOwned = await instance.balanceOf(accounts[0])
//         assert.equal(tokensOwned.toNumber(), 1)

//         let tokenOwner = await instance.ownerOf(0) //tokenId 0
//         assert.equal(tokenOwner.toString(), accounts[0])
//     })

// })