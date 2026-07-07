// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {PersonhoodSBT} from "../src/PersonhoodSBT.sol";

contract PersonhoodSBTTest is Test {
    PersonhoodSBT internal sbt;

    address internal registry = address(this); // this test acts as the registry
    address internal alice = address(0xA11CE);
    address internal bob = address(0xB0B);
    address internal outsider = address(0xBEEF);

    bytes32 internal constant NULL = keccak256("nullifier-1");

    function setUp() public {
        // deployer = this test contract
        sbt = new PersonhoodSBT();
        sbt.setRegistry(registry);
    }

    // --- setRegistry wiring ---

    function test_setRegistry_onlyOnce() public {
        vm.expectRevert(PersonhoodSBT.RegistryAlreadySet.selector);
        sbt.setRegistry(address(0x1234));
    }

    function test_setRegistry_onlyDeployer() public {
        PersonhoodSBT fresh = new PersonhoodSBT(); // deployer = this
        vm.prank(outsider);
        vm.expectRevert(PersonhoodSBT.OnlyDeployer.selector);
        fresh.setRegistry(registry);
    }

    // --- mint / registry gating ---

    function test_onlyRegistry_mint() public {
        vm.prank(outsider);
        vm.expectRevert(PersonhoodSBT.OnlyRegistry.selector);
        sbt.mint(alice, NULL);
    }

    function test_mint_setsOwnerAndBalance() public {
        uint256 tokenId = sbt.mint(alice, NULL);
        assertEq(tokenId, uint256(NULL));
        assertEq(sbt.ownerOfNullifier(NULL), alice);
        assertEq(sbt.ownerOf(uint256(NULL)), alice);
        assertEq(sbt.balanceOf(alice), 1);
    }

    function test_mint_twice_reverts() public {
        sbt.mint(alice, NULL);
        vm.expectRevert(PersonhoodSBT.AlreadyMinted.selector);
        sbt.mint(bob, NULL);
    }

    // --- soulbound: holder-initiated transfers always revert ---

    function test_transferFrom_reverts() public {
        sbt.mint(alice, NULL);
        vm.prank(alice);
        vm.expectRevert(PersonhoodSBT.Soulbound.selector);
        sbt.transferFrom(alice, bob, uint256(NULL));
    }

    function test_safeTransferFrom_reverts() public {
        sbt.mint(alice, NULL);
        vm.prank(alice);
        vm.expectRevert(PersonhoodSBT.Soulbound.selector);
        sbt.safeTransferFrom(alice, bob, uint256(NULL));
    }

    function test_approve_reverts() public {
        vm.prank(alice);
        vm.expectRevert(PersonhoodSBT.Soulbound.selector);
        sbt.approve(bob, uint256(NULL));
    }

    function test_setApprovalForAll_reverts() public {
        vm.prank(alice);
        vm.expectRevert(PersonhoodSBT.Soulbound.selector);
        sbt.setApprovalForAll(bob, true);
    }

    // --- moveTo (recovery) & burn: registry only ---

    function test_moveTo_updatesOwnerAndBalances() public {
        sbt.mint(alice, NULL);
        sbt.moveTo(NULL, bob);
        assertEq(sbt.ownerOfNullifier(NULL), bob);
        assertEq(sbt.balanceOf(alice), 0);
        assertEq(sbt.balanceOf(bob), 1);
    }

    function test_moveTo_onlyRegistry() public {
        sbt.mint(alice, NULL);
        vm.prank(outsider);
        vm.expectRevert(PersonhoodSBT.OnlyRegistry.selector);
        sbt.moveTo(NULL, bob);
    }

    function test_moveTo_notMinted_reverts() public {
        vm.expectRevert(PersonhoodSBT.NotMinted.selector);
        sbt.moveTo(NULL, bob);
    }

    function test_burn_clearsOwner() public {
        sbt.mint(alice, NULL);
        sbt.burn(NULL);
        assertEq(sbt.ownerOfNullifier(NULL), address(0));
        assertEq(sbt.balanceOf(alice), 0);
        vm.expectRevert(PersonhoodSBT.NotMinted.selector);
        sbt.ownerOf(uint256(NULL));
    }

    function test_burn_onlyRegistry() public {
        sbt.mint(alice, NULL);
        vm.prank(outsider);
        vm.expectRevert(PersonhoodSBT.OnlyRegistry.selector);
        sbt.burn(NULL);
    }

    function test_ownerOf_notMinted_reverts() public {
        vm.expectRevert(PersonhoodSBT.NotMinted.selector);
        sbt.ownerOf(uint256(NULL));
    }

    // --- metadata / interfaces ---

    function test_metadata() public view {
        assertEq(sbt.name(), "Proof of Croatian Personhood");
        assertEq(sbt.symbol(), "POCP");
    }

    function test_supportsInterface() public view {
        assertTrue(sbt.supportsInterface(0x01ffc9a7)); // ERC165
        assertTrue(sbt.supportsInterface(0x80ac58cd)); // ERC721
        assertTrue(sbt.supportsInterface(0x0489b56f)); // EIP-5484
        assertFalse(sbt.supportsInterface(0xffffffff));
    }

    function test_burnAuth_isBoth() public view {
        assertEq(uint256(sbt.burnAuth(uint256(NULL))), uint256(PersonhoodSBT.BurnAuth.Both));
    }
}
