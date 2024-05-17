// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "./ZephyrTokenV1.sol";

/// @title Asset Management Contract
/// @dev Manages real-world assets tokenized as NFTs on the blockchain on ZephyrAssets.
contract AssetManager is AccessControl {
    /// @notice Constructor to set up the Asset Manager contract
    /// @param _zephyrNftAddress Address of the Zephyr NFT contract
    /// @param _adminAddress Address of the admin to be granted MINTER_ROLE
    constructor(address _zephyrNftAddress, address _adminAddress) {
        zephyrNft = Zephyr(_zephyrNftAddress);
        MINTER = zephyrNft.MINTER_ROLE();
        _grantRole(MINTER, _adminAddress);
    }

    receive() external payable {}
    fallback() external payable {}
    /// @notice Custom errors for specific revert conditions :
    /**
     * @dev
     *     Unauthorized : Not enough Information or Access Revoked
     *     UserAlreadyRegistered : User's address has already been indexed
     *     UserNotRegistered : Function Requiring a user to be registered and throw if not
     *     CannotFindAsset : AssetId cannot be found ( when not registered or deleted )
     */

    error Unauthorized();
    error UserAlreadyRegistered(address user);
    error UserNotRegistered(address user);
    error CannotFindAsset(bytes32 assetId);

    Zephyr zephyrNft;
    /// @dev MINTER_ROLE of ERC721 Contract
    bytes32 public MINTER;

    // Struct definitions
    /// @dev Structure to represent an Asset

    struct Assets {
        address holderAddress;
        bytes32 assetId;
        string description;
        uint256 price;
        assetType classType;
    }

    /// @dev Enumeration of different types of assets
    enum assetType {
        realEstate,
        vehicle,
        jewelry,
        commodities,
        accessories,
        other
    }

    /// @dev Enumeration of different types of transactions
    enum transactionType {
        Purchase,
        Sale,
        Transfer,
        Mint,
        Burn
    }

    /// @dev Structure to represent a User
    struct User {
        string username;
        address userAddress;
        bytes32 userId;
    }

    // State variables
    /// @notice mappings
    /**
     * @dev
     *     mapping
     *         userAssets : bytes userId to Possessed Assets
     *         userTransactions : UserId to array with all users's transactions
     *         isRegistered : Address is registered
     *         getId : Address to get bytes32 id
     *         getAssetIdFromDescription
     *         idExists : bytes32 Id already exists
     *         HoldingAssets : Address's amount of Assets Holding
     */
    mapping(bytes32 => Assets[]) public userAssets;
    mapping(bytes32 => transactionType[]) public userTransactions;
    User[] public users;
    Assets[] public assets;
    mapping(address => bool) public isRegistered;
    mapping(address => bytes32) public getId;
    mapping(string => bytes32) public getAssetIdFromDescription;
    mapping(bytes32 => bool) public idExists;
    mapping(address => uint256) public HoldingAssets;
    mapping(bytes32 => bool) public isListed;
    uint256 internal TotalUsers = 0;
    uint256 internal TotalAssets = 0;
    uint256 internal constant MAX_ASSET_PER_USER = 15;

    /// @notice Modifiers for access control and checks
    /// @dev Modifier to restrict function access to users with MINTER role
    modifier requireMinter(address _userAddress) {
        if (!zephyrNft.hasRole(MINTER, _userAddress)) revert Unauthorized();
        _;
    }

    /// Ensure user is not registered
    modifier isNotRegistered(address _userAddress) {
        if (isRegistered[_userAddress]) revert UserAlreadyRegistered(_userAddress);
        _;
    }

    /// Ensure user is already registered
    modifier isAlreadyRegistered(address _userAddress) {
        if (!isRegistered[_userAddress]) revert UserNotRegistered(_userAddress);
        _;
    }

    /// @notice Register a new user
    /// @param _username The username of the user
    /// @param _address The wallet address of the user
    /// @dev Registers a new user and assigns them a unique userId
    function registerUser(string memory _username, address _address) public isNotRegistered(_address) {
        bytes32 id = keccak256(abi.encodePacked(block.timestamp, _username, _address));
        User memory newUser = User({username: _username, userAddress: _address, userId: id});
        users.push(newUser);
        isRegistered[_address] = true;
        TotalUsers++;
    }

    function createNewAsset(
        // address _minterAddress,
        address _holderAddress,
        bytes32 _userId,
        string memory _description,
        uint256 _price,
        assetType _classType
    ) public {
        require(HoldingAssets[_holderAddress] <= MAX_ASSET_PER_USER, "Max Assets reached");
        require(zephyrNft.hasRole(zephyrNft.MINTER_ROLE(), msg.sender), "Cannot Interact with the contract");
        bytes32 id = keccak256(abi.encodePacked(_holderAddress, _classType, _price));
        Assets memory newAsset = Assets({
            holderAddress: _holderAddress,
            description: _description,
            price: _price,
            classType: _classType,
            assetId: id
        });

        zephyrNft.safeMint(_holderAddress);

        assets.push(newAsset);
        HoldingAssets[_holderAddress]++;
        TotalAssets++;
        idExists[id] = true;
        getAssetIdFromDescription[_description] = id;
        userTransactions[_userId].push(transactionType.Mint);
    }

    function testMint() public {
        zephyrNft.safeMint(msg.sender);
    }

    /// @notice Allows a registered user to create a listing for an asset
    /// @param _assetId The unique identifier of the asset
    /// @param _userId The unique identifier of the user creating the listing
    /// @param _newDescription New description for the asset
    /// @param _listingPrice Price at which the asset is listed for sale
    /// @dev Updates asset details for listing and records the transaction
    function createListing(bytes32 _assetId, bytes32 _userId, string memory _newDescription, uint256 _listingPrice)
        public
        isAlreadyRegistered(msg.sender)
    {
        bool assetExists = false;
        uint256 assetIndex = 0;
        for (uint256 i = 0; i < assets.length; i++) {
            if (assets[i].assetId == _assetId) {
                assetExists = true;
                assetIndex = i;
                break;
            }
        }
        if (assetExists == false) revert CannotFindAsset(_assetId);
        require(assets[assetIndex].holderAddress == msg.sender, "Caller is not the asset owner.");
        // Update asset details for listing
        assets[assetIndex].price = _listingPrice;
        assets[assetIndex].description = _newDescription;
        // Optionally, mark the asset as listed in some way
        // Record the transaction
        userTransactions[_userId].push(transactionType.Sale);
        isListed[_assetId] = true;
    }

    /// @notice Allows a user to buy a listed asset
    /// @param assetId The unique identifier of the asset to be purchased
    /// @param description A description of the asset
    /// @param sellerUserId The unique identifier of the seller
    /// @param sellerAddress sellers' address
    /// @param buyerId buyer's id
    /// @dev Transfers ownership of the asset and updates the price to zero (unlisted)
    function buyAsset(
        bytes32 assetId,
        bytes32 buyerId,
        string memory description,
        bytes32 sellerUserId,
        address sellerAddress
    ) public payable isAlreadyRegistered(msg.sender) {
        require(isListed[assetId] == true, "Asset Is not Listed");
        require(
            getAssetIdFromDescription[description] == assetId,
            "Wrong call : Description Do not match any identification"
        );
        bool assetTransferred = false;
        // Asset asset = userAssets[sellerUserId][0];
        uint256 assetIndex = 0;
        for (uint256 i = 0; i < userAssets[sellerUserId].length; i++) {
            if (userAssets[sellerUserId][i].assetId == assetId) {
                assetIndex = i;
                require(msg.value == userAssets[sellerUserId][i].price, "Insufficient Funds");
                userAssets[buyerId].push(userAssets[sellerUserId][i]);
                delete userAssets[sellerUserId][i];
                assetTransferred = true;
                break;
            }
        }
        // require(assetTransferred, "Asset not found or transfer failed");
        isListed[assetId] = false;
        HoldingAssets[msg.sender]++;
        HoldingAssets[sellerAddress]--;
        (bool sent,) = sellerAddress.call{value: msg.value}("");
        require(sent, "Failed to send value");
    }

    /// @notice Allows a user to place a bid on an asset
    /// @param _assetId The unique identifier of the asset
    /// @param _userId The unique identifier of the bidder
    /// @param _bidAmount The amount of the bid
    /// @dev Records the bid and updates asset state if necessary
    function placeBid(bytes32 _assetId, bytes32 _userId, uint256 _bidAmount) public {}


    event AssetUnlisted(bytes32 assetId, bytes32 userId);
    /// @notice Removes a listing for an asset
    /// @param assetId The unique identifier of the asset to be unlisted
    /// @dev Sets the asset price to zero and updates its state to unlisted
    function removeListing(bytes32 assetId, bytes32 userId) public isAlreadyRegistered(msg.sender) {
        require(isListed[assetId] == true, "Asset Already unlisted");
        bool isOwner;
        for (uint256 i = 0; i < userAssets[userId].length; i++) {
            if (userAssets[userId][i].assetId == assetId) {
                isOwner = true;
                isListed[assetId] = false;
                emit AssetUnlisted(assetId, userId);
                break;
            }
        }

        require(isOwner == true, "Caller is not the owner of the asset");
    }

    function removeAsset(bytes32 assetId) public {
        require(isListed[assetId] == false, "Cannot remove Asset");
    }

    function modifyAssetDescription() private {}

    function modifyAssetPrice() private {}

    function modifyAssetAddressOwner() private {}

    function getNumberOfHolders() public view returns (uint256) {
        return TotalUsers;
    }

    function getUserTransactionHistory(bytes32 _userId) public view returns (transactionType[] memory) {
        return userTransactions[_userId];
    }

    function getUserId() public view returns (bytes32) {
        return getId[msg.sender];
    }

    function getAssetid(string memory description) public view returns (bytes32) {
        return getAssetIdFromDescription[description];
    }
}
