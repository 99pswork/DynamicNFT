const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("NFT", function () {
	before(async () => {
		const NFT = await ethers.getContractFactory("TheDynamicNFT");
		nft = await NFT.deploy(
			"Tiger",
			"TIGER",
			);
		await nft.deployed();

		accounts = await ethers.getSigners();
	});

	it("Should check for contract's ownership!", async function () {
		expect(await nft.owner()).to.equal(accounts[0].address);
	});

	it("Check Base URI Before Reveal", async function () {
		await expect(nft.tokenURI(0)).to.be.revertedWith(
			"TLS URI For Token Non-existent"
		);
	});

	it("Check Status Paused", async function () {
		expect(await nft.paused()).to.equal(true);
		await nft.togglePauseState();
		expect(await nft.paused()).to.equal(false);
		await nft.togglePauseState();
	});

	it("Check Pre Sale State", async function () {
		expect(await nft.preSaleActive()).to.equal(true);
		await nft.togglePreSale();
	});

	it("Check Public Sale State", async function () {
		expect(await nft.publicSaleActive()).to.equal(false);
		await nft.togglePublicSale();
		expect(await nft.publicSaleActive()).to.equal(true);
		await nft.togglePublicSale();
	});

	it("Check Pre Sale Mint", async function () {
		await expect(
			nft
				.connect(accounts[1])
				.preSaleMint(1, { value: ethers.utils.parseEther("0.15") })
		).to.be.revertedWith("TLS Pre Sale is not Active");

		await nft.togglePreSale();
		await expect(nft.connect(accounts[1])
		.preSaleMint(1, { value: ethers.utils.parseEther("0.15") }))
		.to.be.revertedWith("TLS User is not White/OG Listed");

		await nft.addWhiteListedAddresses([accounts[1].address]);

		await expect(nft.connect(accounts[1])
		.preSaleMint(1, { value: ethers.utils.parseEther("0.15") }))
		.to.be.revertedWith("TLS Minting is Paused");
		
		await nft.togglePauseState();

		await nft
			.connect(accounts[1])
			.preSaleMint(1, { value: ethers.utils.parseEther("0.15") });

		await nft.addOgListedAddresses([accounts[2].address]);

		await expect(
			nft
				.connect(accounts[2])
				.preSaleMint(1, { value: ethers.utils.parseEther("0.10") })
		).to.be.revertedWith("TLS ETH Value Sent for Pre Sale is not enough");

		await nft
			.connect(accounts[2])
			.preSaleMint(1, { value: ethers.utils.parseEther("0.25") });
	});

	it("Check Public Sale Mint", async function () {
		await expect(
			nft
				.connect(accounts[1])
				.publicSaleMint(1, { value: ethers.utils.parseEther("0.15") })
		).to.be.revertedWith("TLS Public Sale is not Active");
		await nft.togglePublicSale();

		await nft
			.connect(accounts[1])
			.publicSaleMint(1, { value: ethers.utils.parseEther("0.2") });
		await nft
			.connect(accounts[5])
			.publicSaleMint(1, { value: ethers.utils.parseEther("0.2") });
		expect(await nft.balanceOf(accounts[5].address)).to.equal(1);
		await nft
			.connect(accounts[5])
			.publicSaleMint(4, { value: ethers.utils.parseEther("0.8") });
		expect(await nft.totalSupply()).to.equal(8);

		expect(await nft.tokenURI(1)).to.equal("");

		await nft.setNotRevealedURI("test.png");

		expect(await nft.tokenURI(1)).to.equal("test.png");
		expect(await nft.tokenURI(await nft.totalSupply())).to.equal("test.png");
	});

	it("Check Air Drop Functionality", async function () {
		await nft.airDrop([accounts[2].address, accounts[3].address]);

		balanceAcc1 = await nft.balanceOf(accounts[2].address);
		await nft.airDrop([accounts[2].address, accounts[2].address]);

		await expect(nft.airDrop([accounts[4].address])).to.be.revertedWith(
			"TLS Maximum Supply Reached"
		);
		await expect(
			nft
				.connect(accounts[8])
				.publicSaleMint(1, { value: ethers.utils.parseEther("0.2") })
		).to.be.revertedWith("TLS Maximum Supply Reached");

		expect(await nft.balanceOf(accounts[2].address)).to.equal(
			parseInt(balanceAcc1) + 2
		);
	});

	it("Check Random Number Generator", async function () {
		randNumber = await nft.raffleNumberGenerator(8888);
		expect(parseInt(randNumber)).to.be.lessThan(8889);
		randNumber2 = await nft.raffleNumberGenerator(20);
		expect(parseInt(randNumber2)).to.be.lessThan(21);
		randNumber3 = await nft.raffleNumberGenerator(200);
		expect(parseInt(randNumber3)).to.be.lessThan(201);
	});

	it("Withdraw money to owner Account", async function () {
		bal1 = await web3.eth.getBalance(accounts[0].address);
		await expect(nft.connect(accounts[1]).withdrawTotal()).to.be.revertedWith(
			"Ownable: caller is not the owner"
		);

		await nft.withdrawTotal();

		contractBal = await web3.eth.getBalance(nft.address);
		expect(contractBal).to.equal(ethers.utils.parseEther("0.0"));
	});
});
