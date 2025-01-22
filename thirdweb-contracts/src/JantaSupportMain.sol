// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract JantaSupportMain {
    string public name;
    string public desc;
    uint256 public goal;
    uint256 public deadline;
    address public owner;
    bool public paused;

    enum CampaignState {
        Active,
        Successful,
        Failed
    }

    CampaignState public state;

    struct Tier {
        string name;
        uint256 amt;
        uint256 backers;
    }

    struct Backer {
        uint256 totalContributions;
        mapping(uint256 => bool) fundedTiers;
    }

    Tier[] public tiers;
    mapping(address => Backer) public backers;

    modifier onlyOwner() {
        require(msg.sender == owner, "only owner can access this");
        _;
    }

    modifier campaignOpen() {
        require(state == CampaignState.Active, "campaign is not active");
        _;
    }

    modifier notPaused() {
        require(!paused, "Contract is paused");
        _;
    }

    constructor(
        address _owner,
        string memory _name,
        string memory _desc,
        uint256 _goal,
        uint256 _durationInDays
    ) {
        name = _name;
        desc = _desc;
        goal = _goal;
        deadline = block.timestamp + (_durationInDays * 1 days);
        owner = _owner;
        state = CampaignState.Active;
    }

    function checkAndUpdateState() internal {
        if (state == CampaignState.Active) {
            if (block.timestamp >= deadline) {
                state = address(this).balance >= goal
                    ? CampaignState.Successful
                    : CampaignState.Failed;
            } else {
                state = address(this).balance >= goal
                    ? CampaignState.Successful
                    : CampaignState.Active;
            }
        }
    }

    function fund(uint256 _index) public payable campaignOpen notPaused {
        require(_index < tiers.length, "tier doesn't exist");
        require(msg.value == tiers[_index].amt, "amount should exact as tier");

        tiers[_index].backers++;

        backers[msg.sender].totalContributions += msg.value;
        backers[msg.sender].fundedTiers[_index] = true;

        checkAndUpdateState();
    }

    function withdraw() public onlyOwner {
        require(address(this).balance >= goal, "goal hasnt reached yet");

        uint256 balance = address(this).balance;

        payable(owner).transfer(balance);
    }

    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function addTier(string memory _name, uint256 _amt) public onlyOwner {
        require(_amt > 0, "amount must be not be less than 0");
        tiers.push(Tier(_name, _amt, 0));
    }

    function removeTier(uint256 _index) public onlyOwner {
        require(_index < tiers.length, "tier doesnt exist");
        tiers[_index] = tiers[tiers.length - 1];
        tiers.pop();
    }

    function refund() public {
        checkAndUpdateState();
        require(state == CampaignState.Failed, "refunds are not avaialble now");
        uint256 amt = backers[msg.sender].totalContributions;
        require(amt > 0, "no contributions to refund");

        backers[msg.sender].totalContributions = 0;
        payable(msg.sender).transfer(amt);
    }

    function hasFundedTier(address _backer, uint256 _index)
        public
        view
        returns (bool)
    {
        return backers[_backer].fundedTiers[_index];
    }

    function getTiers() public view returns (Tier[] memory) {
        return tiers;
    }

    function getCampaignStatus() public view returns (CampaignState) {
        if (state == CampaignState.Active && block.timestamp > deadline) {
            return
                address(this).balance >= goal
                    ? CampaignState.Successful
                    : CampaignState.Failed;
        }
        return state;
    }

    function togglePaused() public onlyOwner {
        paused = !paused;
    }

    function extendDeadline(uint256 _daysToAdd) public onlyOwner campaignOpen {
        deadline += _daysToAdd * 1 days;
    }
}
