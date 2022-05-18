const NFT = artifacts.require("NFT");
const SampleToken = artifacts.require("SampleToken");
const baseDecimals = 10;

contract('NFT', async accounts => {
    it("Check blind mode", async () => {
        var nftInstance = await NFT.deployed();
        let result = await nftInstance.isBlind.call();
        assert.equal(result, false, "not blind mode.");
    });

    it("Set blind mode", async () => {
        var nftInstance = await NFT.deployed();
        await nftInstance.setBlind();
        let result = await nftInstance.isBlind.call();
        assert.equal(result, true, "unpack fail.");
    });

    it("Check Decimals", async () => {
        var tokenInstance = await SampleToken.deployed();
        var decimals = await tokenInstance.decimals.call();
        assert.equal(decimals, 18, "Fail Decimals");
    });

    it("Set mint price", async () => {
        var nftInstance = await NFT.deployed();
        var tokenInstance = await SampleToken.deployed();
        var decimals = await tokenInstance.decimals.call();
        let price = BigInt(100 * (baseDecimals ** decimals));
        await nftInstance.setMintPrice(tokenInstance.address, price);
        let amount = await nftInstance.getMintPrice(tokenInstance.address);
        assert.equal(amount, price, "set mint price fail.");
    });

    it("Try Mint", async () => {
        var nftInstance = await NFT.deployed();
        var tokenInstance = await SampleToken.deployed();
        var decimals = await tokenInstance.decimals.call();
        let price = BigInt(100 * (baseDecimals ** decimals));
        await tokenInstance.increaseAllowance(nftInstance.address, price);
        await nftInstance.mint(tokenInstance.address);
        let result = await nftInstance.ownerOf(1);
        assert.equal(result, accounts[0], "Mint fail.");
    });

    it("Set nft price", async () => {
        var nftInstance = await NFT.deployed();
        var tokenInstance = await SampleToken.deployed();
        var decimals = await tokenInstance.decimals.call();
        let price = BigInt(100 * (baseDecimals ** decimals));
        await nftInstance.setSalePrice(1, tokenInstance.address, price);
        let amount = await nftInstance.getPrice(1, tokenInstance.address);
        assert.equal(amount, price, "set nft price fail.");
        let approve = await nftInstance.getApproved(1);
        assert.equal(approve, nftInstance.address, "Not approve to contract.");
    });

    it("Buy nft", async () => {
        var nftInstance = await NFT.deployed();
        var tokenInstance = await SampleToken.deployed();
        let amount = await nftInstance.getPrice(1, tokenInstance.address);
        await tokenInstance.transfer(accounts[1], amount);
        let receivedToken = await tokenInstance.balanceOf.call(accounts[1]);
        assert.equal(receivedToken.toString(), amount.toString(), "Not received correct token.");
        await tokenInstance.increaseAllowance(nftInstance.address, amount, { from: accounts[1] });
        await nftInstance.buy(1, tokenInstance.address, { from: accounts[1] });
        let result = await nftInstance.ownerOf(1);
        assert.equal(result, accounts[1], "Buy fail.");
        let approve = await nftInstance.getApproved(1);
        assert.notEqual(approve, nftInstance.address, "Should not have approve.");
    });
});