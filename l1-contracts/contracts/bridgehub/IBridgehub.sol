// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import {L2CanonicalTransaction, L2Message, L2Log, TxStatus} from "../common/Messaging.sol";
import {IL1AssetHandler} from "../bridge/interfaces/IL1AssetHandler.sol";
import {IAssetRouterBase} from "../bridge/interfaces/IAssetRouterBase.sol";
import {ISTMDeploymentTracker} from "./ISTMDeploymentTracker.sol";
import {IMessageRoot} from "./IMessageRoot.sol";

struct L2TransactionRequestDirect {
    uint256 chainId;
    uint256 mintValue;
    address l2Contract;
    uint256 l2Value;
    bytes l2Calldata;
    uint256 l2GasLimit;
    uint256 l2GasPerPubdataByteLimit;
    bytes[] factoryDeps;
    address refundRecipient;
}

struct L2TransactionRequestTwoBridgesOuter {
    uint256 chainId;
    uint256 mintValue;
    uint256 l2Value;
    uint256 l2GasLimit;
    uint256 l2GasPerPubdataByteLimit;
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

interface IBridgehub is IL1AssetHandler {
    /// @notice pendingAdmin is changed
    /// @dev Also emitted when new admin is accepted and in this case, `newPendingAdmin` would be zero address
    event NewPendingAdmin(address indexed oldPendingAdmin, address indexed newPendingAdmin);

    /// @notice Admin changed
    event NewAdmin(address indexed oldAdmin, address indexed newAdmin);

    /// @notice STM asset registered
    event AssetRegistered(
        bytes32 indexed assetInfo,
        address indexed _assetAddress,
        bytes32 indexed additionalData,
        address sender
    );

    /// @notice Starts the transfer of admin rights. Only the current admin can propose a new pending one.
    /// @notice New admin can accept admin rights by calling `acceptAdmin` function.
    /// @param _newPendingAdmin Address of the new admin
    function setPendingAdmin(address _newPendingAdmin) external;

    /// @notice Accepts transfer of admin rights. Only pending admin can accept the role.
    function acceptAdmin() external;

    /// Getters
    function stateTransitionManagerIsRegistered(address _stateTransitionManager) external view returns (bool);

    function stateTransitionManager(uint256 _chainId) external view returns (address);

    function tokenIsRegistered(address _baseToken) external view returns (bool);

    function baseToken(uint256 _chainId) external view returns (address);

    function baseTokenAssetId(uint256 _chainId) external view returns (bytes32);

    function sharedBridge() external view returns (IAssetRouterBase);

    function getHyperchain(uint256 _chainId) external view returns (address);

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

    function requestL2TransactionDirect(
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
        uint256 _salt,
        address _admin,
        bytes calldata _initData,
        bytes[] calldata _factoryDeps
    ) external returns (uint256 chainId);

    function addStateTransitionManager(address _stateTransitionManager) external;

    function removeStateTransitionManager(address _stateTransitionManager) external;

    function addToken(address _token) external;

    function setAddresses(
        address _sharedBridge,
        address _l1Nullifier,
        ISTMDeploymentTracker _stmDeployer,
        IMessageRoot _messageRoot
    ) external;

    // function relayTxThroughBH(uint256 _baseDestChainId, uint256 _destChainId, bytes calldata _dataToRelay) external;

    // function registerCounterpart(uint256 chainid, address _counterpart) external;

    event NewChain(uint256 indexed chainId, address stateTransitionManager, address indexed chainGovernance);

    function whitelistedSettlementLayers(uint256 _chainId) external view returns (bool);

    function registerSyncLayer(uint256 _newSyncLayerChainId, bool _isWhitelisted) external;

    // function finalizeMigrationToSyncLayer(
    //     uint256 _chainId,
    //     address _baseToken,
    //     address _sharedBridge,
    //     address _admin,
    //     uint256 _expectedProtocolVersion,
    //     HyperchainCommitment calldata _commitment,
    //     bytes calldata _diamondCut
    // ) external;

    function forwardTransactionOnSyncLayer(
        uint256 _chainId,
        L2CanonicalTransaction calldata _transaction,
        bytes[] calldata _factoryDeps,
        bytes32 _canonicalTxHash,
        uint64 _expirationTimestamp
    ) external;

    function stmAssetInfoFromChainId(uint256 _chainId) external view returns (bytes32);

    function stmAssetInfo(address _stmAddress) external view returns (bytes32);

    function stmDeployer() external view returns (ISTMDeploymentTracker);

    function setSTMDeployer(ISTMDeploymentTracker _stmDeployer) external;

    function stmAssetInfoToAddress(bytes32 _assetInfo) external view returns (address);

    function setAssetHandlerAddressInitial(bytes32 _additionalData, address _assetAddress) external;

    function L1_CHAIN_ID() external view returns (uint256);

    function messageRoot() external view returns (IMessageRoot);
}
