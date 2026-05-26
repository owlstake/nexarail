# NexaRail Legal Review Package

**Document:** docs/legal/LEGAL_REVIEW_PACKAGE.md
**Version:** 1.0-draft
**Date:** 2026-05-25
**Status:** Draft preparation document — does NOT contain legal conclusions. Requires review by qualified legal counsel in relevant jurisdictions.

## Project Summary

NexaRail Network is a sovereign Layer 1 blockchain built with Cosmos SDK and CometBFT. It is designed for payment settlement between payers and registered merchants, with protocol fee routing to treasury, burn, and (future) validators.

**Current state:** Testnet preparation. No public mainnet. No token sale. No monetary value attributed to testnet tokens.

## NXRL Token Utility

The NXRL token (denom: `unxrl`) is the native staking and fee token of the NexaRail Network. Proposed utility:
- Gas fees for transactions
- Staking for network security
- Protocol fee denomination for settlement fees
- Governance voting power

NXRL has **no monetary value** in the current testnet state. There is **no public sale**, **no ICO/IEO/IDO**, and **no market** for NXRL.

## Key Facts for Counsel

| Assertion | Status |
|---|---|
| Public mainnet is live | ❌ No |
| Token sale has occurred | ❌ No |
| NXRL has monetary value | ❌ No (testnet only) |
| Investment returns are promised | ❌ No |
| Stablecoin module exists | ❌ No |
| Bridge module exists | ❌ No |
| Validator distribution is active | ❌ No (deferred) |
| Burn mechanism is active | ❌ No (disabled by default) |
| Testnet tokens are transferable to mainnet | ❌ No (testnet resets wipe state) |
| Any entity holds NXRL as an investment | ❌ Not to project's knowledge |

## Jurisdictions Requiring Review

| Jurisdiction | Key Framework | Concern |
|---|---|---|
| United Kingdom | FCA cryptoasset regulations, Financial Promotions Order | Token classification, financial promotion rules |
| European Union | MiCA (Markets in Crypto-Assets Regulation) | Token classification under MiCA, CASP requirements |
| United States | SEC (Howey test), FinCEN (MSB regulations), CFTC | Securities classification, money transmission |
| Switzerland | FINMA | Token classification, banking law |
| Singapore | MAS (Payment Services Act) | Digital payment token regulation |

## UK FCA Considerations

*This section identifies areas for legal review. It does not state conclusions.*

- **Token classification:** Is NXRL an exchange token, utility token, or security token under FCA guidance?
- **Financial promotion:** Do testnet announcements constitute financial promotion under the Financial Promotions Order?
- **MLR registration:** Is a testnet operator required to register with the FCA under the Money Laundering Regulations?
- **Staking:** Does staking constitute a collective investment scheme or regulated activity?

## EU MiCA Considerations

- **Token classification:** Is NXRL an asset-referenced token (ART), electronic money token (EMT), or other under MiCA?
- **CASP licensing:** Does operating validators or RPC endpoints constitute a crypto-asset service?
- **White paper:** Does a testnet require a MiCA-compliant white paper before any public offering?

## US Considerations

- **Howey test:** Is NXRL an investment contract? Factors: no investment of money (testnet has no value), no common enterprise, no expectation of profits from efforts of others.
- **Money transmission:** Does operating a validator constitute money transmission under FinCEN guidance?
- **Commodity classification:** Could NXRL be classified as a commodity under CFTC jurisdiction?

## Stablecoin / Bridge Not Live

The project has NOT implemented:
- Stablecoin registry module
- Fiat-backed or algorithmic stablecoin
- Cross-chain bridge (IBC or custom)
- Any mechanism to represent off-chain assets on-chain

These are explicitly deferred and have no implementation timeline. This simplifies regulatory analysis in early phases.

## Testnet Disclaimer (Draft — requires counsel review)

> The NexaRail testnet is a technical testing environment. Testnet tokens have no monetary value and cannot be exchanged for any other asset. Participation in the testnet does not constitute an investment, does not entitle participants to any mainnet allocation, and is not an offer of any financial product. The testnet may be reset, modified, or terminated at any time without notice. No promises are made regarding the launch, features, or value of any future mainnet.

## No Investment Claims

The project does not:
- Promise returns, profits, or appreciation
- Characterise testnet participation as an investment
- Offer NXRL for sale
- Conduct airdrops as marketing incentives
- Guarantee mainnet launch
- Claim NXRL will have any particular value

## Next Steps for Legal Review

1. Engage qualified legal counsel in primary jurisdictions (UK, EU, US)
2. Provide this package + full technical documentation
3. Obtain written legal opinion on:
   - Token classification
   - Financial promotion compliance for testnet communications
   - Any registration or licensing requirements
   - Recommended disclaimers for all public-facing materials
4. Review testnet disclaimer wording
5. Establish ongoing counsel relationship for mainnet preparation
