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

    DaoState public currentState;

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

    // Event for a member deposit
    event Deposit(address indexed _from, uint256 _value);

    // Event for a member withdrawal
    event Withdrawal(address indexed _from, address indexed _to, uint256 _value);

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
        require(
            currentState == DaoState.REVOKED || currentState == DaoState.COLLECTING,
            "The DAO is not in the correct state to changed."
        );
        target = newCollactor;
    }

    function resetDAO() public onlyRole(DEFAULT_ADMIN_ROLE) {
        currentState = DaoState.COLLECTING;
    }

    function addStake() external payable onlyRole(MEMBER) {
        if (currentState == DaoState.STAKING) {
            // Sanity check
            if (!staking.is_delegator(address(this))) {
                revert("This DAO is in an inconstent State");
            }
            memberStakes[msg.sender] = memberStakes[msg.sender].add(msg.value);
            totalStake = totalStake.add(msg.value);

            // emit event
            emit Deposit(msg.sender, msg.value);

            staking.delegator_bond_more(target, msg.value);
        } else if (currentState == DaoState.COLLECTING) {
            memberStakes[msg.sender] = memberStakes[msg.sender].add(msg.value);
            totalStake = totalStake.add(msg.value);

            // emit event
            emit Deposit(msg.sender, msg.value);

            if (totalStake < MIN_STAKING) {
                return;
            } else {
                staking.delegate(
                    target,
                    address(this).balance,
                    staking.candidate_delegation_count(target),
                    staking.delegator_delegation_count(address(this))
                );
                currentState = DaoState.STAKING;
            }
        } else {
            revert("The DAO is not accepting");
        }
    }

    function scheduleRevoke() public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(currentState == DaoState.STAKING, "The DAO is not in the current state to revoke");

        staking.schedule_revoke_delegation(target);
        currentState = DaoState.REVOKING;
    }

    function executeRevoke() internal onlyRole(MEMBER) returns (bool) {
        require(currentState == DaoState.REVOKING, "The DAO is not in the current state to execute");

        staking.execute_delegation_request(address(this), target);
        if (staking.is_delegator(address(this))) {
            return false;
        } else {
            currentState = DaoState.REVOKED;
            return true;
        }
    }

    function withdraw(address payable account) public onlyRole(MEMBER) {
        require(currentState != DaoState.STAKING, "The DAO is not is the correct state to withdraw");

        if (currentState == DaoState.REVOKING) {
            bool result = executeRevoke();
            require(result, "Exit delay period has not finished yet");
        }

        if (currentState == DaoState.REVOKED || currentState == DaoState.COLLECTING) {
            // Sanity checks
            if (staking.is_delegator(address(this))) {
                revert("The DAO is in an inconsistent state");
            }
            require(totalStake != 0, "Cannot divide by zero");

            // Calculate the amount that the member is owned.
            uint256 amount = address(this).balance.mul(memberStakes[msg.sender]).div(totalStake);

            require(checkFreeBalance() >= amount, "Not enough free balance for withdraw");

            Address.sendValue(account, amount);

            totalStake = totalStake.sub(memberStakes[msg.sender]);
            memberStakes[msg.sender] = 0;

            emit Withdrawal(msg.sender, account, amount);
        }
    }
}
