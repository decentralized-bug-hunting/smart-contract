// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// Import openzeppelin contract for NFT
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

// DeBounty contract inherits ERC721 from openzeppelin
contract DeBounty is ERC721URIStorage {
    // admin is the one who deploys contract
    address public admin;

    // Structure definition for Issue
    struct Issue {
        // Unique issue specification
        uint256 id;
        address creator;
        address solver;
        uint256 solutionID;
        // Issue Details
        string title;
        string description;
        string issueHash;
        uint256 reward;
        ISSUE_STATUS status;
    }

    // Structure definition for solution proposed
    struct ProposedSolution {
        // Unique solution specification
        uint256 id;
        uint256 issueID;
        address issueCreator;
        address proposer;
        // Solution Details
        string solutionDescription;
        PROPOSED_SOLUTION_STATUS status;
    }

    // Issue can be in one of the following state
    enum ISSUE_STATUS {
        POSTED,
        SOLVED,
        CANCELLED
    }

    // Solution proposed can be in one of the following state
    enum PROPOSED_SOLUTION_STATUS {
        PROPOSED,
        ACCEPTED,
        REJECTED
    }

    // Structure definition for Hunter
    struct Hunter {
        string name;
        bool isRegistered;
    }

    // Structure definition for Company
    struct Company {
        string name;
        // Image and description for NFTs
        string nftMetadata;
        bool isRegistered;
    }

    // mapping Issue ID with Issue
    mapping(uint256 => Issue) public issues;

    // mapping Solutions with Issue ID
    mapping(uint256 => ProposedSolution[]) proposedSolutions;

    // mapping hunters address with their solutions proposed
    mapping(address => ProposedSolution[]) myProposedSolutions;

    // Main identifiers for issues, solutions and tokens
    uint256 public issueCount;
    uint256 proposedSolutionCount;
    uint256 tokenCount;

    // mapping addresses with respective hunters and companies
    mapping(address => Hunter) hunters;
    mapping(address => Company) companies;

    // NFT contract and state varibales initialized in constructor
    constructor() ERC721("Bounty NFT", "NFT-BT") {
        admin = msg.sender;
        issueCount = 0;
        proposedSolutionCount = 0;
        tokenCount = 0;
    }

    // mint a NFT to the hunter address using metadata of the company whose issue is solved
    function makeAnNFT(address _address, string memory _metadata) internal {
        // openzeppelin functions for minting
        _safeMint(_address, tokenCount);
        _setTokenURI(tokenCount, _metadata);

        // tokenCount is used as an unique identifier for each NFT
        tokenCount++;
    }

    // some modifiers needed for proper authorization
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

    // These functions execute if none of other functions match
    fallback() external payable {}

    receive() external payable {}

    // New Hunters can register their name and wallet address
    function registerHunter(string memory _name) public onlyNewHunter {
        hunters[msg.sender] = Hunter(_name, true);
    }

    // New Companies can register their name, NFT metadata and wallet address
    function registerCompany(string memory _name, string memory _nftMetadata)
        public
        onlyNewCompany
    {
        companies[msg.sender] = Company(_name, _nftMetadata, true);
    }

    // Functions to retrive own details by hunter or company
    function getCompany() public view returns (Company memory company) {
        return companies[msg.sender];
    }

    function getHunter() public view returns (Hunter memory hunter) {
        return hunters[msg.sender];
    }

    // Check if the hunter or company is registered to the platform using their wallet
    function isHunterValid() public view returns (bool) {
        if (hunters[msg.sender].isRegistered == true) {
            return true;
        } else {
            return false;
        }
    }

    function isCompanyValid() public view returns (bool) {
        if (companies[msg.sender].isRegistered == true) {
            return true;
        } else {
            return false;
        }
    }

    // Issues can be posted by company which contains title, description, issueHash and reward
    // Reward amount of ether  is sent to smart contract
    function postIssue(
        string memory title,
        string memory description,
        string memory issueHash,
        uint256 reward //in wei
    ) public payable onlyRegisteredCompany {
        require(msg.value >= reward, "Insufficient funds ");

        Issue memory newIssue = Issue(
            issueCount,
            msg.sender,
            address(0),
            0,
            title,
            description,
            issueHash,
            reward,
            ISSUE_STATUS.POSTED
        );
        issues[issueCount] = newIssue;
        issueCount++;
    }

    // Reward amount is sent to the hunter from the contract after the solution proposed is accepted
    function payHunter(address payable _hunterAddress, uint256 _issueId)
        public
        payable
    {
        require(
            address(this).balance > issues[_issueId].reward,
            "Not enough funds"
        );

        (bool success, ) = _hunterAddress.call{value: issues[_issueId].reward}(
            ""
        );
        require(success, "failed transaction");
    }

    // Hunters can post their solution to the isse
    // description of the solution can be posted
    function postSolutionProposal(
        uint256 _issueID,
        string memory _solutionDescription
    ) public onlyRegisteredHunter {
        require(
            issues[_issueID].status == ISSUE_STATUS.POSTED,
            "Can't post this solution proposal"
        );

        ProposedSolution[] storage proposed_solutions = proposedSolutions[
            _issueID
        ];

        ProposedSolution memory proSolution = ProposedSolution(
            proposedSolutionCount,
            _issueID,
            issues[_issueID].creator,
            msg.sender,
            _solutionDescription,
            PROPOSED_SOLUTION_STATUS.PROPOSED
        );

        proposed_solutions.push(proSolution);

        ProposedSolution[] storage mySolutions = myProposedSolutions[
            msg.sender
        ];
        mySolutions.push(proSolution);

        proposedSolutionCount++;
    }

    // Issue poster/company can view all the proposed solutions for given issue id
    function getAllProposedSolution(uint256 _issueID)
        public
        view
        onlyRegisteredCompany
        returns (ProposedSolution[] memory)
    {
        require(
            issues[_issueID].creator == msg.sender,
            "You have no access to view proposed solutions"
        );
        return proposedSolutions[_issueID];
    }

    // hunters can get their proposed solutions
    function getMyProposedSolutions()
        public
        view
        onlyRegisteredHunter
        returns (ProposedSolution[] memory)
    {
        return myProposedSolutions[msg.sender];
    }

    //company can accept any of proposed soln and finally pay hunters and mint NFT
    function acceptProposedSolution(uint256 _proposedSolnID, uint256 _issueID)
        external
        onlyRegisteredCompany
    {
        address _companyAddress = proposedSolutions[_issueID][_proposedSolnID]
            .issueCreator;
        require(_companyAddress == msg.sender, "Not authorized to accept");
        address _hunterAddress = proposedSolutions[_issueID][_proposedSolnID]
            .proposer;
        issues[_issueID].status = ISSUE_STATUS.SOLVED;
        issues[_issueID].solver = _hunterAddress;
        proposedSolutions[_issueID][_proposedSolnID]
            .status = PROPOSED_SOLUTION_STATUS.ACCEPTED;
        payHunter(payable(_hunterAddress), _issueID);
        makeAnNFT(_hunterAddress, companies[_companyAddress].nftMetadata);
    }
}
