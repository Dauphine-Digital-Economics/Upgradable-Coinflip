// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Test, console2} from "forge-std/Test.sol";
import {Coinflip} from "../src/Coinflip.sol";
import {CoinflipV2} from "../src/CoinflipV2.sol";
import {UUPSProxy} from "../src/Proxy.sol";

contract CoinflipUpgradeTest is Test {
    Coinflip public game;
    CoinflipV2 public gameV2;
    UUPSProxy public proxy;

    Coinflip public wrappedV1;
    CoinflipV2 public wrappedV2;

    address owner = vm.addr(0x1);

    function setUp() public {
        // Set deployer to know address
        
        vm.startPrank(owner);
        // Initialize both versions of the contract
        game = new Coinflip();
        gameV2 = new CoinflipV2();
        
        // Launch the proxy with V1 implementation
        proxy = new UUPSProxy(address(game), abi.encodeWithSignature("initialize(address)", owner));

        // We need to cheat here a litte because the coin flip game is not deployed and the proxy
        // will not know how to access the game unless wrapped. 
        wrappedV1 = Coinflip(address(proxy));
    }

    function test_V1InitialSeed() public {
        assertEq(wrappedV1.seed(), "It is a good practice to rotate seeds often in gambling");
    }

    function test_V2InitialSeed() public {
        // Call the upgrade function with V2
        wrappedV1.upgradeToAndCall(address(gameV2), "");

        // Re-wrap with V2 implementation
        wrappedV2 = CoinflipV2(address(wrappedV1));
        assertEq(wrappedV2.seed(), "It is a good practice to rotate seeds often in gambling");
    }

    function test_V2Seed() public {
        // Upgrade the proxy to V2 and wrap it
        wrappedV1.upgradeToAndCall(address(gameV2), "");
        wrappedV2 = CoinflipV2(address(proxy));

        wrappedV2.seedRotation("1234567890");
        assertEq(wrappedV2.seed(), "6789012345");
    }


}