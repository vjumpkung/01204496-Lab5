// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

// Import 2 Smart Contract which necessary for minimum time to allow withdraw and commit-reveal to hide user choice input.
import "TimeUnit.sol";
import "CommitReveal.sol";
import "IERC20.sol";

contract RPS {

    // using MKOL instead of AVAX
    IERC20 public MKOL;

    // Initial Imported Smart Contract
    TimeUnit private timeUnit = new TimeUnit();
    CommitReveal private commitReveal = new CommitReveal();

    // using struct instead of mapping of address->each types
    struct Player {
        uint8 idx;
        bytes32 player_choice; // 01 - Rock, 02 - Paper , 03 - Scissors , 04 = Lizard , 05 = Spock
        bytes32 player_reveal_hash;
        bool player_not_played;
        bool player_not_revealed;
    }

    // Initial smart contract state varaible
    uint256 private numPlayer = 0;
    uint256 private revealCount = 0;
    uint256 private reward = 0;
    uint256 private numInput = 0;
    uint8 private current_idx = 0;

    // mapping(address => bool) private address_list;
    mapping(address => Player) private player;

    address[] private playersAddress = [
        0x0000000000000000000000000000000000000000,
        0x0000000000000000000000000000000000000000
    ];

    constructor() {
        MKOL = IERC20(0x3FC287aA9d2664B8D9A64a682dcf0DFcBE863Ca6);
        // using constructor to hardcoded address to prevent others address to play this game.
        // address_list[0x5B38Da6a701c568545dCfcB03FcB875f56beddC4] = true;
        // address_list[0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2] = true;
        // address_list[0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db] = true;
        // address_list[0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB] = true;
    }

    function addPlayer(address playerAddress) public payable {
        // require(address_list[msg.sender]); // disable to can play with any address
        require(numPlayer < 2); // Check numPlayer must be less than 2 before addPlayer
        if (numPlayer > 0) {
            require(playerAddress != playersAddress[0], "Sender address must not equal to first player"); // Sender address is not equal to first player
        }
        require(MKOL.allowance(msg.sender, playerAddress) == 1000 gwei);

        // require(msg.value == 0.000001 ether); // Sender address must have 0.000001 ETH
        reward += msg.value; // Add reward by msg.value

        player[playerAddress].idx = current_idx;
        player[playerAddress].player_not_played = true;
        player[playerAddress].player_not_revealed = true;

        playersAddress[current_idx] = playerAddress; // push address of sender to array
        numPlayer++; // increase numPlayer by one

        timeUnit.setStartTime(playerAddress); // when addPlayer will collect address to startTime for prevent eth lock in this contract.
        emit gameState(
            numInput,
            revealCount,
            numPlayer,
            current_idx,
            playersAddress
        );
        current_idx = (current_idx + 1) % 2;
    }

    function input(bytes32 choice, address playerAddress) public {
        require(numPlayer == 2, "number of player should be 2"); // Player can input choice when two player use addPlayer into game.
        require(player[playerAddress].player_not_played); // Player must not played (not input)
        require(player[playerAddress].player_not_revealed); // Player must not reveal choice
        require(MKOL.allowance(msg.sender, playerAddress) == 1000 gwei);

        player[playerAddress].player_choice = choice; // assign choice -> should be commit hash
        commitReveal.commit(choice, playerAddress); // we pass address into function to easier mapping in CommitReveal smart contract.
        player[playerAddress].player_not_played = false; // assign not played to false
        numInput++; // Increase numInput
        timeUnit.setStartTime(playerAddress);
        MKOL.transferFrom(playerAddress, msg.sender, 1000 gwei);
        emit gameState(
            numInput,
            revealCount,
            numPlayer,
            current_idx,
            playersAddress
        );
    }

    function revealChoice(bytes32 revealHash, address playerAddress) public {
        require(numInput == 2); // when both player input commit hash player can reveal hash
        commitReveal.reveal(revealHash, playerAddress); // check reveal hash is valid

        player[playerAddress].player_not_revealed = false; // set player is reveal their choice.
        player[playerAddress].player_reveal_hash = revealHash; // assign revealHash into player struct

        revealCount++; // increase revealCount
        timeUnit.setStartTime(playerAddress);
        emit gameState(
            numInput,
            revealCount,
            numPlayer,
            current_idx,
            playersAddress
        );
        if (revealCount == 2) {
            _checkWinnerAndPay(); // game will check winner if revealCount equals 2
        }
    }

    function _reset() private {
        /*
            this function using when game end succesfully and reset for play this game again.
        */
        numPlayer = 0;
        reward = 0;
        numInput = 0;
        revealCount = 0;
        playersAddress[0] = 0x0000000000000000000000000000000000000000;
        playersAddress[1] = 0x0000000000000000000000000000000000000000;
        emit gameState(
            numInput,
            revealCount,
            numPlayer,
            current_idx,
            playersAddress
        );
    }

    function mapChoice(uint256 choice) internal pure returns (uint8) {
        if (choice == 0) return 0; // Rock -> Rock
        if (choice == 1) return 2; // Paper -> Paper becomes position 2
        if (choice == 2) return 4; // Scissors -> Scissors becomes position 4
        if (choice == 3) return 3; // Lizard stays at position 3
        if (choice == 4) return 1; // Spock -> Spock becomes position 1
        revert("Invalid choice");
    }

    function _checkWinnerAndPay() private {
        /*
            get reveeal hash and convert into uint256 and bitwise and with 0xFF and -1 to get real choice like
            0 = Rock, 1 = Paper , 2 = Scissors , 3 = Lizard , 4 = Spock
        */
        bytes32 p0Choice = player[playersAddress[0]].player_reveal_hash;
        bytes32 p1Choice = player[playersAddress[1]].player_reveal_hash;
        address payable account0 = payable(playersAddress[0]);
        address payable account1 = payable(playersAddress[1]);

        uint256 finalPlayer0Choice = (uint256(p0Choice) & 0xFF) - 1;
        uint256 finalPlayer1Choice = (uint256(p1Choice) & 0xFF) - 1;

        /*
            Choice validation -> if invalid, will be tie because each player know their choice already.
        */
        if (!(finalPlayer0Choice <= 4 && finalPlayer0Choice >= 0)) {
            MKOL.transferFrom(msg.sender, account0, reward / 2);
            MKOL.transferFrom(msg.sender, account1, reward / 2);
            // account0.transfer(reward / 2);
            // account1.transfer(reward / 2);
            _reset();
            return;
        }
        if (!(finalPlayer1Choice <= 4 && finalPlayer0Choice >= 0)) {
            MKOL.transferFrom(msg.sender, account0, reward / 2);
            MKOL.transferFrom(msg.sender, account1, reward / 2);
            // account0.transfer(reward / 2);
            // account1.transfer(reward / 2);
            _reset();
            return;
        }

        /*
            if choice is valid will calculate remapping by using mapChoice and judge using modulo method to decide the winner of this game
        */

        emit playerChoice(playersAddress[0], finalPlayer0Choice);
        emit playerChoice(playersAddress[1], finalPlayer1Choice);

        uint8 mappedPlayer0 = mapChoice(finalPlayer0Choice);
        uint8 mappedPlayer1 = mapChoice(finalPlayer1Choice);
        uint8 diff = (5 + mappedPlayer0 - mappedPlayer1) % 5;

        if (diff == 0) {
            // Tie: split the reward between both accounts
            MKOL.transferFrom(msg.sender, account0, reward / 2);
            MKOL.transferFrom(msg.sender, account1, reward / 2);
            // account0.transfer(reward / 2);
            // account1.transfer(reward / 2);
        } else if (diff == 1 || diff == 2) {
            // Player0 wins
            MKOL.transferFrom(msg.sender, account0, reward);
            // account0.transfer(reward);
        } else {
            // diff == 3 || diff == 4
            // Player1 wins
            MKOL.transferFrom(msg.sender, account1, reward);
            // account1.transfer(reward);
        }

        // reset state variable for playing again.
        _reset();
    }

    function getDepositTime(address playerAddress) public view returns (uint256) {
        // using for checking deposit time
        return timeUnit.elapsedSeconds(playerAddress);
    }

    function withdrawMoney() public {
        /*
            This function is allow player to withdraw money from smart contract when elapsed time more than 30 seconds by 2 cases
            1. no 2nd player
            2. both player is not input their commit hash
        */

        // require(address_list[msg.sender]); // disable to allow with any address
        require(msg.sender == playersAddress[player[msg.sender].idx]);
        require(timeUnit.elapsedSeconds(msg.sender) > 5 seconds);
        require(revealCount < 2 || numInput < 2); // 1 player in not reveal or not input commit hash yet
        address payable to = payable(msg.sender);
        to.transfer(0.000001 ether);
        reward--;
        numPlayer--;
        current_idx = (current_idx + 1) % 2;
        if (numInput > 0 && !player[msg.sender].player_not_played) {
            numInput--;
        }
        if (revealCount > 0 && !player[msg.sender].player_not_revealed) {
            revealCount--;
        }
        delete playersAddress[player[msg.sender].idx];
        delete player[msg.sender];
        emit gameState(
            numInput,
            revealCount,
            numPlayer,
            current_idx,
            playersAddress
        );
    }

    event playerChoice(address indexed _player, uint256 choice_num_);
    event gameState(
        uint256 numInput,
        uint256 revealCount,
        uint256 numPlayer,
        uint8 current_idx,
        address[] playersAddress
    );
}
