const Kittycontract = artifacts.require("Kittycontract");

module.exports = function (deployer) {
  deployer.deploy(Kittycontract);
};


/* 
truffle console
const instance = await Kittycontract.deployed()
// gets the name
instance.name()
instance.createKittyGen0(1001)

let n = await instance.totalSupply()
n.toString() // 1

n = await instance.balanceOf(accounts[0])
n.toString() // 1

isntance.ownerOf(1) // show be accounts[0]

let result = await instance.getKitty(0)
result["genes"].toNumber()
result["generation"].toNumber()

*/