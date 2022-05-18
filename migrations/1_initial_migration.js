const NFT = artifacts.require("NFT");
const SampleToken = artifacts.require("SampleToken");

module.exports = function (deployer) {
  deployer.deploy(NFT, "MyNFT", "NFT");
  deployer.deploy(SampleToken);
};
