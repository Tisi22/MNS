const main = async () => {
    const PNSRegistryFactory = await hre.ethers.getContractFactory('PNSRegistry');
    const PNSRegistry = await PNSRegistryFactory.deploy();
    await PNSRegistry.deployed();
    console.log("Contract deployed to:", PNSRegistry.address);
  };
  
  const runMain = async () => {
    try {
      await main();
      process.exit(0);
    } catch (error) {
      console.log(error);
      process.exit(1);
    }
  };
  
  runMain();