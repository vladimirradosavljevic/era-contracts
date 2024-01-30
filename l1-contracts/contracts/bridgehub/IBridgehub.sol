// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

import {IL1Bridge} from "../bridge/interfaces/IL1Bridge.sol";
import "../common/Messaging.sol";
import "../state-transition/IStateTransitionManager.sol";
import "../state-transition/libraries/Diamond.sol";

struct L2TransactionRequestDirect {
    uint256 chainId;
    uint256 mintValue;
    address l2Contract;
    uint256 l2Value;
    bytes l2Calldata;
    uint256 l2GasLimit;
    uint256 l2GasPerPubdataByteLimit;
    uint256 l1GasPriceConverted;
    bytes[] factoryDeps;
    address refundRecipient;
}

struct L2TransactionRequestTwoBridgesOuter {
    uint256 chainId;
    uint256 mintValue;
    uint256 l2Value;
    uint256 l2GasLimit;
    uint256 l2GasPerPubdataByteLimit;
    uint256 l1GasPriceConverted;
    address refundRecipient;
    address secondBridgeAddress;
    uint256 secondBridgeValue;
    bytes secondBridgeCalldata;
}

struct L2TransactionRequestTwoBridgesInner {
    bytes32 magicValue;
    address l2Contract;
    bytes l2Calldata;
    bytes[] factoryDeps;
    bytes32 txDataHash;
}

interface IBridgehub {
    struct ChainData {
        address stateTransitionManager;
        address baseToken;
        address baseTokenBridge;
    }

    /// Getters
    function stateTransitionManagerIsRegistered(address _stateTransitionManager) external view returns (bool);

    function stateTransitionManager(uint256 _chainId) external view returns (address);

    function tokenIsRegistered(address _baseToken) external view returns (bool);

    function baseToken(uint256 _chainId) external view returns (address);

    function wethBridge() external view returns (IL1Bridge);

    function tokenBridgeIsRegistered(address _baseTokenBridge) external view returns (bool);

    function baseTokenBridge(uint256 _chainId) external view returns (address);

    function getStateTransition(uint256 _chainId) external view returns (address);

    /// Mailbox forwarder

    function proveL2MessageInclusion(
        uint256 _chainId,
        uint256 _batchNumber,
        uint256 _index,
        L2Message calldata _message,
        bytes32[] calldata _proof
    ) external view returns (bool);

    function proveL2LogInclusion(
        uint256 _chainId,
        uint256 _batchNumber,
        uint256 _index,
        L2Log memory _log,
        bytes32[] calldata _proof
    ) external view returns (bool);

    function proveL1ToL2TransactionStatus(
        uint256 _chainId,
        bytes32 _l2TxHash,
        uint256 _l2BatchNumber,
        uint256 _l2MessageIndex,
        uint16 _l2TxNumberInBatch,
        bytes32[] calldata _merkleProof,
        TxStatus _status
    ) external view returns (bool);

    function requestL2Transaction(
        L2TransactionRequestDirect calldata _request
    ) external payable returns (bytes32 canonicalTxHash);

    function requestL2TransactionTwoBridges(
        L2TransactionRequestTwoBridgesOuter calldata _request
    ) external payable returns (bytes32 canonicalTxHash);

    function l2TransactionBaseCost(
        uint256 _chainId,
        uint256 _gasPrice,
        uint256 _l2GasLimit,
        uint256 _l2GasPerPubdataByteLimit
    ) external view returns (uint256);

    //// Registry

    function createNewChain(
        uint256 _chainId,
        address _stateTransitionManager,
        address _baseToken,
        address _baseTokenBridge,
        uint256 _salt,
        address _governor,
        bytes calldata _initData
    ) external returns (uint256 chainId);

    function addStateTransitionManager(address _stateTransitionManager) external;

    function removeStateTransitionManager(address _stateTransitionManager) external;

    function addToken(address _token) external;

    function addTokenBridge(address _tokenBridge) external;

    function setWethBridge(address _wethBridge) external;

    event NewChain(uint256 indexed chainId, address stateTransitionManager, address indexed chainGovernance);
}
