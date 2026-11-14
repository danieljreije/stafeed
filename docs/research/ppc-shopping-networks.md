# Pay-per-click shopping networks as Ad sources

- Date: 2026-11-14 (all sources accessed on this date unless noted)
- Ticket: #26
- Author: research agent (read-only; no sign-ups, no forms)

## Question

Can Stafeed add pay-per-click (PPC) shopping or price-comparison networks as extra automatic Ad sources? Each would be an adapter in a Supabase Edge Function. It must search Products with Offers by Destination Country, category and free text, fetch one Product fresh, and return a click link for the Merchant Handoff. Which networks accept a mobile app, cover the US, UK, UAE and Lebanon, and allow a feed made only of Ads?

## Recommendation

1. **Pursue Kelkoo Group first, for the US and UK.** It is a live CPC network with a real offer search API. The API takes free text, category filters and price filters, and returns price, currency, availability, image, Merchant and a click link (`goUrl`). It lists both the US and UK as markets. Its rules fit a server-side adapter: a JWT token from the Publisher Center, used only on the server. The catch: Kelkoo says not to cache live-search `goUrl`s, and clicks must open in a visible browser on the Shopper's device. Mobile-app traffic is not mentioned anywhere in the docs, so ask before building.
2. **Apply to Connexity (Taboola) second, US only at first.** Its terms name apps as eligible and it pays CPC, with a $25 minimum payment. But the public terms are from 2013. They require a refresh at least every 6 hours, a linked credit to Connexity on every page, and at least three Offers per Product in comparison views. The API docs are behind a help centre that blocked automated reading. Treat it as a candidate, not a certainty. The UK is a separate Connexity programme.
3. **Keep Sovrn Commerce as an optional third (US/UK).** It accepts apps, pays CPC or CPA per Merchant, and has a server-side Product Recommendation API. But it has no plain keyword search. It is better suited to wrapping links than to being a search source.
4. **UAE and Lebanon: there is a gap.** None of the PPC shopping networks checked lists the UAE or Lebanon. Kelkoo's 27 listed countries include no Middle East country. Connexity's regions are US, UK, FR, DE and IT. The MENA networks (ArabClicks, Admitad, Boostiny) pay on a sale or coupon basis (CPA/CPS), not CPC. No product search API for publishers was found for them. Nothing was found that targets Lebanon at all. For the UAE, plan on Brand Ads and affiliate programmes, not PPC. For Lebanon, expect no automatic Ad source from these networks.

**What the owner must do:**
- Kelkoo: sign up at the Publisher Center as "Publisher" ([Kelkoo for publishers](https://www.kelkoogroup.com/en/for-publishers/)). Before signing up, email the account manager the open questions below (app traffic, `originReferer` for an app, caching, feed made only of Ads). You will need a company or sole-trader identity that can invoice monthly. Kelkoo pays only against your invoice ([Publisher Center](https://docs.kelkoogroup.com/for-publishers/publisher-center.md)). You will also need the app's store URLs, the target countries (US and/or UK) and expected traffic.
- Connexity: register one "Site" (the app) in the US programme ([registration](https://publisher.connexity.com/registration)). You must be 18+ and the registered owner, and most of the traffic must come from the US ([terms](https://publisher.connexity.com/terms)). You need a privacy policy shown in the app store listing. Ask for the current terms, since the online copy is dated 2013.
- Do nothing for UAE/Lebanon PPC until a launch country is chosen.

## Comparison table

| Network | Accepts apps | US | UK | UAE | Lebanon | Payout | API / feed |
|---|---|---|---|---|---|---|---|
| **Kelkoo Group** | Not confirmed (no app rules; in-app SDK background calls banned) | Yes | Yes | No | No | CPC (Static / Flex); invoice monthly | Search API (JWT), Feeds, Links |
| **Connexity (Taboola)** | Yes ("website, widget or app") | Yes | Separate UK programme | No | No | CPC; $25 minimum; paid 45 days after month end | Catalog API, HTTP data feeds (details not confirmed) |
| **Sovrn Commerce** | Yes, with prior approval | Yes (usd_en market) | Yes (gbp_en market) | Not confirmed | Not confirmed | CPC or CPA per Merchant; $25 minimum; paid 90 days after month end | Product Recommendation, Price Comparison, Bid Check, link APIs |
| ArabClicks | Yes ("such as an app") | No | No | Yes (GCC) | Not confirmed | CPS / CPA | None found |
| Admitad | Not confirmed for product feeds | Global network | Global network | Yes (Dubai HQ, GCC offers) | Not confirmed | CPA / CPS | Not confirmed for publishers |
| Boostiny (ArabyAds) | Not confirmed | No | No | Yes (MENA/GCC) | Not confirmed | Coupon-based CPA | Not confirmed (secondary source mentions an API) |

## Kelkoo Group

**What it is.** A CPC shopping network. It says it runs retail campaigns in 29 markets, with "dynamic CPC pricing" ([Kelkoo for publishers](https://www.kelkoogroup.com/en/for-publishers/)).

**Countries.** The company page lists 27 countries, including the United States and the United Kingdom. It lists no Middle East country, so no UAE and no Lebanon ([About Kelkoo Group](https://www.kelkoogroup.com/en/our-company/)). The page also says "29 markets", so the list and the count do not match. Access to the Publisher Center is per country ([Publisher Center](https://docs.kelkoogroup.com/for-publishers/publisher-center.md)).

**Mobile app eligibility.**
- No published traffic minimum, and no app acceptance rule. The docs do not mention apps ([traffic guidelines](https://docs.kelkoogroup.com/for-publishers/quick-starts/traffic-guidelines.md); [click and lead validity](https://docs.kelkoogroup.com/for-publishers/guides/click-and-lead-validity)). **Not confirmed.**
- The `goUrl` rules ban asynchronous background calls, for example from a mobile SDK. The browser frame must be visible, run JavaScript, accept first-party cookies, and keep an unmodified user agent ([Go URL guide](https://docs.kelkoogroup.com/for-publishers/quick-starts/how-to-handle-go-urls.md)). So the Merchant Handoff must open in a real browser view on the Shopper's device. That means the system browser or an in-app browser tab, not a hidden fetch. Whether an in-app browser tab is accepted is **not confirmed**.
- No iframes. Do not hide the kelkoogroup.net redirect. Send the traffic source in `originReferer` ([traffic guidelines](https://docs.kelkoogroup.com/for-publishers/quick-starts/traffic-guidelines.md)). What an app should put there is **not confirmed**.
- Merchants can forbid traffic types, listed in the Merchant feed's `forbiddenTrafficTypes` field. The example values include social media, price comparison website, native platforms, browser extensions and others. None of them is "mobile app" ([merchants feed](https://docs.kelkoogroup.com/for-publishers/shopping-api-feeds/feeds-merchants.md); [merchant campaigns](https://docs.kelkoogroup.com/for-publishers/guides/understanding-merchant-campaigns)). Stafeed's category is **not confirmed**. It could be read as "price comparison website" or "social media".

**Payout.**
- CPC on valid leads only ([click and lead validity](https://docs.kelkoogroup.com/for-publishers/guides/click-and-lead-validity)).
- Campaign tiers: Static (fixed CPC per category), Flex (CPC set daily from your traffic quality), Flex Premium ([merchant campaigns](https://docs.kelkoogroup.com/for-publishers/guides/understanding-merchant-campaigns)).
- You invoice Kelkoo monthly. The earnings shown are live estimates until the account manager confirms them ([Publisher Center](https://docs.kelkoogroup.com/for-publishers/publisher-center.md)).
- A minimum payment threshold is **not confirmed**.

**API / feed access.**
- Three products: Links, Search, Feeds. Search is for a live search engine without storing offers. Feeds are bulk downloads, "not meant to be retrieved at each end user request" ([which is right for me](https://docs.kelkoogroup.com/for-publishers/quick-starts/feeds-search-or-links-which-is-right-for-me)).
- Search endpoint: `/search/offers`, JWT auth. Parameters include free text `query` (with `matchStrength`), `filterBy=categoryId:…`, price range filters and EAN. Pages hold 1–99 results, with a cap of 500 results per query (can be raised on request) ([offer search request](https://docs.kelkoogroup.com/for-publishers/shopping-api-search/search-offers/offer-search-request)).
- Offer fields include `offerId`, `title`, `price`, `currency`, `availabilityStatus`, image URLs, `goUrl`, `merchantId`/`merchantName`, `brandName`, `categoryId`, `deliveryCost`, a two-letter `country` and `lastUpdateDate` ([offer model](https://docs.kelkoogroup.com/for-publishers/shopping-api-search/search-offers/offer-search-model.md)).
- There is no "ships-to countries" field. Each offer carries one `country` (the market).
- Rate limits: "high", per application. Over the limit returns HTTP 429. No numbers are published ([rate limits](https://docs.kelkoogroup.com/for-publishers/shopping-api-search/search-offers/offer-search-rate-limits.md)).
- Tokens are created in the Publisher Center and called "secret keys" ([Publisher Center](https://docs.kelkoogroup.com/for-publishers/publisher-center.md)). That fits server-side key handling.
- A "link search" endpoint returns monetisation info (estimated CPC) for a given URL ([link search](https://docs.kelkoogroup.com/for-publishers/shopping-api-search/search-link/link-search.md)).

**Terms that matter.**
- Caching: avoid caching `goUrl`s from live search. If you must cache, keep it as short as possible. Do not crawl `goUrl`s to check them. Do not change them, except to add publisher parameters ([Go URL guide](https://docs.kelkoogroup.com/for-publishers/quick-starts/how-to-handle-go-urls.md)).
- Invalid clicks: automated traffic is rejected (DataDome). Repeat clicks on the same offer in a short time count as spam. Non-converting off-geo traffic is rejected ([traffic guidelines](https://docs.kelkoogroup.com/for-publishers/quick-starts/traffic-guidelines.md)). Match the Shopper's location to the campaign country.
- Quality targets: aim for at least 1% sales conversion and steady volumes. A suggested starting volume is 100 leads per Merchant campaign per day, or 1,000 per country ([traffic guidelines](https://docs.kelkoogroup.com/for-publishers/quick-starts/traffic-guidelines.md)). For a pre-launch app this is a guide, not a stated entry minimum.
- Ad labelling: no requirement found. **Not confirmed.**
- A feed made only of Ads: not addressed. **Not confirmed.**

## Connexity (a Taboola company)

**Status.** Taboola completed its purchase of Connexity on 1 September 2021 ([Taboola press release](https://www.taboola.com/press-releases/taboola-closes-connexity-acquisition/)). Connexity's site still runs and says "a Taboola Company". Its region selector shows US, UK, France, Germany and Italy ([connexity.com](https://www.connexity.com/)). PriceGrabber was folded into Connexity in 2015–16 (secondary: [Retail Dive](https://www.retaildive.com/news/shopzilla-parent-connexity-acquires-pricegrabber/400812/)).

**Source caveat.** The publisher help centre (pubresources.connexity.com) returned HTTP 403 to automated reading. Points marked "(search snippet)" come from search-engine summaries of those Connexity pages, not from a full read.

**Mobile app eligibility.**
- A Site can be a "website, widget or app". One Site per application; more Sites go in by email. Approval is at Connexity's discretion ([US terms](https://publisher.connexity.com/terms)).
- You must be 18+ and the registered owner. Apps must post a privacy policy in the app store ([US terms](https://publisher.connexity.com/terms)).
- No traffic minimum is published. You can be terminated if you earn under $25 in 12 months ([US terms](https://publisher.connexity.com/terms)).

**Countries.**
- US programme: most of the Site's traffic must come from the US. Non-US clicks can be discounted ([US terms](https://publisher.connexity.com/terms)).
- UK: a separate Connexity UK Publisher Program with its own Publisher ID (search snippet: [Will I generate earnings from all programs?](https://pubresources.connexity.com/hc/en-us/articles/360017225458-Will-I-generate-earnings-from-all-Connexity-Inc-programs)). The UK terms were **not found**.
- UAE, Lebanon: not listed.

**Payout.** CPC on net revenue from valid clicks, minus an admin fee of up to 5%. Paid in USD, 45 days after month end, with a $25 minimum ([US terms](https://publisher.connexity.com/terms)). No fixed rate is published (search snippet: [commission rate FAQ](https://pubresources.connexity.com/hc/en-us/articles/360017115997-What-is-the-affiliate-commission-rate-I-will-earn-through-the-Connexity-Publisher-Program)).

**API / feed access.**
- The terms cover a Catalog API (capped at about 200,000 calls a day; tell Connexity before growing more than 20%) and HTTP data feeds ([US terms, Schedule 1](https://publisher.connexity.com/terms)).
- The help centre also lists a Merchant Match API (keywords to matching Merchants, then a Catalog API URL for their offers) and a "Publisher Exports" product feed. The feed is reached with Publisher ID and API key as query parameters, in JSON or CSV (search snippet: [API + HTTP Data Feeds](https://pubresources.connexity.com/hc/en-us/sections/360005023258-API-HTTP-Data-Feeds)).
- Exact fields, filters (country/category/text) and click link format: **not confirmed**.

**Terms that matter** (all from the [US terms](https://publisher.connexity.com/terms), last modified 19 Sep 2013):
- Refresh cached content at least every 6 hours (Catalog API). For feeds, update within 6 hours of each new feed.
- Comparison displays must show price and Merchant name with each Product. They must show at least three Offers per Product, or a "see all offers" link.
- Every page with this content needs a linked credit to the Connexity network site.
- Content cannot be altered. Content cannot run on Sites with "excessive advertisements". This may clash with a feed made only of Ads. **Not confirmed** either way.
- Keep the API key "strictly confidential". This fits server-side keys.
- No robots, no self-clicks, no "support this Site" prompts. Valid clicks mixed with invalid ones can be withheld.

## Sovrn Commerce (formerly VigLink)

**Mobile app eligibility.**
- Apps are accepted, but only after you add Sovrn links and send a few test clicks. Review takes up to 5 business days. Each app store page is submitted separately ([mobile onboarding guide](https://knowledge.sovrn.com/kb/mobile-and-software-application-onboarding-guide-f)).
- The Code of Conduct needs advance written approval to promote Merchants through software on a mobile device ([Code of Conduct](https://www.sovrn.com/service-policies/commerce-publisher-code-of-conduct/)).

**Countries.** Markets are currency/language pairs such as `usd_en` and `gbp_en`, not countries ([Product Data API](https://developer.sovrn.com/reference/prod-data-api)). UAE and Lebanon: **not confirmed**.

**Payout.** CPC programmes pay a flat rate per qualified click. CPA programmes pay commission on sales. The minimum is $25 ($50 by wire), paid 90 days after month end ([Payments in Commerce](https://knowledge.sovrn.com/kb/payments-in-commerce); [Getting started](https://knowledge.sovrn.com/kb/getting-started-with-sovrn-commerce)).

**API.**
- **Product Recommendation:** POST with content text plus optional market, price range, Merchant include/exclude, up to 50 products. It returns price, currency, `inStock`, image and an affiliate `deepLink`. Limits: 30,000 requests per 5 minutes per key, and 100 per 5 minutes per IP ([Product Recommendation](https://developer.sovrn.com/reference/get_product_recommendations.md)). The per-IP limit matters for Edge Functions behind shared IPs.
- **Product Data / Price Comparison:** lookup by product URL only, no keyword search. 20 requests/second per account, secret key in the header ([Product Data API](https://developer.sovrn.com/reference/prod-data-api)).
- **Bid Check:** a real-time CPC bid for a destination URL. It needs the Shopper's IP and user agent. Bids expire after 250 ms ([Bid Check](https://authcore.atlassian.net/wiki/spaces/KB/pages/2694999048193/Commerce+Bid+Check+API)).
- There is no keyword or category product search in the API index ([developer index](https://developer.sovrn.com/llms.txt)).

**Fit.** Weak as a search source. Useful later to monetise outbound links that have no other programme.

## Fit with Stafeed's ad source interface

| Interface need | Kelkoo | Connexity | Sovrn |
|---|---|---|---|
| Declare supported filters | Country (per market), category ID, free text, price, EAN | Not confirmed | Market, price range, Merchant |
| Search by Destination Country | Yes, one market per call; US, UK only | US programme only (UK separate) | Market code (currency_lang) |
| Search by category | Yes (`categoryId`; category list feed) | Not confirmed | No |
| Free-text search | Yes (`query`) | Merchant Match by keyword (two-step) | No (content text only) |
| Fetch one Product fresh | No by-ID endpoint seen; re-query by `offerId`/EAN filter is **not confirmed** | Not confirmed | By product URL |
| Price, currency, availability, image, link | All present | Not confirmed | All present |
| Ships-to countries | Only the offer `country` | Not confirmed | No |
| Click link | `goUrl`; open in visible browser on device; no background calls | Direct Merchant links (format not confirmed) | `deepLink` / wrapped links |
| Caching | Avoid caching live `goUrl`s | Refresh at most every 6 h | Responses cached by `pageUrl` |
| Server-side key | JWT "secret key" | Confidential API key | Secret key / site key |

**Blockers and design notes:**
- **Outbound Click flow.** For Kelkoo, the app must open the `goUrl` itself in a visible browser. Stafeed can still record the Outbound Click server-side first. It must not pre-fetch or follow the `goUrl` on the server.
- **No caching of Kelkoo click links.** The adapter should cache Product data (title, image) at most briefly. It should fetch a fresh `goUrl` when the card is shown or tapped. That means the "fetch one Product fresh" call is required, not optional.
- **Geo matching.** Only show a market's Offers to Shoppers in that country. Off-geo clicks are rejected (Kelkoo) or discounted (Connexity).
- **Attribution.** Connexity needs a visible linked credit wherever its content appears. Plan a small "Ads by …" label slot on cards.
- **Ships-to.** Neither network gives a ships-to list. The adapter should treat the market as the only Destination Country.
- **Single-Offer cards.** Connexity's "three Offers per Product" rule applies to comparison displays. Whether a single-Offer card counts is **not confirmed**.

## Others considered and dropped

- **eBay Commerce Network / Shopping.com:** shut on 1 May 2019. eBay pointed publishers to the eBay Partner Network (secondary: [MarTech](https://martech.org/ebay-shuttering-ebay-commerce-network-its-third-party-advertising-network/); [EcommerceBytes](https://www.ecommercebytes.com/2019/04/03/ebay-to-close-shopping-com-and-ad-platform-on-may-1st/)).
- **Shopzilla / Bizrate / PriceGrabber:** now part of Connexity. Covered above.
- **PriceRunner (Klarna):** the API on offer is for Merchants and advertisers ([merchant terms](https://www.pricerunner.dk/info/merchant-terms)). Klarna's Agentic Product Protocol catalog API is for approved partners only ([Klarna docs](https://docs.klarna.com/klarna-search/klarna-agentic-product-protocol/)). No CPC publisher programme found.
- **idealo:** its API is for Merchants to upload offers ([idealo partner web service](https://idealo.github.io/partner-web-service/docs/v2)). Publishers can only promote idealo as an affiliate advertiser on Awin ([Awin profile](https://ui.awin.com/merchant-profile/7705)). Not an Ad source.
- **Ciao:** no current presence found. **Not confirmed** (no primary source).
- **FlexOffers:** affiliate network with daily product feeds via API/FTP, 650M+ products ([FlexOffers publishers](https://flexoffers.com/publishers/)). CPC terms and app rules **not confirmed**. Overlaps with Awin as an affiliate source.
- **Skimlinks:** link-wrapping network. Terms count mobile apps as a "Property" ([Skimlinks terms](https://skimlinks.com/terms-of-service/)). Its product search API is documented only in 2013-era coverage (secondary). Mostly CPA.
- **Yieldkit:** now part of mrge ([yieldkit.com](https://yieldkit.com/)). Link monetisation, not a product search source.
- **Google Shopping:** Merchants buy these Ads. Google's Merchant API manages a Merchant's own products ([Merchant API products](https://developers.google.com/merchant/api/guides/products/overview)). No API was found for a third-party app to pull Google Shopping Ads.
- **Amazon:** commission on qualifying purchases, not CPC ([Operating Agreement](https://affiliate-program.amazon.com/help/operating/agreement)). The API licence needs the app's main purpose to be promoting Amazon ([policies](https://affiliate-program.amazon.com/help/operating/policies)). It is an affiliate source, not PPC.
- **ArabClicks:** Dubai network for the GCC. Apps qualify. Pays CPS/CPA. No product API found ([ArabClicks affiliate marketing](https://www.arabclicks.com/support/affiliate-marketing/)). A possible UAE affiliate source later, not PPC.
- **Admitad (MENA):** Dubai-based. Lists GCC CPA programmes, some with app rates ([Admitad blog, Eid 2026](https://www.admitad.com/en-ae/blog/eid-al-adha-2026-20-gcc-affiliate-programs/)). Publisher product-feed API **not confirmed**.
- **Boostiny (ArabyAds):** MENA coupon-code attribution network (secondary: [wecantrack](https://wecantrack.com/boostiny-integration/); [App Store listing](https://apps.apple.com/app/id1559301526)). Coupon-led, not a product feed.
- **Lebanon:** no PPC or product-feed network targeting Lebanon was found. Only single-Merchant affiliate programmes exist (e.g. [Made in Lebanon](https://made-in-lebanon.net/affiliate-program)).

## Open questions (owner or network must answer)

1. Kelkoo: do you accept a native mobile app as a publisher? Is the Merchant Handoff allowed in an in-app browser tab (Chrome Custom Tabs / SFSafariViewController), or only in the system browser?
2. Kelkoo: what should an app send as `originReferer`?
3. Kelkoo: which traffic type would a swipe feed made only of Ads count as? Is it forbidden by many Merchants?
4. Kelkoo: is there a minimum invoice amount, and are there entry traffic thresholds for a new publisher with no traffic?
5. Kelkoo: how should we fetch one offer fresh by `offerId`? How long may Product data (not `goUrl`) be cached?
6. Connexity: what are the current US and UK publisher terms (the online copy is from 2013)? Does a feed made only of Ads count as "excessive advertisements"? Does a single-Offer card need three Offers?
7. Connexity: Catalog API docs (search by keyword/category, response fields, click link format).
8. Owner: which launch country? If it is the UAE or Lebanon, PPC networks do not help. Lean on Brand Ads and affiliate programmes.
9. Owner: will Stafeed have a legal entity able to invoice (Kelkoo) and receive USD payments (Connexity)?

## Sources

All accessed 2026-11-14. "(secondary)" marks non-network sources. "(search snippet)" marks Connexity help pages that blocked automated reading.

Kelkoo Group
- https://www.kelkoogroup.com/en/for-publishers/
- https://www.kelkoogroup.com/en/our-company/
- https://docs.kelkoogroup.com/for-publishers.md
- https://docs.kelkoogroup.com/for-publishers/publisher-center.md
- https://docs.kelkoogroup.com/for-publishers/quick-starts/feeds-search-or-links-which-is-right-for-me
- https://docs.kelkoogroup.com/for-publishers/shopping-api-search/search-offers/offer-search-request
- https://docs.kelkoogroup.com/for-publishers/shopping-api-search/search-offers/offer-search-model.md
- https://docs.kelkoogroup.com/for-publishers/shopping-api-search/search-offers/offer-search-rate-limits.md
- https://docs.kelkoogroup.com/for-publishers/shopping-api-search/search-link/link-search.md
- https://docs.kelkoogroup.com/for-publishers/quick-starts/traffic-guidelines.md
- https://docs.kelkoogroup.com/for-publishers/quick-starts/how-to-handle-go-urls.md
- https://docs.kelkoogroup.com/for-publishers/guides/click-and-lead-validity
- https://docs.kelkoogroup.com/for-publishers/guides/understanding-merchant-campaigns
- https://docs.kelkoogroup.com/for-publishers/shopping-api-feeds/feeds-merchants.md

Connexity / Taboola
- https://publisher.connexity.com/terms
- https://publisher.connexity.com/registration
- https://www.connexity.com/
- https://www.taboola.com/press-releases/taboola-closes-connexity-acquisition/
- https://pubresources.connexity.com/hc/en-us/sections/360005023258-API-HTTP-Data-Feeds (search snippet)
- https://pubresources.connexity.com/hc/en-us/articles/360017225458-Will-I-generate-earnings-from-all-Connexity-Inc-programs (search snippet)
- https://pubresources.connexity.com/hc/en-us/articles/360017115997-What-is-the-affiliate-commission-rate-I-will-earn-through-the-Connexity-Publisher-Program (search snippet)
- https://www.retaildive.com/news/shopzilla-parent-connexity-acquires-pricegrabber/400812/ (secondary)

Sovrn Commerce
- https://knowledge.sovrn.com/kb/mobile-and-software-application-onboarding-guide-f
- https://knowledge.sovrn.com/kb/payments-in-commerce
- https://knowledge.sovrn.com/kb/getting-started-with-sovrn-commerce
- https://www.sovrn.com/service-policies/commerce-publisher-code-of-conduct/
- https://developer.sovrn.com/reference/prod-data-api
- https://developer.sovrn.com/reference/get_product_recommendations.md
- https://developer.sovrn.com/llms.txt
- https://authcore.atlassian.net/wiki/spaces/KB/pages/2694999048193/Commerce+Bid+Check+API

Others
- https://martech.org/ebay-shuttering-ebay-commerce-network-its-third-party-advertising-network/ (secondary)
- https://www.ecommercebytes.com/2019/04/03/ebay-to-close-shopping-com-and-ad-platform-on-may-1st/ (secondary)
- https://www.pricerunner.dk/info/merchant-terms
- https://docs.klarna.com/klarna-search/klarna-agentic-product-protocol/
- https://idealo.github.io/partner-web-service/docs/v2
- https://ui.awin.com/merchant-profile/7705
- https://flexoffers.com/publishers/
- https://skimlinks.com/terms-of-service/
- https://yieldkit.com/
- https://developers.google.com/merchant/api/guides/products/overview
- https://affiliate-program.amazon.com/help/operating/agreement
- https://affiliate-program.amazon.com/help/operating/policies
- https://www.arabclicks.com/support/affiliate-marketing/
- https://www.admitad.com/en-ae/blog/eid-al-adha-2026-20-gcc-affiliate-programs/
- https://wecantrack.com/boostiny-integration/ (secondary)
- https://apps.apple.com/app/id1559301526 (secondary)
- https://made-in-lebanon.net/affiliate-program
