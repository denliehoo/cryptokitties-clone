// https://eips.ethereum.org/EIPS/eip-721 must have all these events/functions
pragma solidity ^0.5.12;
import "./IERC721.sol";

contract Kittycontract is IERC721 {
    string public nameOfToken = "Dkitties";
    string public symbolOfToken = "DK";
    uint256 CREATION_LIMIT_GEN0 = 10;
    uint256 public gen0Counter;
    address contractOwner;

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

    function approve(address _approved, uint256 _tokenId) external{
        require(_isTokenOwner(msg.sender, _tokenId););
        _approve(_approved, _tokenId);
        emit Approval(msg.sender, _approved, _tokenId);
    }

    function _approve(address _approved, uint256 _tokenId) internal {
        kittyIndexToApproved[_tokenId] = _approved;

    }


    function setApprovalForAll(address _operator, bool _approved) external{
        require(_operator != msg.sender);
        _operatorApprovals[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved)
    }

    // gets the status of a token of whether or not it is approved
    function getApproved(uint256 _tokenId) external view returns (address){
        require(_tokenId < kitties.length); // Token must exist
        // returns the approved address; returns address(0) if not approved
        return kittyIndexToApproved[_tokenId]; 
    }

    function isApprovedForAll(address _owner, address _operator)
        external
        view
        returns (bool){
            return _operatorApprovals[_owner][_operator];
        }

    // transfer and transferFrom has the same logic as ERC20 whereby transferFrom is
    // allowing the smart contract to transfer the NFT on the owner's behalf
    // once the owner approves it.
    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes calldata data
    ) external;


    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) external;


    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) external{
        require(_to != address(0));
        // either one of the three has to be true
        require(msg.sender == _from || _approvedFor(msg.sender, _tokenId) || isApprovedForAll(_from, msg.sender));
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

    modifier onlyOwner() {
        require(msg.sender == contractOwner);
        _;
    }
}
