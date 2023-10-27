// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import { AbstractPortal } from "./AbstractPortal.sol";
import { AttestationPayload } from "./Structs.sol";
import { Ownable } from "./Ownable.sol";
import { Pausable } from "./Pausable.sol";

contract ZeroXScorePortal is
    Ownable,
    Pausable,
    AbstractPortal
{
    struct AttestationRequestData {
        uint64 expirationTime;
        bool revocable;
         address walletAddress;
        uint16 score;
        uint256 chainId;
        bool isSybil;
        uint256 updated;
    }


    struct AttestationRequest {
        bytes32 schema;
        AttestationRequestData data;
    }
    /*#########################
    ##        Errors         ##
    ##########################*/

    /// @dev Error thrown when the withdraw fails
    error WithdrawFail();

    /// @dev Error thrown when the attestation is expired
    error AttestationExpired();

    /*#########################
    ##      Constructor      ##
    ##########################*/

    /**
     * @notice Contract constructor
     * @param modules list of modules to use for the portal (can be empty)
     * @param router the Router's address
     * @dev This sets the addresses for the AttestationRegistry, ModuleRegistry and PortalRegistry
     */
    constructor(
        address[] memory modules,
        address router
    ) AbstractPortal(modules, router) {}

    /*#########################
    ##    Write Functions    ##
    ##########################*/

    /**
     * @dev Pauses the contract.
     * See {Pausable-_pause}.
     * Can only be called by the owner.
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev Unpauses the contract.
     * See {Pausable-_unpause}.
     * Can only be called by the owner.
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /// @inheritdoc AbstractPortal
    function withdraw(
        address payable to,
        uint256 amount
    ) external override onlyOwner {
        (bool s, ) = to.call{ value: amount }("");
        if (!s) revert WithdrawFail();
    }


    function attest0xScoreSimple(
        bytes32 schema,
        uint64 expirationTime,
        bool revocable,
        address walletAddress,
        uint16 score,
        uint256 chainId,
        bool isSybil,
        uint256 updated,
        bytes[] memory validationPayload
    ) public payable whenNotPaused {
        AttestationRequestData memory attestationRequestData = AttestationRequestData(
            expirationTime,
            revocable,
             walletAddress,
             score,
             chainId,
             isSybil,
             updated
        );
        AttestationRequest memory attestationRequest = AttestationRequest(
            schema,
            attestationRequestData
        );
        attest0xScore(attestationRequest, validationPayload);
    }


    function attest0xScore(
        AttestationRequest memory attestationRequest,
        bytes[] memory validationPayload
    ) public payable whenNotPaused {
        if (attestationRequest.data.expirationTime < block.timestamp) {
            revert AttestationExpired();
        }

        bytes memory attestationData = abi.encode(
            attestationRequest.data.walletAddress,
            attestationRequest.data.score,
            attestationRequest.data.chainId,
            attestationRequest.data.isSybil,
            attestationRequest.data.updated
        );
        AttestationPayload memory attestationPayload = AttestationPayload(
            attestationRequest.schema,
            attestationRequest.data.expirationTime,
            abi.encode(msg.sender),
            attestationData
        );
        super.attest(attestationPayload, validationPayload);
    }

    function bulkAttest0xScore(
        AttestationRequest[] memory attestationsRequests,
        bytes[] memory validationPayload
    ) external payable {
        for (uint256 i = 0; i < attestationsRequests.length; i++) {
            attest0xScore(attestationsRequests[i], validationPayload);
        }
    }
}