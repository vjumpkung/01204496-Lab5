// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.2 <0.9.0;

// copy from 204496/219493 (ภาคปลาย 2567) การเงินแบบรวมศูนย์กับแบบกระจายศูนย์ (CeFi vs DeFi) and modify by adding address to specific address by parameters not contract address.

contract CommitReveal {
    uint8 public max = 100;

    struct Commit {
        bytes32 commit;
        uint64 block;
        bool revealed;
    }

    mapping(address => Commit) public commits;

    function commit(bytes32 dataHash, address add) public {
        commits[add].commit = dataHash;
        commits[add].block = uint64(block.number);
        commits[add].revealed = false;
        emit CommitHash(add, commits[add].commit, commits[add].block);
    }

    event CommitHash(address sender, bytes32 dataHash, uint64 block);

    function reveal(bytes32 revealHash, address add) public {
        //make sure it hasn't been revealed yet and set it to revealed
        require(
            commits[add].revealed == false,
            "CommitReveal::reveal: Already revealed"
        );
        commits[add].revealed = true;
        //require that they can produce the committed hash
        require(
            getHash(revealHash) == commits[add].commit,
            "CommitReveal::reveal: Revealed hash does not match commit"
        );
        //require that the block number is greater than the original block
        require(
            uint64(block.number) > commits[add].block,
            "CommitReveal::reveal: Reveal and commit happened on the same block"
        );
        //require that no more than 250 blocks have passed
        require(
            uint64(block.number) <= commits[add].block + 250,
            "CommitReveal::reveal: Revealed too late"
        );
        //get the hash of the block that happened after they committed
        bytes32 blockHash = blockhash(commits[add].block);
        //hash that with their reveal that so miner shouldn't know and mod it with some max number you want
        uint256 random = uint256(
            keccak256(abi.encodePacked(blockHash, revealHash))
        ) % max;
        emit RevealHash(add, revealHash, random);
    }

    event RevealHash(address sender, bytes32 revealHash, uint256 random);

    function getHash(bytes32 data) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(data));
    }
}
