const Stakingpool = artifacts.require("Stakingpool");
const MCHToken =artifacts.require("MCHToken");
const MCFToken = artifacts.require("MCFToken");

module.exports = async function (deployer) {
  
  await deployer.deploy(MCHToken);
  const mch = await MCHToken.deployed();
  
  await deployer.deploy(MCFToken);
  const mcf= await MCFToken.deployed();
  
  await deployer.deploy(Stakingpool,mch.address,mcf.address);
  const stakepool = await Stakingpool.deployed();
}