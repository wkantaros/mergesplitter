# Merge Splitter (working name)

## Description

Merge Splitter is a set of smart contract and interfaces that enable *XXX* [insert arbitrary token for *XXX*] holders to split their token into two exposures by depositing *XXX* into a vault and receiving *XXXPoS* and *XXXPoW* in exchange.

After the merge, *XXXPoS* will only be redeemable for *XXX* on the proof-of-stake chain and *XXXPoW* will only be redeemable for *XXX* on the proof-of-work chain. The *XXXPoS* trigger is trivial to impliment as the proof-of-stake chain will be live when ```block.difficulty > 2 ** 64 || block.difficulty == 0;```. When the previous statement evaluates to ```true``` redemptions of *XXXPoS* for *XXX* are enabled.

The non-trivial part to impliment is for the proof-of-work chain to know that the merge has happened since if you just try to negate the conditions for proof-of-stake redemptions, there would be no way to prevent redemptions before the merge as well. To enable redemptions, an extra assumption that chainid() != 1 was also added. To avoid the difficulty bomb Ethereum proof-of-work supporters will fork before the geth update and change the chainid to prevent replay attacks.

To prevent the loss of funds in the case the merge never occurs, *XXXPoW* will be redeemable for *XXX* after ```MaxBlock``` has been reached. ```MaxBlock``` will be approximately 2 years (period subject to change) after the current expected time for the merge. If this happens, *XXXPoW* will trade similarly to a zero-coupon bond whose expiry is ```MaxBlock``` (This is similar to the [Element Finance](https://docs.element.fi/) mechanism and other fixed-rate DeFi protocols).

A user can also redeem *XXX* before the merge occurs by exchanging equal units of *XXXPoS* and *XXXPoW* for *XXX*.
