// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;
import "TimeUnit.sol";
import "CommitReveal.sol";

contract RPS {
    struct Player {
        bytes32 player_choice; // 01 - Rock, 02 - Paper , 03 - Scissors , 04 = Lizard , 05 = Spock
        bytes32 player_reveal_hash;
        bool player_not_played;
        bool player_not_revealed;
    }

    TimeUnit private timeUnit = new TimeUnit();
    CommitReveal private commitReveal = new CommitReveal();
    uint256 private numPlayer = 0;
    uint256 private revealCount = 0;
    uint256 private reward = 0;
    uint256 private numInput = 0;
    mapping(address => bool) private address_list;
    mapping(uint256 => uint8) private choice_remap;
    mapping(address => Player) private player;
    address[] private playersAddress;

    constructor() {
        address_list[0x5B38Da6a701c568545dCfcB03FcB875f56beddC4] = true;
        address_list[0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2] = true;
        address_list[0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db] = true;
        address_list[0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB] = true;
        choice_remap[0] = 0; // Rock -> Rock
        choice_remap[1] = 2; // Paper -> Paper becomes position 2
        choice_remap[2] = 4; // Scissors -> Scissors becomes position 4
        choice_remap[3] = 3; // Lizard stays at position 3
        choice_remap[4] = 1; // Spock -> Spock becomes position 1
    }

    function addPlayer() public payable {
        require(address_list[msg.sender]);
        require(numPlayer < 2); // Check numPlayer must be less than 2 before addPlayer
        if (numPlayer > 0) {
            require(msg.sender != playersAddress[0]); // Sender address is not equal to first player
        }
        require(msg.value == 1 ether); // Sender address must have 1 ETH
        reward += msg.value; // Add reward by msg.value

        player[msg.sender].player_not_played = true;
        player[msg.sender].player_not_revealed = true;

        playersAddress.push(msg.sender); // push address of sender to array
        numPlayer++; // increase numPlayer by one

        timeUnit.setStartTime(msg.sender);
    }

    function input(bytes32 choice) public {
        require(numPlayer == 2);
        require(player[msg.sender].player_not_played);
        require(player[msg.sender].player_not_revealed);
        player[msg.sender].player_choice = choice;
        commitReveal.commit(choice, msg.sender);
        player[msg.sender].player_not_played = false;
        numInput++;
    }

    function revealChoice(bytes32 revealHash) public {
        commitReveal.reveal(revealHash, msg.sender);

        player[msg.sender].player_not_revealed = false;
        player[msg.sender].player_reveal_hash = revealHash;

        revealCount++;
        if (revealCount == 2) {
            _checkWinnerAndPay();
        }
    }

    function _reset() private {
        numPlayer = 0;
        reward = 0;
        numInput = 0;
        revealCount = 0;
        delete player[playersAddress[0]];
        delete player[playersAddress[1]];
        playersAddress.pop();
        playersAddress.pop();
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
        bytes32 p0Choice = player[playersAddress[0]].player_reveal_hash;
        bytes32 p1Choice = player[playersAddress[1]].player_reveal_hash;
        address payable account0 = payable(playersAddress[0]);
        address payable account1 = payable(playersAddress[1]);

        uint256 finalPlayer0Choice = (uint256(p0Choice) & 0xFF) - 1;
        uint256 finalPlayer1Choice = (uint256(p1Choice) & 0xFF) - 1;

        if (!(finalPlayer0Choice <= 4 && finalPlayer0Choice >= 0)) {
            player[playersAddress[0]].player_not_played = true;
            player[playersAddress[0]].player_not_revealed = true;
            revealCount--;
            require(
                finalPlayer0Choice <= 4 && finalPlayer0Choice >= 0,
                "Input choice wrong (please reinput commit and re-reveal)"
            );
        }
        if (!(finalPlayer1Choice <= 4 && finalPlayer0Choice >= 0)) {
            player[playersAddress[1]].player_not_played = true;
            player[playersAddress[1]].player_not_revealed = true;
            revealCount--;
            require(
                finalPlayer1Choice <= 4 && finalPlayer0Choice >= 0,
                "Input choice wrong (please reinput commit and re-reveal)"
            );
        }

        emit playerChoice(playersAddress[0], finalPlayer0Choice);
        emit playerChoice(playersAddress[1], finalPlayer1Choice);

        uint8 mappedPlayer0 = mapChoice(finalPlayer0Choice);
        uint8 mappedPlayer1 = mapChoice(finalPlayer1Choice);
        uint8 diff = (5 + mappedPlayer0 - mappedPlayer1) % 5;

        if (diff == 0) {
            // Tie: split the reward between both accounts
            account0.transfer(reward / 2);
            account1.transfer(reward / 2);
        } else if (diff == 1 || diff == 2) {
            // Player0 wins
            account0.transfer(reward);
        } else {
            // diff == 3 || diff == 4
            // Player1 wins
            account1.transfer(reward);
        }

        _reset();
    }

    function getDepositTime() public view returns (uint256) {
        return timeUnit.elapsedSeconds(msg.sender);
    }

    function withdrawMoney() public {
        require(address_list[msg.sender]);
        require(timeUnit.elapsedSeconds(msg.sender) > 30 seconds);
        require(player[msg.sender].player_not_played); // Check if all players are already revealed and committed their choices before withdrawMone
        address payable to = payable(msg.sender);
        to.transfer(1 ether);
        reward--;
        numPlayer--;
        delete player[msg.sender];
        playersAddress.pop();
    }

    event playerChoice(address indexed _player, uint256 choice_num_);
}
