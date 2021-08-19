const { expect } = require("chai");

// should have minted 4.000.000.000.000 after creation

describe("Token contract 2", function () {

  let Token, token, owner, addr1, addr2;

  beforeEach(async () => {
    Token = await ethers.getContractFactory('P4C');
    token = await Token.deploy();
    [owner,addr1,addr2, addr3, _] = await ethers.getSigners();
  });

  describe('Deployment', () => {
    it('Should set the right owner', async () => {
      expect(await token.owner()).to.equal(owner.address);
    });

    it('Should assign the total supply of tokens to the owner', async () => {
      const ownerBalance = await token.balanceOf(owner.address);
      expect(await token.totalSupply()).to.equal(ownerBalance);
    });
  });

  describe('Transactions', () => {
    it('Should transfer tokens between accounts', async () => {
      await token.transfer(addr1.address, 100);

      await token.connect(addr1).transfer(addr2.address, 100);
      const addr2Balance = await token.balanceOf(addr2.address);      
      expect(addr2Balance).to.equal(97); //100 - 4% fees + 1% RFI

      let addr1Balance = await token.balanceOf(addr1.address);
      expect(addr1Balance).to.equal(0);

    });

    it('Should fail if sender doesn\'t have enough tokens', async () => {
      const initialBalanceOwner = await token.balanceOf(owner.address);

      await expect(token.connect(addr1).transfer(owner.address, 1)).to.be.revertedWith('Insufficient Balance');

      expect(await token.balanceOf(owner.address)).to.equal(initialBalanceOwner);
    });

    it('Should distribute 1% to shareholders', async () => {
      await token.transfer(addr1.address, 1000000);
      let addr1Balance = await token.balanceOf(addr1.address);
      expect(addr1Balance).to.equal(1000000);

      await token.transfer(addr2.address, 100000);
      token.connect(addr2).transfer(addr3.address, 100000);

      addr1Balance = await token.balanceOf(addr1.address);

      console.log(addr1Balance.toString());

      expect(addr1Balance).to.equal(1000000);
      


    });
  });

  // testing uniswap pool creation / liquidity added and fee on swaps



});
