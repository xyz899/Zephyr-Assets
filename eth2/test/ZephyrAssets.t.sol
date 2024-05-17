// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import {Test, console2} from "forge-std/Test.sol";
import {AssetManager} from "../src/AssetsManagerV1.sol";
import {Zephyr} from "../src/ZephyrTokenV1.sol";
import "forge-std/console.sol";

/// @title Zephyr Test Contract
/// @dev Testing contract for Asset Manager and Zephyr Token functionalities
contract ZephyrTest is Test {
    AssetManager assets;
    Zephyr zephyrToken;

    struct fuzz {
        string name;
        address addr;
    }

    uint256 constant JEWELRY_PRICE = 41;
    fuzz admin = fuzz("John Marston", makeAddr("johnmarston"));
    fuzz fuzz1 = fuzz("SAMURAI OKISHITA", makeAddr("okishitaSamuraika"));
    fuzz fuzz2 = fuzz("Jean Frank Chabal", makeAddr("JFC"));

    string BASIC_DESCRIPTION = "A red white incrusted diamond watch";

    /// @notice Sets up the testing environment before each test
    /// @dev Deploys Zephyr and AssetManager contracts and registers an admin user
    function setUp() public {
        zephyrToken = new Zephyr(admin.addr, admin.addr, admin.addr);
        assets = new AssetManager(address(zephyrToken), admin.addr);
        vm.prank(admin.addr);
        assets.registerUser(admin.name, admin.addr);
        assertEq(assets.isRegistered(admin.addr), true);
        vm.prank(fuzz1.addr);
        assets.registerUser(fuzz1.name, fuzz1.addr);
        assertEq(assets.isRegistered(fuzz1.addr), true);
        assets.registerUser(fuzz2.name, fuzz2.addr);
        assertEq(assets.isRegistered(fuzz2.addr), true);
        deal(fuzz1.addr, 100 ether);
        deal(fuzz2.addr, 100 ether);
        vm.startPrank(admin.addr);
        zephyrToken.grantRole(zephyrToken.MINTER_ROLE(), admin.addr);
        zephyrToken.grantRole(zephyrToken.MINTER_ROLE(), address(assets));
        assertEq(zephyrToken.hasRole(zephyrToken.MINTER_ROLE(), admin.addr), true);
        vm.stopPrank();
    }

    /// @notice Tests that registering an already registered user fails
    /// @dev Ensures that the contract prevents duplicate registrations
    function testFailsifAlreadyRegistered() public {
        vm.prank(fuzz1.addr);
        assets.registerUser(fuzz1.name, fuzz1.addr);
        vm.expectRevert();
        assertEq(assets.isRegistered(fuzz1.addr), true);
    }

    /// @notice Tests minting of Zephyr tokens by an admin with MINTER_ROLE
    /// @dev Ensures that an admin can mint Zephyr tokens
    function testZephyrTokensMintwithAdminRole() public {
        vm.prank(admin.addr);
        zephyrToken.safeMint(admin.addr);
        assertEq(zephyrToken.balanceOf(admin.addr), 1);
        assertEq(zephyrToken.ownerOf(0), admin.addr);
    }

    /// @notice Tests granting MINTER_ROLE and minting Zephyr tokens
    /// @dev Ensures that a user with MINTER_ROLE can mint tokens
    function testZephyrTokensGrantAdminRoleAndMint() public {
        bytes32 minterRole = zephyrToken.MINTER_ROLE();
        vm.prank(admin.addr);
        zephyrToken.grantRole(minterRole, fuzz2.addr);
        assertEq(zephyrToken.hasRole(minterRole, fuzz2.addr), true);
        vm.prank(fuzz2.addr);
        zephyrToken.safeMint(fuzz2.addr);
        assertEq(zephyrToken.balanceOf(fuzz2.addr), 1);
        assertEq(zephyrToken.ownerOf(0), fuzz2.addr);
    }

    /// @notice Tests that minting fails for users without MINTER_ROLE
    /// @dev Ensures that the contract enforces role-based access control for minting
    function testMintFailsifNotMINTER() public {
        vm.expectRevert();
        zephyrToken.safeMint(fuzz2.addr);
    }

    function testverifyAdminisMinterandVerifyMinterRoleInternally() public {
        vm.startPrank(admin.addr);
        // internal calls
        bool ZephTokenResult = zephyrToken.hasRole(zephyrToken.MINTER_ROLE(), admin.addr);
        bool AssetsResult = assets.hasRole(assets.MINTER(), admin.addr);
        vm.stopPrank();
        assertEq(ZephTokenResult, true);
        assertEq(AssetsResult, true);
    }

    function testverifyAdminisMinterandVerifyMinterRoleExternally() public {
        // external calls
        vm.startPrank(admin.addr);
        bool ZephTokenResult = zephyrToken.hasRole(assets.MINTER(), admin.addr);
        bool AssetsResult = assets.hasRole(zephyrToken.MINTER_ROLE(), admin.addr);
        vm.stopPrank();
        assertEq(ZephTokenResult, true);
        assertEq(AssetsResult, true);
    }

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with an {AccessControlUnauthorizedAccount} error including the required role.
     *
     * modifier onlyRole(bytes32 role) {
     *     _checkRole(role);
     *     _;
     * }
     *
     * @dev Reverts with an {AccessControlUnauthorizedAccount} error if `_msgSender()`
     * is missing `role`. Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * function _checkRole(bytes32 role) internal view virtual {
     * _checkRole(role, _msgSender());
     * }
     */
    function testCreateNewAsset() public {
        vm.prank(fuzz1.addr);
        bytes32 userId = assets.getUserId();
        vm.startPrank(admin.addr);
        console.logBytes32(zephyrToken.MINTER_ROLE());
        console.logBytes32(userId);
        assets.createNewAsset(fuzz1.addr, userId, BASIC_DESCRIPTION, JEWELRY_PRICE, AssetManager.assetType.jewelry);
        assertEq(assets.HoldingAssets(fuzz1.addr), 1);
        vm.stopPrank();
    }

    function testcreateListingWithFuzz() public {
        vm.prank(fuzz1.addr);
        bytes32 userId = assets.getUserId();
        vm.prank(admin.addr);
        assets.createNewAsset(fuzz1.addr, userId, BASIC_DESCRIPTION, JEWELRY_PRICE, AssetManager.assetType.jewelry);
        bytes32 assetId = assets.getAssetid(BASIC_DESCRIPTION);
        vm.prank(fuzz1.addr);
        assets.createListing(assetId, userId, BASIC_DESCRIPTION, 15);
        assertEq(assets.isListed(assetId), true);
        assertEq(assets.HoldingAssets(fuzz1.addr), 1);
    }

    function testBuyingAnAsset() public {
        vm.prank(fuzz1.addr);
        bytes32 fuzz1UserId = assets.getUserId();
        vm.prank(admin.addr);
        assets.createNewAsset(fuzz1.addr, fuzz1UserId, BASIC_DESCRIPTION, JEWELRY_PRICE, AssetManager.assetType.jewelry);
        bytes32 assetId = assets.getAssetid(BASIC_DESCRIPTION);
        vm.prank(fuzz1.addr);
        assets.createListing(assetId, fuzz1UserId, BASIC_DESCRIPTION, 15);
        vm.startPrank(fuzz2.addr);
        bytes32 fuzz2UserId = assets.getUserId();
        assets.buyAsset{value: 15 ether}(assetId, fuzz2UserId, BASIC_DESCRIPTION, fuzz1UserId, fuzz1.addr);
        vm.stopPrank();
        assertEq(assets.isListed(assetId), false);
        assertEq(assets.HoldingAssets(fuzz2.addr), 1);
        assertEq(assets.HoldingAssets(fuzz1.addr), 0);
        console.log("The balance of fuzz1 is :", fuzz1.addr.balance);
        assertEq(fuzz1.addr.balance, 115 ether);
        assertEq(fuzz2.addr.balance, 85 ether);
    }

    function testRemoveListingAnAsset() public {
        vm.prank(fuzz1.addr);
        bytes32 fuzz1UserId = assets.getUserId();
        vm.startPrank(admin.addr);
        assets.createNewAsset(fuzz1.addr, fuzz1UserId, BASIC_DESCRIPTION, JEWELRY_PRICE, AssetManager.assetType.jewelry);
        assets.createNewAsset(fuzz1.addr, fuzz1UserId, "A Golden Kebab", 10, AssetManager.assetType.other);
        bytes32 assetId = assets.getAssetid(BASIC_DESCRIPTION);
        vm.stopPrank();

        vm.startPrank(fuzz1.addr);
        assets.createListing(assetId, fuzz1UserId, BASIC_DESCRIPTION, 15);
        assets.removeListing(assetId, fuzz1UserId);
        assertEq(assets.isListed(assetId), false);
        vm.stopPrank();

        vm.startPrank(fuzz2.addr);
        bytes32 fuzz2UserId = assets.getUserId();
        vm.expectRevert();
        assets.buyAsset{value: 15 ether}(assetId, fuzz2UserId, BASIC_DESCRIPTION, fuzz1UserId, fuzz1.addr);
        vm.stopPrank();
        
        assertEq(assets.HoldingAssets(fuzz1.addr), 1);
    }
}
