/* we will write our function here which uses JS to interact with our frontend
e.g. the buttons etc; web3.js stuff... */
// url to the ETH node; however, since we are using metamask, we dont need to provide it ourself
// .givenProvider gives whatever provider it gets from metamask. 
const web3 = new Web3(Web3.givenProvider);
let instance, user, contractAddress;

contractAddress = '0x7a5a229b26a37a11562e9E16FD26Fda31368E5AC';

// when page has finished loading.... call the function
$(document).ready(function () {
    // prompts the user to connect 
    // gets a callback (then) when the accept it
    /* abi means application binary interface which is a specification we pass through web3.
    This allows web3 to know what functions are available in our contract, what params (and type)
    they take and what they return; hence ABI is a summary of what the contract does
    We can find the abi from the build folder -> .json file of our contract ()
    Hence, copy paste that .json file (all the "abi":{}) part and put it into our
    client/assets/ file and call it abi.js
    */
    window.ethereum.enable().then(function (accounts) {
        // instance of our Kittycontract
        // since our abi.js is imported into our index.html and this file
        // users index.html and the end, we don't need import it here again
        // we can just use the abi variable which was defined in abi.js
        instance = new web3.eth.Contract(abi, contractAddress, { from: accounts[0] })
        user = accounts[0]

        console.log(instance);
        // listens to an event; remember: we have a Birth event in our smart contract. 
        instance.events.Birth().on('data', function (event) {
            console.log(event);
            // gets the returnValues accordingly from the event
            let owner = event.returnValues.owner;
            let kittyId = event.returnValues.kittyId;
            let mumId = event.returnValues.mumId;
            let dadId = event.returnValues.dadId;
            let genes = event.returnValues.genes;
            // creates on the frontend
            $("#kittyCreation").css("display", "block");
            $("#kittyCreation").text("owner:" + owner
                + " kittyId:" + kittyId
                + " mumId:" + mumId
                + " dadId:" + dadId
                + " genes:" + genes)
        }).on('error', console.log(error))
    })

})

function createKitty() {
    const dnaStr = getDna(); //function created in catSettings.js
    // we use instance.methods.fnName to access the functions in our smart contract
    // if we have setter functions (which changes the state of blockchain), we need to add .send()
    // however, if its getter functions (view only which doens't change state of blockchain),
    // we dont need to put .send()
    /* .send() has two params: an object and a call backfunction which hash 2 params: error and txHash
    */

    instance.methods.createKittyGen0(dnaStr).send({}, function (error, txHash) {
        if (error) {
            console.log(error)
        } else {
            console.log(txHash)
        }
    })
}