# Stafeed

A vertical, swipeable feed made of ads, and openly proud of it. For You is entirely Ads; Shoppers come for the fun and for finding things to buy, and are sent to the Merchant to purchase. Stafeed never sells or takes payment.

## Language

### Catalog

**Product**:
A thing someone can buy, independent of who sells it (e.g. one sneaker model).
_Avoid_: Item, listing, ad

**Offer**:
One merchant's terms for a Product: price, currency, availability, ships-to countries, and destination link.
_Avoid_: Listing, deal, price

**Merchant**:
The seller the shopper is handed off to.
_Avoid_: Store, shop, vendor, brand

**Brand**:
The maker of a Product. Not the same as the Merchant selling it.

**Fixture**:
A hand-made, clearly-labelled sample Product used when no real inventory source is available. Never real commercial inventory.
_Avoid_: Mock, dummy, fake product

**Ad**:
A Feed Item that earns money for Stafeed (Brand Ad, affiliate commission, or pay-per-click), labelled AD. Every Feed Item in For You is an Ad.
_Avoid_: Promotion, listing, organic result

**Brand Ad**:
An ad creative (video or images) supplied by a Brand or Merchant with permission, linked to one or more Products. Shown as supplied, never edited by Stafeed.
_Avoid_: Creative (alone), sponsored post, commercial

**Sponsored**:
An Ad the Brand or Merchant pays Stafeed for directly (per view, click or fixed fee), as opposed to earning through affiliate commission or pay-per-click. Every Brand Ad is Sponsored.
_Avoid_: Promoted, boosted

**Affiliate Ad**:
An Ad for a Product from an affiliate or pay-per-click source, where Stafeed earns on click or purchase.
_Avoid_: Organic product, catalog item

**Not an Ad**:
A Feed Item for a Product that earns Stafeed nothing, shown only inside a Shopping Session to fill gaps when Ads run thin, and labelled as such.
_Avoid_: Organic result, free listing

### Feed

**Feed Item**:
One full-screen card in the feed: either a Brand Ad, or an Affiliate Ad showing a Product with exactly one chosen Offer.
_Avoid_: Card, post, product card (in domain talk)

**For You**:
The permanent default feed, ranked by the shopper's long-term taste. Never changed by a Shopping Session.
_Avoid_: Home feed, main feed

**Shopping Session**:
A named, temporary shopping goal (e.g. "white sneakers under $150") with its own filters and its own taste signals. Many can be kept; one is active at a time.
_Avoid_: Search, query, intent feed

**Not interested**:
A shopper's rejection of a Product: it is hidden permanently, and its Brand and category are ranked lower in the feed where it happened.
_Avoid_: Dismiss, hide, skip

**Skip**:
Swiping past a Feed Item without acting on it. A weak negative signal, unlike Not interested.

### Shopper

**Shopper**:
The person using the app. Anonymous by default; no sign-up needed to browse.
_Avoid_: User, customer, buyer

**Destination Country**:
Where the Shopper wants products delivered. Offers that don't ship there are never shown.
_Avoid_: Region, location, market

**Saved Product**:
A Product the Shopper kept for later, stored with a snapshot (title, image, price, Merchant) so it shows without the feed loaded.
_Avoid_: Favorite, like, wishlist item

**Merchant Handoff**:
Sending the Shopper from a Product to its Merchant to buy. Recorded as an Outbound Click.
_Avoid_: Checkout, purchase, buy button

**Event**:
A recorded Shopper action (impression, skip, save, Not interested, Outbound Click, …) used for ranking and measuring.
_Avoid_: Log, analytics hit
