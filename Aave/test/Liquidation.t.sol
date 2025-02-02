// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "../lib/forge-std/src/Test.sol";
import {IERC20} from '../src/dependencies/openzeppelin/contracts/IERC20.sol';
import "../src/interfaces/IPool.sol";
import "../src/interfaces/IPoolAddressesProvider.sol";
import "../src/Mock/TestState.sol";
import "../src/Mock/AddressList.sol";
import "../src/protocol/libraries/types/DataTypes.sol";

contract LiquidationTest is Test {
    IPool Pool = IPool(AddressList.POOL);
    IERC20 WETH = IERC20(AddressList.WETH);
    IERC20 DAI = IERC20(AddressList.DAI);
    address user_1 = TestState.user_1;
    address user_2 = TestState.user_2;
    function setUp() public {
        vm.createSelectFork("ETH_RPC_URL", TestState.BLOCK_NUMBER);
    }

    function test_simple_liquidate() public {
        vm.startPrank(user_1);
        deal(address(WETH), user_1, 1 * 1e18);
        WETH.approve(address(Pool), 1 * 1e18);
        Pool.supply(address(WETH), 1 * 1e18, user_1, 0);
        DataTypes.ReserveData memory ReserveData = Pool.getReserveData(address(WETH));
        uint256 MintAWETH = IERC20(address(ReserveData.aTokenAddress)).balanceOf(user_1);
        assert(MintAWETH == 1 * 1e18);

        Pool.borrow(address(DAI), 1_940 * 1e18, 2, 0, user_1);
        uint256 BorrowDAI = IERC20(address(DAI)).balanceOf(user_1);
        assert(BorrowDAI == 1_940 * 1e18);
        vm.stopPrank();

        vm.warp(block.timestamp + 31_536_000);

        vm.startPrank(user_2);
        deal(address(DAI), user_2, 100_000 * 1e18);
        DAI.approve(address(Pool), type(uint256).max);

        Pool.liquidationCall(address(WETH), address(DAI), user_1, 1_000 * 1e18, false);
    }

}