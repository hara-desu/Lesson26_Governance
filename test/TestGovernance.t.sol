// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {Governance} from "../src/Governance.sol";
import {MyToken} from "../src/MyToken.sol";

contract TestGovernance is Test {
    Governance public governance;
    MyToken public myToken;

    uint256 public constant FUND_CONTRACT_VALUE = 5e16;
    uint256 public constant MYTOKEN_MINT_VALUE = 100;
    address public constant TO = address(0x4);
    address public constant USER = address(0x3);
    uint public constant SEND_VALUE = 1234000;
    uint8 public constant VOTE_POSITIVE = 1;
    uint8 public constant VOTE_NEGATIVE = 0;
    string public FUNC = "Function()";
    bytes public DATA = bytes("uint256 _funcParameter");
    string public DESC = "Please, execute this function.";

    enum ProposalState {
        Pending,
        Active,
        Succeeded,
        Defeated,
        Executed
    }

    function setUp() public {
        myToken = new MyToken();
        governance = new Governance(myToken);
        vm.deal(address(governance), FUND_CONTRACT_VALUE);
        myToken.mint(MYTOKEN_MINT_VALUE, USER);
    }

    /////////////
    /* propose */
    /////////////

    function testProposeRevertsIfUserDoesNotHaveTokens() public {
        // Act / Assert
        vm.expectRevert("Not enough tokens");
        vm.prank(address(0x1));
        bytes32 proposalId = governance.propose(
            TO,
            SEND_VALUE,
            FUNC,
            DATA,
            DESC
        );
    }

    function testProposeRevertsIfProposalExists() public {
        // Act / Assert
        vm.prank(USER);
        bytes32 proposalId1 = governance.propose(
            TO,
            SEND_VALUE,
            FUNC,
            DATA,
            DESC
        );
        vm.expectRevert("Proposal already exists");
        vm.prank(USER);
        bytes32 proposalId2 = governance.propose(
            TO,
            SEND_VALUE,
            FUNC,
            DATA,
            DESC
        );
    }

    function testProposalGetsRecorded() public {
        // Act
        vm.prank(USER);
        bytes32 proposalId = governance.propose(
            TO,
            SEND_VALUE,
            FUNC,
            DATA,
            DESC
        );

        (uint votingStarts, , ) = governance.proposals(proposalId);

        // Assert
        assert(votingStarts != 0);
    }

    //////////
    /* vote */
    //////////

    function testVoteRevertsIfProposalDoesNotExist() public {
        // Arrange
        bytes32 proposalId = governance.generateProposalId(
            TO,
            SEND_VALUE,
            FUNC,
            DATA,
            keccak256(bytes(DESC))
        );

        // Act / Assert
        vm.expectRevert("Proposal doesn't exist");
        vm.prank(USER);
        governance.vote(proposalId, VOTE_NEGATIVE);
    }

    function testVoteRevertsIfProposalStateNotActive() public {
        // Arrange
        vm.prank(USER);
        bytes32 proposalId = governance.propose(
            TO,
            SEND_VALUE,
            FUNC,
            DATA,
            DESC
        );

        // Act / Assert
        vm.expectRevert("Invalid state");
        vm.prank(USER);
        governance.vote(proposalId, VOTE_NEGATIVE);
    }

    function testVoteRevertsIfUserDoesNotHaveEnoughTokens() public {
        // Arrange
        vm.prank(USER);
        bytes32 proposalId = governance.propose(
            TO,
            SEND_VALUE,
            FUNC,
            DATA,
            DESC
        );
        address noFundsUser = address(0x5);
        vm.warp(block.timestamp + 15);

        // Act / Assert
        vm.expectRevert("Not enough tokens");
        vm.prank(noFundsUser);
        governance.vote(proposalId, VOTE_NEGATIVE);
    }

    function testCheckVoteRevertsIfAlreadyVoted() public {
        // Arrange
        vm.prank(USER);
        bytes32 proposalId = governance.propose(
            TO,
            SEND_VALUE,
            FUNC,
            DATA,
            DESC
        );
        address votingUser = address(0x5);
        myToken.mint(MYTOKEN_MINT_VALUE, votingUser);

        vm.warp(block.timestamp + 15);

        vm.prank(votingUser);
        governance.vote(proposalId, VOTE_POSITIVE);

        // Act / Assert
        vm.expectRevert("Already voted");
        vm.prank(votingUser);
        governance.vote(proposalId, VOTE_NEGATIVE);
    }

    ///////////
    /* state */
    ///////////

    function testStateRevertsIfProposalDoesNotExist() public {
        // Arrange
        bytes32 proposalId = governance.generateProposalId(
            TO,
            SEND_VALUE,
            FUNC,
            DATA,
            keccak256(bytes(DESC))
        );

        // Act / Assert
        vm.expectRevert("Proposal doesn't exist");
        governance.state(proposalId);
    }

    function testStateReturnsPending() public {
        // Arrange
        vm.prank(USER);
        bytes32 proposalId = governance.propose(
            TO,
            SEND_VALUE,
            FUNC,
            DATA,
            DESC
        );

        // Act / Assert
        Governance.ProposalState state = governance.state(proposalId);
        assertEq(uint(state), uint(Governance.ProposalState.Pending));
    }

    function testStateReturnsActive() public {
        // Arrange
        vm.prank(USER);
        bytes32 proposalId = governance.propose(
            TO,
            SEND_VALUE,
            FUNC,
            DATA,
            DESC
        );

        vm.warp(block.timestamp + 15);

        // Act / Assert
        Governance.ProposalState state = governance.state(proposalId);
        assertEq(uint(state), uint(Governance.ProposalState.Active));
    }

    ////////////////////////
    /* generateProposalId */
    ////////////////////////

    function testGenerateProposalIdWorks() public {
        // Arrange
        bytes32 descriptionHash = keccak256(bytes(DESC));
        bytes32 generatedProposalId = governance.generateProposalId(
            TO,
            SEND_VALUE,
            FUNC,
            DATA,
            descriptionHash
        );
        bytes32 proposalId = keccak256(
            abi.encode(TO, SEND_VALUE, FUNC, DATA, descriptionHash)
        );

        // Act / Assert
        assertEq(generatedProposalId, proposalId);
    }

    /////////////
    /* execute */
    /////////////

    function testExecuteRevertsIfStateNotSucceeded() public {
        // Arrange
        bytes32 descriptionHash = keccak256(bytes(DESC));
        vm.prank(USER);
        bytes32 proposalId = governance.propose(
            TO,
            SEND_VALUE,
            FUNC,
            DATA,
            DESC
        );
        address votingUser = address(0x5);
        myToken.mint(MYTOKEN_MINT_VALUE, votingUser);

        vm.warp(block.timestamp + 15);

        vm.prank(votingUser);
        governance.vote(proposalId, VOTE_NEGATIVE);

        // Act / Assert
        vm.expectRevert("Invalid state");
        governance.execute(TO, SEND_VALUE, FUNC, DATA, descriptionHash);
    }

    function testExecuteWorks() public {
        // Arrange
        bytes32 descriptionHash = keccak256(bytes(DESC));
        vm.prank(USER);
        bytes32 proposalId = governance.propose(
            TO,
            SEND_VALUE,
            FUNC,
            DATA,
            DESC
        );
        address votingUser = address(0x5);
        myToken.mint(MYTOKEN_MINT_VALUE, votingUser);

        vm.warp(block.timestamp + 15);

        vm.prank(votingUser);
        governance.vote(proposalId, VOTE_POSITIVE);

        uint256 votingDelay = governance.VOTING_DELAY();
        uint256 votingDuration = governance.VOTING_DURATION();

        // Act / Assert
        vm.warp(block.timestamp + votingDelay + votingDuration + 1);
        bytes memory resp = governance.execute(
            TO,
            SEND_VALUE,
            FUNC,
            DATA,
            descriptionHash
        );
        assert(resp.length != 0);
    }
}
