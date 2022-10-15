const { expect } = require("chai");
const { ethers } = require("hardhat");
const { Contract } = require("ethers");

const ABI = require("../artifacts/contracts/DeBounty.sol/DeBounty.json"); // Contract ABI

const provider = ethers.getDefaultProvider();

// const inter = new ethers.utils.Interface(ABI);

// import { Contract } from "ethers";

// const kycContract = new ethers.Contract(contractAddress, contractABI, signer);

describe("Bounty Contract", function () {
  let deBounty;

  this.beforeAll(async () => {
    const DeBounty = await ethers.getContractFactory("DeBounty");
    deBounty = await DeBounty.deploy();
    // console.log("DEPLOY", deBounty);
    await deBounty.deployed();
  });

  it("Test company registration", async function () {
    const [owner, addrCompany, addrHunter] = await ethers.getSigners();

    const companyName = "APPLE";
    const companyNftMetadata = "Test metadaa";
    const regCompany = await deBounty
      .connect(addrCompany)
      .registerCompany(companyName, companyNftMetadata);
    await regCompany.wait();
    const company = await deBounty.connect(addrCompany).getCompany();
    expect(company.name).to.equal(companyName);
    expect(company.nftMetadata).to.equal(companyNftMetadata);
    expect(company.isRegistered).to.equal(true);
  });

  it("Test hunter registration", async function () {
    const [owner, addrCompany, addrHunter] = await ethers.getSigners();
    const hunterName = "Mr Robot";
    const regHunter = await deBounty
      .connect(addrHunter)
      .registerHunter(hunterName);
    await regHunter.wait();
    const hunter = await deBounty.connect(addrHunter).getHunter();
    expect(hunter.name).to.equal(hunterName);
  });

  it("Test Posted issue", async function () {
    const [owner, addrCompany, addrHunter] = await ethers.getSigners();
    const rewardAmount = 50; //
    const transaction = {
      value: rewardAmount,
    };
    const postIssue1 = await deBounty
      .connect(addrCompany)
      .postIssue(
        "BUG in UI",
        "Button not properly working",
        "Test hash",
        50,
        transaction
      );

    const postIssue2 = await deBounty
      .connect(addrCompany)
      .postIssue(
        "Network bug",
        "Unable to connect to server ",
        "Test hash",
        50,
        transaction
      );

    const issueList = await deBounty.connect(addrHunter).getAllUnsolvedIssues();
    expect(issueList.length).to.equal(2);
  });
});

//TODO testing is working only on view functions only not on other
