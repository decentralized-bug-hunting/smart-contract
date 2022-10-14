// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract DeBounty {
    address public admin;

    struct Issue {
        uint256 id;
        address creator;
        address solver;
        string title;
        string description;
        string hash; //TODO what is role of hash here?
        uint256 reward;
        ISSUE_STATUS status;
    }

    enum ISSUE_STATUS {
        POSTED,
        SOLVED,
        CANCELLED
    }

    struct Hunter {
        string name;
        bool isRegistered;
        //can add hunter points/rating later
    }

    struct Company {
        string name;
        string nftMetadata;
        bool isRegistered;
    }

    mapping(uint256 => Issue) public issues;
    uint256 public issueCount;

    mapping(address => Hunter) hunters;
    mapping(address => Company) companies;

    Issue[] issueList;

    constructor() {
        admin = msg.sender;
        issueCount = 0;
    }

    modifier onlyNewHunter() {
        require(
            hunters[msg.sender].isRegistered != true,
            "Hunter address already registered"
        );
        require(
            companies[msg.sender].isRegistered != true,
            "This address is registered as a company"
        );
        _;
    }

    modifier onlyRegisteredHunter() {
        require(
            hunters[msg.sender].isRegistered == true,
            "Hunter is not registered yet"
        );
        _;
    }

    modifier onlyRegisteredCompany() {
        require(
            companies[msg.sender].isRegistered == true,
            "Company is not registered yet"
        );
        _;
    }

    modifier onlyNewCompany() {
        require(
            companies[msg.sender].isRegistered != true,
            "Company address already registered"
        );
        require(
            hunters[msg.sender].isRegistered != true,
            "This account is registered as a hunter"
        );
        _;
    }

    fallback() external payable {}

   receive() external payable {
    }

    function registerHunter(string memory _name) public onlyNewHunter {
        hunters[msg.sender] = Hunter(_name, true);
    }

    function registerCompany(string memory _name, string memory _nftMetadata)
        public
        onlyNewCompany
    {
        companies[msg.sender] = Company(_name, _nftMetadata, true);
    }

    function postIssue(
        string memory title,
        string memory description,
        string memory hash,
        uint256 reward //in wei
    ) public payable onlyRegisteredCompany returns (Issue memory) {
        require(msg.value >= reward, "Insufficient funds ");

        Issue memory newIssue = Issue(
            issueCount,
            msg.sender,
            address(0),
            title,
            description,
            hash,
            reward,
            ISSUE_STATUS.POSTED
        );
        issues[issueCount] = newIssue;
        issueList.push(newIssue);
        issueCount++;
        return newIssue;
    }

    function getAllUnsolvedIssues()
        public
        view
        onlyRegisteredHunter
        returns (Issue[] memory)
    {
        return issueList;
    }

    //TODO how shall payment be done ?  either by directly sending hunter address or getting solver addess from issue struct

    function payHunter(address payable _hunterAddress, uint256 _issueId)
        external
        payable
    {
        //TODO how to check if contract has enpugh funds or not

        (bool success, ) = _hunterAddress.call{value: issues[_issueId].reward}(
            ""
        );
        require(success, "failed transacction");
    }
}
