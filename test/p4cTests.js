const { expect } = require("chai");


// should have minted 4.000.000.000.000 after creation

describe("P4C", function () {
  it("Should return the owner's tokens minted after creationDeployment should assign the total supply of tokens to the owner", async function () {
      
      const [owner] = await ethers.getSigners();

      const Token = await ethers.getContractFactory("P4C");
  
      const p4cToken = await Token.deploy();
  
      const ownerBalance = await p4cToken.balanceOf(owner.address);
      expect(await p4cToken.totalSupply()).to.equal(ownerBalance);
    
    });
});
    

//   it("Should return the new greeting once it's changed", async function () {
//     const Greeter = await ethers.getContractFactory("Greeter");
//     const greeter = await Greeter.deploy("Hello, world!");
//     await greeter.deployed();

//     expect(await greeter.greet()).to.equal("Hello, world!");

//     const setGreetingTx = await greeter.setGreeting("Hola, mundo!");

//     // wait until the transaction is mined
//     await setGreetingTx.wait();

//     expect(await greeter.greet()).to.equal("Hola, mundo!");
//   });
// });
