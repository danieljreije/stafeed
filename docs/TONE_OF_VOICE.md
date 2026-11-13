# Stafeed tone of voice

How the app talks to the Shopper. Short on purpose: read it before writing any text the Shopper sees.

## The one idea

Stafeed is a feed made of ads, and it says so. Every other app hides its ads; this one is proud of them. The joke is the honesty. So the voice is **fun but grounded: it stays a shopping app.**

## Rules

1. **Say what it is.** An Ad is labelled AD. A Product that earns Stafeed nothing is labelled NOT AN AD. Sample data is labelled sample data. Never dress one up as the other.
2. **One light line, then get out of the way.** A wink in a heading or a note is enough. The Shopper came to find things to buy, not to read jokes.
3. **Facts are never a joke.** Price, currency, Merchant, delivery, availability and anything about money or privacy are written plainly, with no irony.
4. **The joke is on us, never on the Shopper.** Laugh at ads, at Stafeed, at advertisers. Never at what someone likes, buys or can afford.
5. **Never trick.** No fake urgency ("Only 2 left!"), no fake scarcity, no guilt ("No thanks, I hate saving money"), no buttons that hide what they do.
6. **Plain words.** Short sentences. No marketing talk ("curated", "elevate", "unlock"), no exclamation marks, no emoji in labels or buttons.
7. **Buttons say what happens.** "Save", "Retry", "Clear filters", "Continue". The playful line goes beside the button, not on it. One exception is allowed per screen when the meaning is still obvious (onboarding ends with "Show me the ads").
8. **Errors are calm and useful.** Say what happened and what to do next: "Couldn't load the feed." with a Retry button. No jokes when something is broken.
9. **Brand Ads are shown as supplied.** Stafeed never rewrites, trims or jokes inside a Brand's own words. Our voice lives around the ad, not in it.
10. **Use the glossary's words** (`CONTEXT.md`) for anything the Shopper can see: Saved, Not interested, Shopping Session, Destination Country.

## Fixed lines

These are decided. Use them exactly; the app name comes from `lib/app/app_name.dart`.

| Where | Line |
|---|---|
| Onboarding welcome | Welcome to Stafeed. It's all ads. We're not hiding it. |
| Every Ad | **AD** (bold, never hidden or greyed out) |
| Brand Ad | **AD** · Sponsored |
| Affiliate Ad note | Stafeed may earn a commission |
| Not an Ad | **NOT AN AD** · Stafeed earns nothing on this one |
| Profile | You've watched {n} ads this week. Advertisers thank you. |
| Sample data | Sample data · not real products |

## Good and not so good

| Instead of | Write | Why |
|---|---|---|
| "Discover curated picks just for you!" | "It's all ads. We're not hiding it." | Honest beats polished. |
| "Oops! Something went wrong 😅" | "Couldn't load the feed." + Retry | Errors are calm and useful. |
| "Hurry, selling fast!" | (nothing) | Never fake urgency. |
| "Where do you live?" | "Where should things be delivered?" | Ask for what we need, and say why: "You'll only see what ships there." |
| "No results. Maybe try being less picky?" | "No matches" + Clear filters | The joke is never on the Shopper. |
| "Pick your interests to personalise your experience" | "What are you into? Pick a few, or skip. The ads will find you either way." | Plain words, one light line. |

## Checking a new line

Ask three things:

1. Is it true?
2. Would it still be clear with the joke removed?
3. Would it annoy you the tenth time you read it?

If any answer is no, write the plain version.
