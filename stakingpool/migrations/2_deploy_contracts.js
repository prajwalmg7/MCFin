const Stakingpool = artifacts.require("Stakingpool");
const MCHToken =artifacts.require("MCHToken");
const MCFToken = artifacts.require("MCFToken");

const { deployProxy } = require('@openzeppelin/truffle-upgrades');


module.exports = async function (deployer) {
  
  await deployer.deploy(MCHToken);
  const mch = await MCHToken.deployed();
  
  await deployer.deploy(MCFToken);
  const mcf= await MCFToken.deployed();
  
  await deployProxy(Stakingpool,mch.address,mcf.address,{ deployer, initializer: 'Initialize' });

}