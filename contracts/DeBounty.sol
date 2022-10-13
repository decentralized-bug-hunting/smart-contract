// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract DeBounty {
    address public admin;

    constructor() {
        admin = msg.sender;
    }

    struct Issue {
        uint256 id;
        address creator;
        address solver;
        string title;
        string description;
        string hash;
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
    }

    struct Company {
        string name;
        string nftMetadata;
        bool isRegistered;
    }

    mapping(uint256 => Issue) public issues;

    mapping(address => Hunter) hunters;
    mapping(address => Company) companies;

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

    function registerHunter(string memory _name) public onlyNewHunter {
        hunters[msg.sender] = Hunter(_name, true);
    }

    function registerCompany(string memory _name, string memory _nftMetadata)
        public
        onlyNewCompany
    {
        companies[msg.sender] = Company(_name, _nftMetadata, true);
    }
}
