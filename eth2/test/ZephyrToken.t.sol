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