// https://eips.ethereum.org/EIPS/eip-721 must have all these events/functions
pragma solidity ^0.5.12;
import "./IERC721.sol";
import "./IERC721Receiver.sol";

contract Kittycontract is IERC721 {
    string public nameOfToken = "Dkitties";
    string public symbolOfToken = "DK";
    uint256 CREATION_LIMIT_GEN0 = 10;
    uint256 public gen0Counter;
    address contractOwner;
    bytes4 internal constant MAGIC_ERC721_RECEIVED =
        bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));

    // this is the interface ID for ERC721 and ERC165 token standrads
    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

    event Birth(
        address owner,
        uint256 kittenId,
        uint256 mumId,
        uint256 dadId,
        uint256 genes
    );

    struct Kitty {
        uint256 genes;
        uint64 birthTime;
        uint32 mumId;
        uint32 dadId;
        uint16 generation;
    }
    Kitty[] kitties;

    mapping(uint256 => address) public kittyIndexToOwner;
    mapping(address => uint256) ownershipTokenCount;
    mapping(uint256 => address) public kittyIndexToApproved;

    // owner address => operator address => true/false ; _operatorApprovals[myAddr][oppAddr] = true/false
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    constructor() public {
        contractOwner = msg.sender;
    }

    // people can use this function and input the interface ID (e.g. of ERC165 or ERC721) to
    // verify whether our smartcontract supports a certain token standards
    // in this case, our contract supports ERC165 & ERC721 but not ERC20
    // this function is required to be ERC721 compliant.
    function supportsInterface(bytes4 _interfaceId)
        external
        view
        returns (bool)
    {
        return (_interfaceId == _INTERFACE_ID_ERC721 ||
            _interfaceId == _INTERFACE_ID_ERC165);
    }

    function createKittyGen0(uint256 _genes)
        public
        onlyOwner
        returns (uint256)
    {
        require(gen0Counter < CREATION_LIMIT_GEN0);
        gen0Counter++;

        return _createKitty(0, 0, 0, _genes, msg.sender);
    }

    function _createKitty(
        uint256 _mumId,
        uint256 _dadId,
        uint256 _generation,
        uint256 _genes,
        address _owner
    ) internal returns (uint256 catId) {
        Kitty memory _kitty = Kitty({
            genes: _genes,
            birthTime: uint64(now),
            mumId: uint32(_mumId),
            dadId: uint32(_dadId),
            generation: uint16(_generation)
        });
        // when we do .push, what happens is that we get the length of the array in return
        // hence, we can assign it to a variable (so for this case, e.g. if its the first
        // kitty create, the array length would be 1 and would hence return 1; however, for
        // token index or indexes in general, we usually start from 0, hence we -1)
        uint256 newKittenId = kitties.push(_kitty) - 1;

        emit Birth(_owner, newKittenId, _mumId, _dadId, _genes);
        _transfer(address(0), _owner, newKittenId);

        return newKittenId;
    }

    //remember: external means cannot use function within contract; can only use from outside
    function getKitty(uint256 _tokenId)
        external
        view
        returns (
            uint256 genes,
            uint256 birthTime,
            uint256 mumId,
            uint256 dadId,
            uint256 generation
        )
    {
        // gets the Kitty and saves it in storage as a pointer (this uses less gas compared to copying it and saving in memory)
        Kitty storage kitty = kitties[_tokenId];
        // we return all these below (don't need to put a return statement in this case)
        birthTime = uint256(kitty.birthTime);
        dadId = uint256(kitty.dadId);
        mumId = uint256(kitty.mumId);
        generation = uint256(kitty.generation);
        genes = uint256(kitty.genes);
    }

    function balanceOf(address owner) external view returns (uint256 balance) {
        return ownershipTokenCount[owner];
    }

    function totalSupply() external view returns (uint256 total) {
        return kitties.length;
    }

    function name() external view returns (string memory tokenName) {
        return nameOfToken;
    }

    function symbol() external view returns (string memory tokenSymbol) {
        return symbolOfToken;
    }

    function ownerOf(uint256 tokenId) external view returns (address owner) {
        return kittyIndexToOwner[tokenId];
    }

    function transfer(address to, uint256 tokenId) external {
        require(to != address(0));
        require(to != address(this));
        require(_isTokenOwner(msg.sender, tokenId));

        _transfer(msg.sender, to, tokenId);
    }

    function _transfer(
        address _from,
        address _to,
        uint256 _tokenId
    ) internal {
        ownershipTokenCount[_to]++;
        kittyIndexToOwner[_tokenId] = _to;

        // since when we mint, it is a transfer from address(0) to the address
        // hence, we don't minus from address(0) since it isn't an actual transfer
        // we only decrease if it is a normal transfer.
        if (_from != address(0)) {
            ownershipTokenCount[_from]--;
            // after transfer, the approved address (from the prev owner) should be deleted
            delete kittyIndexToApproved[_tokenId];
        }
        emit Transfer(_from, _to, _tokenId);
    }

    function approve(address _approved, uint256 _tokenId) external {
        require(_isTokenOwner(msg.sender, _tokenId));
        _approve(_approved, _tokenId);
        emit Approval(msg.sender, _approved, _tokenId);
    }

    function _approve(address _approved, uint256 _tokenId) internal {
        kittyIndexToApproved[_tokenId] = _approved;
    }

    function _approvedFor(address _claimant, uint256 _tokenId)
        internal
        view
        returns (bool)
    {
        return kittyIndexToApproved[_tokenId] == _claimant;
    }

    function setApprovalForAll(address _operator, bool _approved) external {
        require(_operator != msg.sender);
        _operatorApprovals[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    // gets the status of a token of whether or not it is approved
    function getApproved(uint256 _tokenId) external view returns (address) {
        require(_tokenId < kitties.length); // Token must exist
        // returns the approved address; returns address(0) if not approved
        return kittyIndexToApproved[_tokenId];
    }

    function isApprovedForAll(address _owner, address _operator)
        public
        view
        returns (bool)
    {
        return _operatorApprovals[_owner][_operator];
    }

    // transfer and transferFrom has the same logic as ERC20 whereby transferFrom is
    // allowing the smart contract to transfer the NFT on the owner's behalf
    // once the owner approves it

    /* safeTransfer vs transferFrom
    for transferFrom, all we really do is change the mapping of the ERC721 to the wallet address. 
    However, what some people might do is that they transfer it to an address/smart contract that doesn't support owning tokens
    e.g. some smart contracts might just not support tokens i.e. they have no functions or methods to interact with ERC721 tokens
    Hence, if we transfer to such smart contracts, the ERC721 token would be last forever. 

    safeTransfer does 2 checks first before sending: 
    It calls the transfer function with require statements that checks whether the receiver supports ERC721. 
    And it also does 2 checks:
    It will firstly check whether the receiver is a contract. If it isn't, it will transfer.
    If it is a contract, it will check whether it support ERC721. Every contract that support ERC721
    must have a function implemented called onERC721Received() which must return a specific value (0x150b7a02)
    Hence, to see if the contract support ERC721 we call the onERC721Received() function and see whether the 
    return the specified value. If it doesn,t it will transfer and if it doesn't, it wont.  
     */

    function _safeTransfer(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes memory _data
    ) internal {
        _transfer(_from, _to, _tokenId);
        require(_checkERC721Support(_from, _to, _tokenId, _data));
    }

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) public {
        safeTransferFrom(_from, _to, _tokenId, "");
    }

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes memory _data
    ) public {
        require(_isApprovedOrOwner(msg.sender, _from, _to, _tokenId));
        _safeTransfer(_from, _to, _tokenId, _data);
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) external {
        require(_to != address(0));
        // either one of the three has to be true
        require(
            msg.sender == _from ||
                _approvedFor(msg.sender, _tokenId) ||
                isApprovedForAll(_from, msg.sender)
        );
        require(_isTokenOwner(_from, _tokenId));
        require(_tokenId < kitties.length);

        _transfer(_from, _to, _tokenId);
    }

    function _isTokenOwner(address _caller, uint256 _tokenId)
        internal
        view
        returns (bool isOwner)
    {
        // return true if the address matches and false if it doesn't
        return kittyIndexToOwner[_tokenId] == _caller;
    }

    function _checkERC721Support(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes memory _data
    ) internal returns (bool) {
        // if it is not a contract, it means that it is a normal addresses. Since normal addresses support ERC721 token,
        // we return true and end the function
        if (!_isContract(_to)) {
            return true;
        }
        // call onERC721Received in the _to contract and checks the return value
        bytes4 returnData = IERC721Receiver(_to).onERC721Received(
            msg.sender,
            _from,
            _tokenId,
            _data
        );
        // if returnData matches the specified return value, we know that the contract support ERC721 tokens
        // hence, if it matches, we return true, else we return false
        return returnData == MAGIC_ERC721_RECEIVED;
    }

    function _isContract(address _to) internal view returns (bool) {
        // if it is a wallet code size = 0, if it is a smart contract, code size should be > 0
        uint32 size;
        assembly {
            // extcodesize gets the code of whatever the _to is from the blockchain
            size := extcodesize(_to)
        }
        // if >0 , it returns true meaning it is a contract, else, it returns false meaning not a contract
        return size > 0;
    }

    function _isApprovedOrOwner(
        address _spender,
        address _from,
        address _to,
        uint256 _tokenId
    ) internal view returns (bool) {
        require(_tokenId < kitties.length); //Token must exist
        require(_to != address(0)); //TO address is not zero address
        require(_isTokenOwner(_from, _tokenId)); //From owns the token

        //spender is from OR spender is approved for tokenId OR spender is operator for from
        return (_spender == _from ||
            _approvedFor(_spender, _tokenId) ||
            isApprovedForAll(_from, _spender));
    }

    modifier onlyOwner() {
        require(msg.sender == contractOwner);
        _;
    }
}
