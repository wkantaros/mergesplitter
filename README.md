# Merge Splitter (working name)

## Description

Merge Splitter is a set of smart contract and interfaces that enable ETH holders to split their token into two exposures by depositing ETH into a vault and receiving *ETHPoS* and *ETHPoW* in exchange. 
After the merge, *ETHPoS* will only be redeemable for ETH on the proof-of-stake chain and *ETHPoW* will only be redeemable for ETH on the proof-of-work chain. The *ETHPoS* trigger is trivial to impliment as the proof-of-stake chain will be live when ```block.difficulty > 2 ** 64 || block.difficulty == 0;```. When the previous statement evaluates to ```true``` redemptions of *ETHPoS* for ETH are enabled. 
The non-trivial part to impliment is for the proof-of-work chain to know that the merge has happened since if you just try to negate the conditions for proof-of-stake redemptions, there would be no way to prevent redemptions before the merge as well. In response, we have devised a 2/3 oracle vote instead. For proof-of-work redemptions to be allowed 2 of these 3 trigger events must occur:
1. *Chainlink oracle call throws an error or stalls*. Since Chainlink has committed to only honoring the PoS chain, making a call to the Chainlink on the PoW chain will not work smoothly.
2. *The price of ETH-stETH is greater than 3* (number subject to change). Since stETH on the PoW chain will be valueless post merge and ETH won't, we posit this is a reliable measure that the merge has happened.
3. TBD

To prevent the loss of funds in the case the merge never occurs, *ETHPoW* will be redeemable for ETH after ```MaxBlock``` has been reached. ```MaxBlock``` will be approximately 2 years (period subject to change) after the current expected time for the merge. If this happens, *ETHPoW* will trade similarly to a zero-coupon bond whose expiry is ```MaxBlock``` (This is similar to the [Element Finance](https://docs.element.fi/) mechanism and other fixed-rate DeFi protocols).

A user can also redeem ETH before the merge occurs by exchanging equal units of *ETHPoS* and *ETHPoW* for ETH.
