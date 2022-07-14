import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { ethers, network } from "hardhat";
import { BigNumber } from "ethers";

import {
  DTT,
  DTTPresale,
  DTTPresale__factory,
  DTT__factory,
} from "../typechain";

async function main(): Promise<void> {
  let admin: SignerWithAddress;
  let dtt: DTT;
  let dttPresale: DTTPresale;
  let total_count = 10000;

  [admin] = await ethers.getSigners();
  dtt = await new DTT__factory(admin).deploy("DTT Token", "DTT", admin.address);
  console.log("------dtt address = ", dtt.address);

  dttPresale = await new DTTPresale__factory(admin).deploy(
    dtt.address,
    admin.address
  );
  console.log("------dttPresale address = ", dttPresale.address);

  let mint = await dtt.mint(BigNumber.from(10).pow(18).mul(total_count));
  await mint.wait();
  console.log("---------- totalSupply = " + (await dtt.totalSupply()));

  let deposit_count = 10000;
  let dtt_approve = await dtt.approve(
    dttPresale.address,
    BigNumber.from(10).pow(18).mul(deposit_count)
  );
  await dtt_approve.wait();

  let presale = await dttPresale.deposit(
    BigNumber.from(10).pow(18).mul(deposit_count)
  );
  await presale.wait();
  console.log(
    "---------- Avaiable Total Token 1 = ",
    await dttPresale.availableTokenForPresale()
  );

  let buy_count = 1;
  // price is 0.01 ether
  console.log("---------- Trying to buy " + buy_count + " tokens");
  let buyDttToken = await dttPresale.buyDttToken({
    value: BigNumber.from(10).pow(16).mul(buy_count),
  });
  await buyDttToken.wait();

  // My token balance
  let tokenBalance = await dttPresale.tokenBalance(admin.address);
  let tokenCount = BigNumber.from(tokenBalance)
    .div(BigNumber.from(10).pow(18))
    .toString();
  console.log("---------- My Token count = ", tokenCount);

  // Withdraw DTT token with count
  let withdraw_count = 1;
  let withdrawDttTOken = await dttPresale.withdrawDttToken(
    BigNumber.from(10).pow(18).mul(withdraw_count)
  );
  await withdrawDttTOken.wait();

  let leftTokenBalance = await dttPresale.tokenBalance(admin.address);
  let leftTokenCount = BigNumber.from(leftTokenBalance)
    .div(BigNumber.from(10).pow(18))
    .toString();
  console.log("---------- Left my Token count = ", leftTokenCount);

  console.log(
    "---------- Avaiable Total Token after widthdraw = ",
    await dttPresale.availableTokenForPresale()
  );

  //Set Presale duration
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
  console.log("---------- Token Price = ", await dttPresale.TokenCountPerEth());
  await dttPresale.setTokenCountPerEth(BigNumber.from(10).pow(18).mul(100)); // 100x per 1 ether
  console.log(
    "---------- Token Price after changing = ",
    await dttPresale.TokenCountPerEth()
  );

  // Set Fund List
  let addressList = [
    "0xe2dbdA1BFD82852D8c15129A4A94847e1b2b373A",
    "0xbF6ec2cB7a8e736Cf6ca99632A19B6C28CDfF56e",
    "0xd5038A160Ae7b603C663c4071bb3759ee91D1cCc",
  ];
  let percentList = [15, 35, 50];
  let setFundList = await dttPresale.setFundList(addressList, percentList);
  await setFundList.wait();

  // Withdraw BNB
  console.log("--- Presale balance---", await dttPresale.balanceOf());
  let withdrawETH = await dttPresale.withdrawETH();
  await withdrawETH.wait();
  console.log("---------BNB withdrawn------");
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
