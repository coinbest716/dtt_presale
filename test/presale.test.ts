import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { ethers, network } from "hardhat";
import { BigNumber } from "ethers";

import {
  DTTPresale,
  DTTPresale__factory,
  DTT,
  DTT__factory,
} from "../typechain";
import { Network } from "hardhat/types";

describe("Check deployment", async () => {
  let admin: SignerWithAddress;
  let dtt: DTT;
  let dttPresale: DTTPresale;
  let total_count = 10000;

  before(async () => {
    [admin] = await ethers.getSigners();
    dtt = await new DTT__factory(admin).deploy(
      "DTT Token",
      "DTT",
      admin.address
    );
    dttPresale = await new DTTPresale__factory(admin).deploy(
      dtt.address,
      admin.address
    );

    await dtt.mint(BigNumber.from(10).pow(18).mul(total_count));
    console.log("---------- totalSupply = " + (await dtt.totalSupply()));
  });

  it("check single mint", async () => {
    let deposit_count = 10;
    await dtt.approve(
      dttPresale.address,
      BigNumber.from(10).pow(18).mul(deposit_count)
    );
    await dttPresale.deposit(BigNumber.from(10).pow(18).mul(deposit_count));
    console.log(
      "---------- Avaiable Total Token 1 = ",
      await dttPresale.availableTokenForPresale()
    );

    let buy_count = 5;
    // price is 0.01 ether
    console.log("---------- Trying to buy " + buy_count + " tokens");
    await dttPresale.buyDttToken(buy_count, {
      value: BigNumber.from(10).pow(16).mul(buy_count),
    });

    // My token balance
    let tokenBalance = await dttPresale.tokenBalance(admin.address);
    let tokenCount = BigNumber.from(tokenBalance)
      .div(BigNumber.from(10).pow(18))
      .toString();
    console.log("---------- My Token count = ", tokenCount);

    // 90 days passed virtually in hardhat testnet
    await mineBlockandSetTimeStamp(network, 90 * 24 * 3600 + 100);

    // Withdraw DTT token with count
    let withdraw_count = 1;
    await dttPresale.withdrawDttToken(
      BigNumber.from(10).pow(18).mul(withdraw_count)
    );

    let leftTokenBalance = await dttPresale.tokenBalance(admin.address);
    let leftTokenCount = BigNumber.from(leftTokenBalance)
      .div(BigNumber.from(10).pow(18))
      .toString();
    console.log("---------- Left my Token count = ", leftTokenCount);

    console.log(
      "---------- Avaiable Total Token after widthdraw = ",
      await dttPresale.availableTokenForPresale()
    );

    // Set Presale duration
    console.log(
      "---------- Presale Duration = ",
      await dttPresale.presalePeriod()
    );
    await dttPresale.setPresalePeriod(30); //30days
    console.log(
      "---------- Presale Duration after changing = ",
      await dttPresale.presalePeriod()
    );

    // Set Token Price
    console.log(
      "---------- Token Price = ",
      await dttPresale.BNB20TokenPrice()
    );
    await dttPresale.setPrice(BigNumber.from(10).pow(16).mul(2)); // 0.02 ether
    console.log(
      "---------- Token Price after changing = ",
      await dttPresale.BNB20TokenPrice()
    );

    // Set Fund List
    let addressList = [
      "0xe2dbdA1BFD82852D8c15129A4A94847e1b2b373A",
      "0xbF6ec2cB7a8e736Cf6ca99632A19B6C28CDfF56e",
      "0xd5038A160Ae7b603C663c4071bb3759ee91D1cCc",
    ];
    let percentList = [15, 35, 50];
    await dttPresale.setFundList(addressList, percentList);

    // Withdraw BNB
    console.log("--- Presale balance---", await dttPresale.balanceOf());
    await dttPresale.withdrawETH();
    console.log("---------BNB withdrawn------");
  });

  async function mineBlockandSetTimeStamp(
    _network: Network,
    addTimeStamps: number
  ): Promise<void> {
    const blockNumAfter = await ethers.provider.getBlockNumber();
    const blockAfter = await ethers.provider.getBlock(blockNumAfter);
    const timestampAfter = blockAfter.timestamp;

    await _network.provider.send("evm_setNextBlockTimestamp", [
      timestampAfter + addTimeStamps,
    ]);
    await _network.provider.send("evm_mine");
    return;
  }
});
