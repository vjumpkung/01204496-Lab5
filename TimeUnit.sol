// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.5.0 <0.9.0;

contract TimeUnit {
    // Declaring a  state variable that will
    // store the current block timestamp
    // as seconds since unix epoch(January 1, 1970)
    mapping (address => uint256) public startTime;

    // setting the startTime variable
    function setStartTime(address add) public {
        startTime[add] = block.timestamp;
    }

    // calculates numbers of seconds that
    // have been elapsed since the startTime
    // variable was set
    function elapsedSeconds(address add) public view returns (uint256) {
        return (block.timestamp - startTime[add]);
    }

    // calculates numbers of minutes that have been
    // elapsed since the startTime variable was set
    function elapsedMinutes(address add) public view returns (uint256) {
        // Both block.timestamp and startTime are in seconds
        // Dividing them by 1 minutes == 60 seconds to find
        // equivalent number of minutes
        return (block.timestamp - startTime[add]) / 1 minutes;
    }
}
