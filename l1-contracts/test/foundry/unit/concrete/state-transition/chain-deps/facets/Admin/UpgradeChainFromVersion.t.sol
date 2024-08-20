// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import {AdminTest} from "./_Admin_Shared.t.sol";

import {Diamond} from "contracts/state-transition/libraries/Diamond.sol";
import {IStateTransitionManager} from "contracts/state-transition/IStateTransitionManager.sol";
import {ProtocolIdMismatch, ProtocolIdNotGreater, InvalidProtocolVersion, ValueMismatch, Unauthorized, HashMismatch} from "contracts/common/L1ContractErrors.sol";

contract UpgradeChainFromVersionTest is AdminTest {
    event ExecuteUpgrade(Diamond.DiamondCutData diamondCut);

    function test_revertWhen_calledByNonAdminOrStateTransitionManager() public {
        address nonAdminOrStateTransitionManager = makeAddr("nonAdminOrStateTransitionManager");
        uint256 oldProtocolVersion = 1;
        Diamond.DiamondCutData memory diamondCutData = Diamond.DiamondCutData({
            facetCuts: new Diamond.FacetCut[](0),
            initAddress: address(0),
            initCalldata: new bytes(0)
        });

        vm.startPrank(nonAdminOrStateTransitionManager);
        vm.expectRevert(abi.encodeWithSelector(Unauthorized.selector, nonAdminOrStateTransitionManager));
        adminFacet.upgradeChainFromVersion(oldProtocolVersion, diamondCutData);
    }

    function test_revertWhen_cutHashMismatch() public {
        address admin = utilsFacet.util_getAdmin();
        address stateTransitionManager = makeAddr("stateTransitionManager");

        uint256 oldProtocolVersion = 1;
        Diamond.DiamondCutData memory diamondCutData = Diamond.DiamondCutData({
            facetCuts: new Diamond.FacetCut[](0),
            initAddress: address(0),
            initCalldata: new bytes(0)
        });

        utilsFacet.util_setStateTransitionManager(stateTransitionManager);

        bytes32 cutHashInput = keccak256("random");
        vm.mockCall(
            stateTransitionManager,
            abi.encodeWithSelector(IStateTransitionManager.upgradeCutHash.selector),
            abi.encode(cutHashInput)
        );

        vm.startPrank(admin);
        vm.expectRevert(
            abi.encodeWithSelector(HashMismatch.selector, cutHashInput, keccak256(abi.encode(diamondCutData)))
        );
        adminFacet.upgradeChainFromVersion(oldProtocolVersion, diamondCutData);
    }

    function test_revertWhen_ProtocolVersionMismatchWhenUpgrading() public {
        address admin = utilsFacet.util_getAdmin();
        address stateTransitionManager = makeAddr("stateTransitionManager");

        uint256 oldProtocolVersion = 1;
        Diamond.DiamondCutData memory diamondCutData = Diamond.DiamondCutData({
            facetCuts: new Diamond.FacetCut[](0),
            initAddress: address(0),
            initCalldata: new bytes(0)
        });

        utilsFacet.util_setProtocolVersion(oldProtocolVersion + 1);
        utilsFacet.util_setStateTransitionManager(stateTransitionManager);

        bytes32 cutHashInput = keccak256(abi.encode(diamondCutData));
        vm.mockCall(
            stateTransitionManager,
            abi.encodeWithSelector(IStateTransitionManager.upgradeCutHash.selector),
            abi.encode(cutHashInput)
        );

        vm.startPrank(admin);
        vm.expectRevert(abi.encodeWithSelector(ProtocolIdMismatch.selector, uint256(2), oldProtocolVersion));
        adminFacet.upgradeChainFromVersion(oldProtocolVersion, diamondCutData);
    }

    function test_revertWhen_ProtocolVersionMismatchAfterUpgrading() public {
        address admin = utilsFacet.util_getAdmin();
        address stateTransitionManager = makeAddr("stateTransitionManager");

        uint256 oldProtocolVersion = 1;
        Diamond.DiamondCutData memory diamondCutData = Diamond.DiamondCutData({
            facetCuts: new Diamond.FacetCut[](0),
            initAddress: address(0),
            initCalldata: new bytes(0)
        });

        utilsFacet.util_setProtocolVersion(oldProtocolVersion);
        utilsFacet.util_setStateTransitionManager(stateTransitionManager);

        bytes32 cutHashInput = keccak256(abi.encode(diamondCutData));
        vm.mockCall(
            stateTransitionManager,
            abi.encodeWithSelector(IStateTransitionManager.upgradeCutHash.selector),
            abi.encode(cutHashInput)
        );

        vm.expectRevert(ProtocolIdNotGreater.selector);
        // solhint-disable-next-line func-named-parameters
        vm.expectEmit(true, true, true, true, address(adminFacet));
        emit ExecuteUpgrade(diamondCutData);

        vm.startPrank(admin);
        adminFacet.upgradeChainFromVersion(oldProtocolVersion, diamondCutData);
    }
}
