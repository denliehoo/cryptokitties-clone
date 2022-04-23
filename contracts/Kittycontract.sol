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

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance) {
        return ownershipTokenCount[owner];
    }

    /*
     * @dev Returns the total number of tokens in circulation.
     */
    function totalSupply() external view returns (uint256 total) {
        return kitties.length;
    }

    /*
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory tokenName) {
        return nameOfToken;
    }

    /*
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory tokenSymbol) {
        return symbolOfToken;
    }

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner) {
        return kittyIndexToOwner[tokenId];
    }

    /* @dev Transfers `tokenId` token from `msg.sender` to `to`.
     *
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `to` can not be the contract address.
     * - `tokenId` token must be owned by `msg.sender`.
     *
     * Emits a {Transfer} event.
     */
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
        }
        emit Transfer(_from, _to, _tokenId);
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
