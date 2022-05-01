// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./StakingInterface.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract DelegationDAO is AccessControl {
    using SafeMath for uint256;

    bytes32 public constant MEMBER = keccak256("MEMBER");

    enum DaoState {
        COLLECTING,
        STAKING,
        REVOKING,
        REVOKED
    }

    DaoState currentState;

    // keep track of the member stakes
    mapping(address => uint256) public memberStakes;

    // total amount of pool stake.
    uint256 public totalStake;

    // Parachain Staking wrapper at the known precompile address.
    // This will be used to make a calls to the underlying staking mechanism.
    ParachainStaking public staking;

    // Moonbase Alpha precompile address.
    address public constant PRECOMPILE_ADDRESS = 0x0000000000000000000000000000000000000800;

    // minimum delegation amount
    uint256 public constant MIN_STAKING = 5 ether;

    // The cololactor we want to delegate to
    address public target;

    // Initialize a new DelegationDao dedicated to delegating to the given callactor target.
    constructor(address _target, address admin) {
        target = _target;

        staking = ParachainStaking(PRECOMPILE_ADDRESS);

        _setupRole(DEFAULT_ADMIN_ROLE, admin);
        _setupRole(MEMBER, admin);

        currentState = DaoState.COLLECTING;
    }

    // Grants a user the role of admin
    function grantAdmin(address newAdmin) public onlyRole(DEFAULT_ADMIN_ROLE) onlyRole(MEMBER) {
        grantRole(DEFAULT_ADMIN_ROLE, newAdmin);
        grantRole(MEMBER, newAdmin);
    }

    // Grants a user membership
    function grantMember(address newMember) public onlyRole(DEFAULT_ADMIN_ROLE) {
        grantRole(MEMBER, newMember);
    }

    // Remove a user membership
    function removeMember(address payable member) public onlyRole(DEFAULT_ADMIN_ROLE) {
        revokeRole(MEMBER, member);
    }

    // Check free balance for member.
    function checkFreeBalance() public view onlyRole(MEMBER) returns (uint256) {
        return address(this).balance;
    }

    // Change target,  admin only.
    function changeTarget(address newCollactor) public onlyRole(DEFAULT_ADMIN_ROLE) {
        target = newCollactor;
    }

    // Get the current state of the Dao
    function getState() public view returns (DaoState) {
        return currentState;
    }

    function addStake() external payable onlyRole(MEMBER) {
        if (currentState == DaoState.STAKING) {
            // Sanity check
            if (!staking.is_delegator(address(this))) {
                revert("This DAO is in an inconstent State");
            }
            memberStakes[msg.sender] = memberStakes[msg.sender].add(msg.value);
            totalStake = totalStake.add(msg.value);
            staking.delegator_bond_more(target, msg.value);
        } else if (currentState == DaoState.COLLECTING) {
            memberStakes[msg.sender] = memberStakes[msg.sender].add(msg.value);
            totalStake = totalStake.add(msg.value);

            if (totalStake < MIN_STAKING) {
                return;
            } else {
                staking.delegate(
                    target,
                    address(this).balance,
                    staking.candidate_delegation_count(target),
                    staking.delegator_delegation_count(address(this))
                );
            }
        } else {
            revert("The DAO is not accepting");
        }
    }
}
