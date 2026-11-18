# MyEx: paywall and onboarding inspiration (research, Nov 2026)

Sources reviewed:
- **paywallscreens.com** (by Superwall). The founder's link `?category=6004` is Apple's **Sports** genre: golf, fishing and betting apps, none of them relevant. I switched to **6013 Health & Fitness** (598 paywalls) and used the site's `?search=` to pull mental health, journaling, self-care, habit, relationship and dating apps. These are static captures of the main paywall, dated, with several versions per app.
- **screensdesign.com/library**. App pages list every onboarding step as named, timestamped chapters, and that list is free. The screen images and video frames after the first seconds are blurred behind "Unlock Pro", so I did not use them (see section 6). The onboarding *sequences* in section 4 come from the free chapter lists.

All screenshots are in `C:\Users\AdMin\AppData\Local\Temp\claude\4c96b6ba23d3a30f\55d0924c-3e56-4378-96cc-2f5b04c5d31f\scratchpad\research\shots\` (list in section 5). The scratchpad can be cleared by a reboot, so copy the folder somewhere durable if you want to keep it.

---

## 1. What the libraries show

### 1.1 Apps reviewed (28 paywalls, 13 onboarding flows)

| # | App | Screen | Key pattern | Why it works |
|---|---|---|---|---|
| 1 | **Calm** (`calm_1/2/3/5`) | Post-onboarding paywall | Header "Your plan is ready. / Unlock Calm for free". 3–4 benefit rows. One yearly plan shown, "View More Plans" expands Family/Monthly. Price reads "$79.99/yr. ($6.67/mo.)" with the billed price first. Reminder toggle "Remind me 2 days before renewal". If notifications are off, an inline "Enable notifications in Settings… Open Settings" row. CTA "Try Free & Subscribe". X top-left, visible. | Continues the onboarding story ("your plan"), shows one decision, and makes the reminder real when permission is denied. The billed price leads, which is 3.1.2-safe. |
| 2 | **Headspace** (`headspace_1/2/4/5`) | Paywall = trial explainer | Brand mascot (sun) hero. Title "How your trial works". Subtitle "First 14 days free, then $69.99 ($5.83/month)". Segmented **Annual / Monthly** control. 3-step timeline. One version starts with a **struck-through completed step "Share your goals: We've set up your profile based on your answers."** CTA "Start my free trial" / "Try for $0.00". Big X top-right. | The timeline answers the main trial fear. The pre-completed step gives a sense of progress you've already made. The segmented control keeps the screen short. |
| 3 | **Finch** (`finch_1/2/4/6`) | One-time trial offer (after the main paywall is declined) | "✓ One-time offer applied" → "Start your 7-day FREE trial". Timeline Today / Day 5 reminder / Day 7 "You will be charged on Jul 23". **The trial is kept and the annual is discounted** ("~~$69.99~~ $34.99 per year (save 50%)"). Text link "Skip this one-time offer". One version adds "100% Satisfaction Guaranteed". Red "Offer expires when you exit this screen!" | The second chance is easier to accept: still free today, and cheaper later. The **exact charge date** builds trust. (The red expiry line is something we don't copy.) |
| 4 | **Breeze** (`breeze_1/2/5/6`) | Paywall | Mascot clouds. **The user's name in the CTA** ("Janne, Accept Free Trial"). "Secured with App Store" pill. "No commitment. Cancel anytime." One version has a horizontal 3-card timeline, "Trial reminder enabled" ON by default, and a **"How can I cancel?" FAQ** with the actual steps. "✓ No payment now!" under the CTA. "Skip" text instead of an X. | Very soft, reassuring copy. The cancel instructions on the paywall itself are the strongest trust signal seen in the set. (Weekly pricing is something we don't copy.) |
| 5 | **BetterMe Well-Being** (`betterme_1/2`) | Trial explainer | "How does trial work?" with a 3-step timeline. Plan rows "Start now $14.99/month" vs "Try 7 days for free". "Unlock trial and reminder" toggle. Promo code link. | Makes the trial the explicit choice and gives the reminder its own control. |
| 6 | **BetterMe Mental Health** (`betterme-mh_1/2`) | Trial explainer / plan cards | Same timeline-plus-toggle. A second version has 2 big plan cards (12-week vs half-year, "Most Popular") with per-week prices. | Program-length plans ("12-Week Plan") map to a goal, not to a billing period. |
| 7 | **Daylio** (`daylio_1/2`) | Trial explainer / plan picker | "Start Free Trial / How does your free trial work?" with a 3-step timeline: "Day 5: Trial Reminder… You will have 2 more days to cancel" and "Day 7… Or you can continue using the free version unlimitedly." CTA "Try for $0.00" and a visible "SKIP". | It **says plainly that the free version stays**, which removes the loss fear. |
| 8 | **I am** (`iam_1/2`) | Trial explainer | "How your free trial works / You won't be charged anything today". Timeline starts with a **struck-through "Install the app"**, then dated steps ("Jul 30 – Trial reminder", "Jul 31 – Become member"). Reminder toggle. "$5.83/month, billed yearly as $69.99/year". | Endowed progress plus real calendar dates. A warm serif and a beige palette, close to MyEx's tone. |
| 9 | **Opal** (`opal_1/2`) | Plan-continuation paywall | "Your Focus Journey Starts Now". Timeline: **"✓ Get your Focus Diagnosis: You successfully started"** → Today → "Day 6: See first results" (a report notification) → Day 7. "✓ No payment due now." | The timeline promises an **outcome moment inside the trial** (a Day 6 report), not only a billing reminder. |
| 10 | **Duolingo** (`duolingo_1/2/5/6`) | Plan picker / benefits | The mascot is the hero. "Get started with a 7 day free trial on Super". Plan cards with "MOST POPULAR", "View All Plans". CTA "START MY FREE WEEK" / "TRY FOR $0.00". "Cancel anytime, no penalties or fees". One version claims "You're 4.2x more likely to finish your course". | Playful mascot energy and a short CTA. The 4.2x stat only works because Duolingo has the data, which we don't. |
| 11 | **Fabulous** (`fabulous_1/2`) | Narrative paywall | A **letter from "Future You"** ("Janne, do you copy? It's me, future Janne…"), then "Try Free for 7 Days Janne". Trial toggle "Not sure yet? Enable a free trial". | Emotional story that turns the commitment into a self-promise. Too theatrical for grief, but the "future self" idea is useful. |
| 12 | **Balance** (`balance_1/2`) | Discount paywall (returning / second chance) | "Unlock a year of Premium for ~~$39.99~~ $23.99", **Free vs Premium compare table**, CTA "Claim 40% off", plus a soft link "Not sure? Learn about our free year". | A compare table makes the free tier honest. The discount is framed as a full year. |
| 13 | **Rosebud** (`rosebud_1`) | Paywall | Logo, "Grow without limits", "10K+ ratings", 4 AI-feature rows with icons, a Monthly / Annual segmented picker, and a precise fine print: "you'll be charged $107.99/year starting September 29, 2026". | An AI-journal peer of Mira. Feature rows name concrete AI abilities (long-term memory, "Ask Rosebud"). |
| 14 | **stoic.** (`stoic_1`) | Paywall | "Premium / Premium + AI" tier toggle at the top. Feature list tagged "AI". "Yearly + AI $99.99 annually ($8.33/month)". | A clear AI upsell layer. Billed price first. |
| 15 | **Clarity CBT** (`clarity_1/2`) | Paywall | A product mock showing a CBT thought-challenge screen. "Subscription starts at $59.99/year ($4.99/month)". "Enable 7 day free trial" toggle. "Join 1 Million+ Users", 5 stars "5k+ Reviews". | Shows the actual tool, not an illustration. (The trial toggle is something we avoid.) |
| 16 | **Day One** (`dayone_1/2`) | Tier cards | Silver / Gold cards with a one-line promise and the **yearly price as the big number** ("$49.99 per year"). "Start my 30-day free trial", "30 days free, then $74.99 per year". | Big billed price, a long trial, calm typography. Good proof that an honest price hierarchy looks premium. |
| 17 | **Gratitude Plus** (`gratitude_1`) | Paywall | **Testimonial carousel** (named user quote). "7 Day Free Trial Activated" toggle. "√ No Payment Now". "View all plans". | Peer voice from the same emotional space. |
| 18 | **Paired** (`paired_1/2`) | Paywall | "Choose a plan for you & [partner]". "Free trial enabled". Testimonial with photos. "292k 5-star reviews". | Names a person the user cares about. Uses real review volume. |
| 19 | **Cozy Couples** (`cozy_1`) | Paywall | Illustrated house hero, 6 benefit rows with sub-copy, and "7-day free trial, then **$29.99/year** ($1.25 per user/month)". "See all plans". | Warm illustration and billed price first. Relationship-category tone. |
| 20 | **Affemity** (`affemity_1`) | Paywall (relationship coach) | Serif "Unlock the *Love Life* you Deserve", "AI-powered emotional support chat, guided by professional psychologists". Discounted 1-week / 1-month / 3-month plans. | Closest positioning to MyEx (AI emotional coach). Its weakness is short-term plans with strike-throughs. |
| 21 | **RISE** (`rise_1/2`) | Discount paywall | "Recommended by" press logos, "JUST FOR YOU 40% Off", trial-length choice (7 days free vs 1 month $2.49), reminder toggle ON, "Easy, 1 click cancel", "See our Money back Guarantee". | Strong credibility stack. "Just for you" is a pattern to avoid. |
| 22 | **Wysa** (`wysa_1`) | Paywall | Penguin mascot, rotating testimonial, a partner card ("Get premium access for free in partnership with…"), Monthly vs Lifetime. | A mental-health app that offers a free route through partners. |
| 23 | **Mooditude** (`mooditude_1`) | Plan picker | 3 colour blocks: Monthly "Try for Free", Yearly "Best Value", Lifetime "One time fee". | Lifetime as an anchor (not recommended for MyEx). |
| 24 | **Reflectly** (`reflectly_1`) | Discount paywall | Illustration, "Start journaling with 50% off Premium!", Forbes / TechCrunch logos, "110k+ reviews". | Press credibility, used only because it's real. |
| 25 | **QUITTR** (`quittr_1`) | Paywall | Product-shot fan, Monthly vs Yearly cards "SAVE 60%", "START MY JOURNEY", "Money back guarantee". | A recovery/abstinence app with a streak and panic button, structurally like MyEx's no-contact streak and SOS. |
| 26 | **Hunch** (`hunch_1`) | Dating paywall | Profile photos, "Most Picked" 3-month plan, Apple Pay row, "Cancel anytime, no questions asked". | The only modern dating paywall available. Bumble and Hinge are not in either library. |
| 27 | **Agapé** (`agape_1`) | Paywall | Tappable sample premium question categories at the top ("Tap to see example premium questions"), then benefits, "REDEEM 3 DAYS FOR $0.00". | **Lets you sample locked content on the paywall.** |
| 28 | **How We Feel / Lightly / MindDay / Tangerine** (`sd_*.png`) | Onboarding flow lists | See section 4. | |

**Close button timing.** Every static capture shows a dismiss control in the first frame: an X on Calm, Headspace, Balance, BetterMe MH, Rosebud, Opal, Paired, Hunch and Mooditude, and "Skip" text on Breeze and Daylio. Fabulous and Clarity use a low-contrast X. Static images can't show whether the X fades in after a delay. That needs the paywalled videos.

### 1.2 Top recurring patterns in this category

1. **The trial timeline is the default paywall layout in wellness.** Seen in Headspace, Finch, BetterMe ×2, Daylio, I am, Breeze, Opal and the Finch offer: 9 of 28. It almost always has 3 steps: Today (unlock) → Day N-2 (reminder) → Day N (charge, "cancel anytime before"). The best versions add a **real date** (Finch, I am, Rosebud) or a **completed step 0** (Headspace "Share your goals", I am "Install the app", Opal "Get your Focus Diagnosis").
2. **A reminder toggle on the paywall** (Calm, BetterMe ×2, I am, RISE, Breeze). Calm alone handles the case where notifications are denied, with an inline "Open Settings".
3. **"No payment now" reassurance next to the CTA** (Breeze, Opal, Gratitude, Paired, Daylio "Try for $0.00", Headspace "Try for $0.00", Duolingo "TRY FOR $0.00").
4. **Continuity from onboarding** ("Your plan is ready" on Calm, "Your Focus Journey Starts Now" on Opal, "We've set up your profile based on your answers" on Headspace).
5. **Progressive disclosure of plans**: one recommended plan plus "View more plans" (Calm, Duolingo, Gratitude, Cozy).
6. **Social proof, but only real proof**: rating counts (Rosebud, Paired, Clarity, Reflectly), named testimonials (Gratitude, Paired, Wysa), press logos (RISE, Reflectly).
7. **Second-chance offers that keep the free trial** (Finch: trial plus 43–50% off the annual). Balance and RISE use strike-through discounts.
8. **Mascots carry warmth on the paywall** (Duolingo, Breeze, Headspace sun, Wysa penguin), always happy and never pleading.
9. **Personalized copy with the user's name or partner** (Breeze CTA, Fabulous, Paired "for you & [name]").
10. **Free trial toggles** (Clarity, Fabulous, Paired, Gratitude). Common, but App Review now treats them as confusing (see "do not copy").

**Do not copy** (seen in the set, but against MyEx rules or App Store 3.1.2):
- Per-week or per-day prices as the biggest number (Breeze "$8.49/week", Opal "$0.27/day", Paired "$3.33/mo" bigger than $39.99, Duolingo "$7.99/MO").
- "Offer expires when you exit this screen!" (Finch) and "JUST FOR YOU" (RISE): urgency framing.
- Free-trial on/off toggles: same product shown two ways, now an App Review risk.
- Unverified usage claims ("4.2x more likely", Duolingo) and "Join 1 Million+" style claims until the numbers are real.
- "100% Satisfaction Guaranteed / Full refund anytime" (Finch, RISE, QUITTR). Refunds for IAP go through Apple, so we can't promise this.

---

## 2. Gap analysis: MyEx vs best in class

Baseline: `MyEx_Glass_Premium.html` (after the design-spec pass) and `MyEx_Design_Spec.md` P1–P5, S1, S7, S10, S11.

| Area | MyEx today | Best in class | Gap |
|---|---|---|---|
| **Onboarding** | The prototype starts at **Plan ready**. The quiz behind "What happened / Attachment style / Focus / First step" exists only as data (`CFG.what`). There is no welcome, no questions, no "building plan" moment, no commitment step, no notification ask (the Prompts doc asks for it on Welcome, *after* purchase). | Finch: 30 steps in about 2.5 min before the paywall. Calm: goal → plan loading → paywall. RISE: quiz → permissions → "Building Your Plan" → personal numbers → testimonials → paywall. How We Feel: first check-in → reminder time → permission. | **Largest gap.** Plan ready has nothing to pay off, so the paywall sells "an app", not "your plan". |
| **Paywall structure** | Strong: honest price, benefits, 30-day plan strip, trial timeline (Variant A) with inline reminder switch, close + Restore. | Headspace/I am/Opal: a completed step 0 in the timeline. Finch/I am: real charge date. Breeze: "How can I cancel?" FAQ. Calm: reminder switch handles denied permission. | Small but high-leverage: no step 0, no "no payment today" line next to the CTA, no cancel how-to, and nothing for when the reminder is on but notifications are denied. |
| **Price display** | Spec P2 is correct (billed price primary). **But `MyEx_Monetization_Prompts.md` line 63 still says "shown per week"**, and lines 1099–1101 still hold the old exit-offer copy ("That's {introWeekly} a week. We only show this once.", "Claim 50% off"). | Calm, Day One and Cozy show the billed price first. | The Flutter build could bring back the per-week anchor and the fake-urgency line. Fix the prompt document. |
| **Limit sheets** | Spec S10 is good: Mira header, Premium / coins / wait, SOS link. | Agapé lets users **sample** locked content. Opal's timeline promises a mid-trial outcome. Daylio says the free version continues. | The limit sheet doesn't say what the trial would feel like tonight, and the lock-day sheet doesn't show a preview of the locked day. |
| **Exit offer** | Shown once, sheet: "$24.99 for your first year" (pay up front, **no trial**). | Finch: **keeps the 7-day trial** and lowers the annual; dated timeline; text-link skip. | The user just declined a *free* trial and we ask them to pay $24.99 today. That is a bigger ask, not a smaller one. |
| **Win-back** | "Lumi kept your place." with streak, entries and plan saved, plus $9.99 for 3 months then $12.99/month. | Balance: annual discount plus an honest Free vs Premium table. RISE: credibility stack. | Good tone. It offers only a monthly path (lower LTV), and shows nothing new since they left. |
| **Trial lifecycle** | Day-5 reminder notification with a value recap, and a Trial status screen. Matches the best apps. | Opal: a "Day 6: See first results" report notification inside the trial. | Add a positive value moment in the trial (a Day 5 "your first week" recap card) that the paywall timeline can promise honestly. |
| **Social proof** | None (on purpose: no fake stats). | Real ratings and testimonials everywhere. | Needs a slot that only switches on with real data. |

---

## 3. Recommendations (prioritized)

Rules respected throughout: no fake urgency or countdowns, no invented reviews or stats, billed price at least as prominent as any breakdown, close always visible, SOS never paywalled, App Store 3.1.2. Copy follows spec §7 style (Title Case buttons, curly apostrophes, no "journey" or "healed").

### P0

**R1. Build the onboarding quiz (12 short steps) before Plan ready.** *(Finch, Calm, RISE, Lightly, MindDay)*
Screens and exact copy are in section 4. Every answer must visibly change Plan ready, the paywall headline sub, and Day 1.
*Effect:* this is the biggest trial-start lever in the set. Personalization makes the paywall feel like the next step of the user's own plan, not an interruption.

**R2. Add a "Building your plan" screen (about 4 s) between the quiz and Plan ready.** *(Finch "Building Plan", RISE "Building Your Plan", Calm "Plan Loading", MindDay "Building Your Personalized Program")*
Lumi centered, eyes closed. Three rows tick in order (0.9 s each, `--ease-snappy` check, light haptic):
"Matching your focus: no contact, self-worth" · "Planning for your hardest time: late nights" · "Choosing Day 1: 4 minutes, tonight". Every line comes from real answers. No progress percentage, no "analyzing 10,000 breakups".
*Effect:* labor illusion. The plan feels made, which raises its perceived value right before the price.

**R3. Add a completed step 0 to the paywall trial timeline.** *(Headspace "Share your goals", I am "Install the app", Opal "Get your Focus Diagnosis ✓")*
Paywall › Variant A › `.tl` gets a first row with a `--success` check and the title struck through in `--ink-3`:
**~~Build your plan~~** / "Done. Based on your answers."
Then: **Today**: "Full access. No charge." → **{date−2}**: "We’ll send you a reminder." (switch) → **{date}**: "Your plan starts at $49.99/year. Cancel before then and you won’t be charged."
*Effect:* endowed progress (the user is already 1 of 4 steps in), and continuity from onboarding.

**R4. Add a "No payment today" line next to the CTA (annual only).** *(Opal, Breeze, Gratitude, Paired)*
In the dock, between the CTA and `.fine`, add one line with a 14px `I.check` in `--success`: "No payment today". It swaps out (spec P3 `swapText`) when Monthly is picked. The billed price stays in `.fine` at the same 13pt as the step-3 timeline text, so it isn't less prominent than any breakdown.
*Effect:* takes away the moment-of-tap fear. The fine print already says it, but people read the line next to the button.

**R5. Make the reminder switch honest when notifications are denied.** *(Calm)*
When the switch turns on and permission is `denied`, show an inline row under timeline step 2: "Notifications are off for MyEx." plus a text button "Open Settings" (`--accent-ink`). If permission is `notDetermined`, flipping the switch triggers the system prompt directly. The pre-prompt was already shown in onboarding (R9), so this counts as the user's request.
*Effect:* the reminder promise is the core of our trust story, so it has to actually fire.

**R6. Keep the free trial in the exit offer.** *(Finch one-time offer)*
Replace the pay-up-front `myex_annual_intro_50` with a separate annual product, `myex_premium_annual_offer` ($29.99/year with a 7-day free trial; the same subscription group, so eligibility rules still apply). Exit sheet copy:
Title "Still free to try, for less." · Sub "7 days free, then $29.99/year instead of $49.99. Cancel anytime in Settings." · Mini timeline (Today · {date−2} reminder · {date} first charge) · CTA "Start Free Trial" · text button "Not Now".
No "one-time", no "expires", no Lumi (spec L1). If the user isn't trial-eligible, fall back to the current $24.99 first-year sheet.
*Effect:* the step down becomes "same free week, lower price later" rather than "pay now". This is Finch's main second-chance mechanic, and it's on every one of their paywall versions since 2025.

**R7. Sync `MyEx_Monetization_Prompts.md` with the spec before the Flutter build.**
Line 63: change "shown per week" to "billed price primary, per-month equivalent secondary". Lines 1098–1101: replace the old exit-offer copy ("Before you go", "That's {introWeekly} a week. We only show this once.", "Claim 50% off", "Continue with the free plan") with spec P4 or R6. Line 1105: move the notification ask to onboarding (R9).
*Effect:* stops the build from shipping the review-risk copy the spec already removed.

**R8. Make SOS reachable from every onboarding screen.** *(MyEx rule. Not seen in the libraries, which is a gap in the category.)*
Every quiz screen gets a top-right text button "Need Help Now?" that opens SOS (free, no sign-in). People often install a breakup app in an acute moment.
*Effect:* safety, App Review goodwill, and trust before we ask for money.

### P1

**R9. Ask for notifications mid-onboarding, tied to the user's hardest time.** *(How We Feel: reminder time → permission; I am: notification schedule setup; Finch: warm-up after bonding)*
After Q4 "When is it hardest?", show a custom pre-prompt: Lumi (small) and "Want a check-in when it’s hardest?" / sub "One message from Mira at 10 PM. You can change the time." (time picker pre-filled from the answer: late night → 10 PM, mornings → 8 AM, weekends → Sat 11 AM). Buttons "Allow Check-ins" (then the system prompt) and "Not Now". Never ask on the paywall itself.
*Effect:* higher opt-in, because the value is concrete and personal. The trial reminder becomes deliverable for most users. Daily check-ins drive day-2 to day-7 retention, which drives trial conversion.

**R10. Give a first value moment before the paywall: one unsent message.** *(Rosebud: first journal entry before subscribing; How We Feel: first check-in before setup)*
Step 8 of the quiz: "Anything you wish you could tell them?" (multi-line field, placeholder "Write it here. It won’t be sent."). On save, show the toast "Saved. It stays unsent for 24 hours." (spec copy). Plus a "Skip" text button.
*Effect:* the user feels Draft Jail working before the price, which is the product's signature relief. It also creates data that win-back can reference ("1 unsent message saved").

**R11. Add a gentle commitment step: "Your 30-day promise".** *(Fabulous "Commitment Contract", Finch "Commitment Screen", Duolingo "Commitment Level", Liftoff "Commit to Your Goal")*
Title "One promise, for 30 days." / sub "I’ll choose myself, even on the hard nights." Then Lumi in a 160px stage: **press and hold Lumi for 1.5 s** (a ring fills in `--accent`, `M3` success haptic at the end, then Lumi's eyes go happy). Button label under it: "Hold Lumi to Promise". Text button "Maybe Later" (no penalty).
*Effect:* consistency bias. People who make a small promise are more likely to start the program that keeps it. It's also the one place Lumi earns a role before the paywall.

**R12. Show the first 3 days and the hardest-time support on Plan ready.** *(RISE "Sleep Need Calculation / Energy Schedule Reveal", Finch "Starter Plan Reveal")*
Keep spec S1 and add a second `.list` "Your first 3 days": "Day 1 · Tonight · Delete the chat shortcut (4 min)", "Day 2 · Three things you don’t miss", "Day 3 · Write the letter you won’t send". Then a row "Late nights: Mira’s here, and SOS is always free." The `.foot` reads "Days 4–30 open with Premium."
*Effect:* concrete, personal, and specific. The paywall plan strip then refers to something the user has seen.

**R13. Add a "How do I cancel?" row on the paywall.** *(Breeze)*
Under the timeline card, add a collapsed `.list` row "How do I cancel?" that expands in place to: "Settings › your name › Subscriptions › MyEx › Cancel Subscription. Takes under a minute. Your streak and journal stay." The last sentence is true: the free tier keeps them.
*Effect:* the strongest anti-anxiety signal seen. It costs one row and fits the "private, honest" brand.

**R14. Restate the price in the paywall subtitle.** *(Headspace "First 14 days free, then $69.99 ($5.83/month)")*
Paywall `.lead` for annual: "7 days free, then $49.99/year." It swaps to "$12.99/month. No free trial." when Monthly is picked. Move the current lead ("Your full plan, and Mira whenever it gets hard.") to Plan ready, or keep it as benefit-list intro text.
*Effect:* the billed price is above the fold in body size, so the per-month value in the plan row can never be the most prominent number. A strong 3.1.2 posture with no cost to warmth.

**R15. Add a value-recap moment inside the trial and promise it in the timeline.** *(Opal "Day 6: See first results… a report")*
On Day 5 of the trial (the same day as the reminder), Home shows a card: "Your first week" with real counts (talks with Mira, unsent texts, days done). The paywall timeline step 2 becomes: **{date−2}**: "Your first-week recap, and a reminder." (switch).
*Effect:* the reminder day turns from "decide whether to cancel" into "see what changed". This is honest: the counts are real (spec S7 already tracks them).

**R16. Let the lock-day sheet show a preview of the locked day.** *(Agapé: tappable sample premium questions on the paywall)*
In `lockDaySheet`, under the title, show the first 2 lines of the day's exercise in body text with a soft fade (the spec X5 overlay style), e.g. "Pick one photo you keep going back to. Before you decide anything, write down…". Then the CTA "Unlock All 30 Days" with the foot "7 days free".
*Effect:* curiosity converts better than a lock icon, and it shows the depth of the content.

**R17. Add a real social-proof slot, off by default.** *(Gratitude/Paired testimonials, Rosebud "10K+ ratings")*
Reserve one row under the benefits: a ★ glyph, "{rating} on the App Store · {count} ratings". It renders **only** when remote config holds real numbers (suggested threshold: ≥4.5 and ≥300 ratings). Testimonials only with written permission from real users, attributed by first name. Until then the row is absent (no placeholder).
*Effect:* adds trust later without breaking the "no fake stats" rule now.

### P2

**R18. Test a timeline-first paywall (Variant C).** *(Headspace, I am, Daylio)*
Title "How your free week works", the R3 timeline as the hero (no benefit list; benefits move into the timeline's Today row, "All 30 days, unlimited Mira, full analysis"), and an Annual / Monthly segmented control instead of two plan rows. Keep the A/B harness; compare against A (benefits + timeline) and B (compare table).
*Effect:* the strongest mental-health brands converge on this. It's worth a clean test because our users' main fear is a surprise charge.

**R19. Win-back: test an annual path and show what's new.** *(Balance "Unlock a year of Premium for $23.99" + Free vs Premium table)*
Keep "Lumi kept your place." and add a second offer card, "A year for $29.99" / "then $49.99/year". The CTA follows the selected card. Add a `.list` row "New since you left: {feature}" only if something real shipped. A strike-through is allowed only on our real regular price ($49.99).
*Effect:* a higher-LTV reactivation option for users who already know the value.

**R20. Put the name in the headline, not the CTA.** *(Breeze "Janne, Accept Free Trial", Paired "for you & Jnn", Fabulous)*
Plan ready title: "Selin, your plan is ready." Paywall CTA stays "Start Free Trial". In a grief context the name belongs with care, not with a purchase button.
*Effect:* warmth and ownership without a pushy sales feel.

**R21. Optional "future you" note on Welcome, not on the paywall.** *(Fabulous "letter from future you")*
After the trial starts, Welcome gets a dismissible card: "A note from Day 30 you" / "You did the hard nights. Keep going." It's written by the user in a later Day 30 task, so for now it's a placeholder prompt, "Write a note to Day 30 you", that opens Draft Jail.
*Effect:* a self-continuity motivator that supports retention, not a pressure tactic before payment.

**R22. Test trial length (7 vs 14 days) on the annual plan.** *(Headspace 14 days, Day One 30 days)*
The plan is 30 days. A 14-day trial lets users reach the "Rebuild" stage before the first charge. Run it as a RevenueCat offering experiment and judge it on trial-to-paid × trial starts, not trial starts alone.
*Effect:* could lift paid conversion by letting more of the plan land. Watch refund rate.

**R23. Ask "How did you hear about MyEx?" after the purchase.** *(Finch places it after the paywall; RISE and Rosebud ask before)*
One optional screen after Welcome: TikTok, Instagram, a friend, App Store search, other. "Skip" visible.
*Effect:* attribution data without adding friction before the paywall.

**R24. Don't add these:** a lifetime plan (Mooditude, Wysa: it cannibalizes the annual plan and coins already serve one-off needs), a family plan (no fit), a trial toggle (App Review risk), and a mascot on the main paywall (spec L1. If tested, use a 64px Lumi beside the plan strip with no crown, as a P2 experiment only).

---

## 4. Onboarding ideas that raise trial starts

### 4.1 What the flows look like (screensdesign chapter lists)

| App | Sequence (condensed) | Takeaway |
|---|---|---|
| **Finch** (~2.5 min to paywall) | Welcome → choose egg → account → hatch/name pet → your name → self-care dialogue → **notification warm-up → system prompt** → quiz (age, sleep, stress, support system, mental-health challenges, obstacles: 14 questions) → **Building Plan → Starter Plan Reveal → Pre-paywall endorsement → Paywall** → welcome → "how did you hear" → streak intro → **commitment screen** → widget | Bond with the mascot first, ask for notifications while warm, then a long, easy quiz → plan reveal → paywall. |
| **Calm** (~1 min) | Notification permission → ATT → goal selection → account → **plan loading → paywall** | Short. Asks for permissions very early, without context (not recommended). |
| **Headspace** (~1.8 min) | Welcome → account → goal → priority → difficulty → additional goals → **feature recommendations → loading → paywall** → notification warm-up | Recommendations reflect the answers. Notifications come after the paywall. |
| **How We Feel** (free app) | Feature showcase → goals → benefit summary → **first emotional check-in** → done → **check-in frequency → reminder time → notification permission** | A first value moment, then a reminder the user scheduled themselves. |
| **RISE** (~3.3 min) | Value props → social proof → "how did you hear" → quiz → "Expert on You" → permission warm-ups (motion, health, notifications) → **Building Your Plan → personal sleep-need number → adjust → energy schedule reveal** → testimonials → paywall | Personal numbers make the plan concrete. Interleaved value-prop screens ("we'll support you at the right moments"). |
| **Fabulous** | Quiz part 1 → interests → "Analyze habits" → quiz part 2 → **Habit Analysis Summary → Commitment Contract → Paywall** → notification warm-up | The commitment comes right before the paywall. |
| **Duolingo** | Language → course building → source → prior knowledge → goal → **commitment level** → feature carousel & paywall → notification warm-up → widget → first lesson → streak ignition | Commitment and a goal are set before the paywall. Value (the first lesson) comes after it. |
| **I am** | Name, age, gender, beliefs, relationship status → benefits → time goal → **notification schedule setup → permission** → icon/theme → mood check-in → goals → paywall | The notification is a configurable feature, not a request. |
| **Rosebud** | Goal → source → demographics → relationship status → recent struggles → therapy experience → theme → **first journal entry** → goals → subscribe | Users experience the AI before paying. |
| **Lightly** (AI wellbeing) | Feature carousel → social proof → **rating prompt** → "Let's shape your plan" → name → 7 feeling statements → support areas → **Wellbeing Plan Summary → Paywall** → reminders → permission | Statement-style questions ("I bottle up feelings") read as reflection, not a form. (A rating prompt before any value is something we don't copy.) |
| **MindDay** (CBT) | Carousel → name → context → goals → value props → expectations → **social proof & method** → feelings quiz → **statement self-reflection → Building program → Paywall** | Explains the method (CBT) right before the plan, which builds credibility. |

### 4.2 Proposed MyEx onboarding (about 90–120 s, 14 screens, SOS link on all of them)

| # | Screen | Copy and controls | Feeds |
|---|---|---|---|
| 0 | Welcome | Lumi waves (spec S1 stage). "Getting over someone takes time. Let’s make the next 30 days easier." CTA "Get Started". Foot: "Private by default. SOS is always free." | Trust |
| 1 | Name (optional) | "What should we call you?" Field plus "Skip". | Headlines (R20) |
| 2 | What happened | "What happened?" They ended it · I ended it · It was mutual · It’s complicated | Plan ready "What happened", plan tone |
| 3 | When | "When did it end?" This week · 1–4 weeks ago · 1–6 months ago · Longer | Plan pacing |
| 4 | Contact | "Are you still in touch?" No · Sometimes · Most days · We share kids or work | **No contact vs low contact track** (safety and realism) |
| 5 | Hardest time | "When is it hardest?" (multi) Late at night · Mornings · Weekends · When I see their posts | R2, R9, R12 |
| 6 | Interstitial (value prop) | Mira orb (spec L2). "Mira’s there at 2 AM. And SOS is always free, whenever you need it." CTA "Continue". | Pre-sells Mira without a claim |
| 7 | Focus (up to 3) | "What do you want most right now?" Stop checking their profile · Stop texting them · Sleep better · Understand what went wrong · Feel like myself again | Plan "Focus" |
| 8 | Attachment (3 statements, Agree / Not really) | "I worry they’ll forget me." · "I’d rather not need anyone." · "I replay what I could have said." → result shown later as "Leaning anxious" plus the foot "A starting point, not a diagnosis." | Plan ready "Attachment style" |
| 9 | First value (R10) | "Anything you wish you could tell them?" Text field, "Save Unsent" / "Skip". Toast "Saved. It stays unsent for 24 hours." | Draft Jail habit, win-back data |
| 10 | Notification pre-prompt (R9) | "Want a check-in when it’s hardest?" Time pre-filled from #5. "Allow Check-ins" → system prompt / "Not Now". | Trial reminder deliverability, retention |
| 11 | Commitment (R11) | "One promise, for 30 days." Hold Lumi 1.5 s, success haptic. "Maybe Later". | Consistency |
| 12 | Building your plan (R2) | 3 lines tick from real answers. | Labor illusion |
| 13 | Plan ready (spec S1 + R12) | "Selin, your plan is ready." Rows plus the first 3 days. CTA "Continue". | Value before price |
| 14 | Paywall (with R3, R4, R5, R13, R14) | Close visible from frame 1. First close → exit sheet (R6) once. | Trial start |

Notes:
- **Notification timing:** ask at step 10, after the user has named their hardest time and before the paywall, so the paywall's reminder switch (R5) is already authorized for most users. Never ask on launch (Calm does, and it's out of context). Don't ask on Welcome after purchase either (the current Prompts doc), because users who close the paywall never see Welcome.
- **ATT:** if needed, ask after the paywall, not before. No library app gains anything by asking for ATT early, and it adds a cold system prompt.
- **Account:** keep anonymous sign-in at the start (Prompts doc line 889). Ask for Apple sign-in after purchase ("Save your plan to your Apple ID").
- **Analytics** (add to the Prompts doc event list): `onboarding_step_viewed{step}`, `onboarding_answer{q,a}`, `notif_preprompt{result}`, `commitment_completed`, `plan_built_viewed`, then the existing `paywall_view{trigger:onboarding}`. Watch the step-by-step drop-off. Finch-length quizzes only work while each step takes under 3 s.
- **Length guardrail:** if step-to-step completion falls below about 95% on any step, cut that question first (candidates: #3, #8).

---

## 5. Screenshots saved

Folder: `C:\Users\AdMin\AppData\Local\Temp\claude\4c96b6ba23d3a30f\55d0924c-3e56-4378-96cc-2f5b04c5d31f\scratchpad\research\shots\`
Paywalls come from paywallscreens.com (capture dates in brackets). `sd_*` files are screensdesign app pages showing the free chapter list (first rows visible; the full list is in section 4.1).

**Most relevant (start here)**
- `headspace_4.png`: Headspace, "How your trial works" with the struck-through completed step "Share your goals" [Oct 2025] (R3)
- `iam_2.png`: I am, "You won’t be charged anything today", "Install the app" done, dated steps, reminder toggle [Apr 2026] (R3)
- `opal_1.png`: Opal, timeline with "✓ Get your Focus Diagnosis" and a Day 6 results report, "No payment due now" [Jul 2026] (R3, R4, R15)
- `finch_1.png`: Finch, one-time offer that **keeps the 7-day trial**, discounted annual, dated charge [Jul 2026] (R6)
- `finch_4.png`: Finch offer variant with a guarantee step [Oct 2025]
- `finch_6.png`: Finch "Special free trial for you", "Finch is free to use. Unlock extra with PLUS." [Mar 2025]
- `calm_1.png`: Calm, "Your plan is ready" + plans + reminder toggle + "Enable notifications in Settings / Open Settings" [Jul 2026] (R5)
- `calm_3.png`: Calm, collapsed "View More Plans" with a single yearly plan [Jan 2026]
- `breeze_5.png`: Breeze, horizontal timeline, reminder ON, **"How can I cancel?" FAQ**, "No payment now" [Apr 2025] (R13)
- `daylio_1.png`: Daylio, timeline that says the free version continues, "Try for $0.00", SKIP [Aug 2025]
- `dayone_1.png`: Day One, big billed yearly price, 30-day trial, calm layout [Jul 2026] (honest price hierarchy)
- `agape_1.png`: Agapé, tappable sample premium content at the top of the paywall [Sep 2024] (R16)

**Trial explainers and plan pickers**
- `headspace_1.png`, `headspace_2.png`, `headspace_5.png`: Headspace variants, segmented Annual / Monthly [2025–2026]
- `iam_1.png`: I am variant [Jul 2026]
- `betterme_1.png`, `betterme_2.png`: BetterMe, "How does trial work?" + plan choice + "Unlock trial and reminder" [2025–2026]
- `betterme-mh_1.png`: BetterMe Mental Health, dark timeline + reminder toggle [Feb 2026]
- `betterme-mh_2.png`: BetterMe MH, 12-week vs half-year program plans (per-week anchor, don't copy) [2022]
- `opal_2.png`: Opal, Yearly/Monthly with "SAVE 58%" [Mar 2026]
- `calm_2.png`, `calm_5.png`: Calm expanded plans; yearly with a 7-day-trial badge
- `rosebud_1.png`: Rosebud (AI journal), AI feature rows, dated charge in the fine print [Sep 2026]
- `stoic_1.png`: stoic., Premium vs Premium + AI tier toggle [Sep 2024]
- `cozy_1.png`: Cozy Couples, warm illustration, billed yearly price first [Sep 2024]
- `gratitude_1.png`: Gratitude Plus, testimonial carousel, "No Payment Now" (trial toggle, don't copy) [Jul 2026]
- `paired_1.png`, `paired_2.png`: Paired, "for you & [partner]", real review count, testimonial [2025–2026]
- `clarity_1.png`, `clarity_2.png`: Clarity CBT, product mock of a CBT tool; social proof (trial toggle, don't copy) [2022–2026]
- `daylio_2.png`: Daylio plan picker with a mascot illustration [2022]

**Mascot and personalization**
- `breeze_1.png`, `breeze_2.png`, `breeze_6.png`: Breeze, mascot clouds, name in the CTA, "Secured with App Store" (weekly price, don't copy)
- `duolingo_1.png`, `duolingo_2.png`, `duolingo_5.png`, `duolingo_6.png`: Duolingo Super, mascot hero, "View All Plans", benefits (the 4.2x claim needs data we don't have)
- `fabulous_1.png`, `fabulous_2.png`: Fabulous, "letter from future you" narrative paywall
- `wysa_1.png`: Wysa, mascot + testimonial + partner free-access card
- `reflectly_1.png`: Reflectly, illustration + real press logos

**Discount, second-chance and category peers**
- `balance_1.png`, `balance_2.png`: Balance, "Unlock a year… ~~$39.99~~ $23.99", Free vs Premium table, "Learn about our free year" (R19)
- `rise_1.png`, `rise_2.png`: RISE, press logos, trial-length choice, reminder ON ("JUST FOR YOU" and money-back promise, don't copy)
- `affemity_1.png`: Affemity, AI relationship coach (closest positioning to MyEx)
- `quittr_1.png`: QUITTR, recovery/streak app (structural peer to no-contact + SOS)
- `hunch_1.png`: Hunch, dating paywall ("Most Picked", Apple Pay row)
- `mooditude_1.png`: Mooditude, Monthly / Yearly / Lifetime blocks (lifetime not recommended)

**Onboarding flow pages (screensdesign)**
- `sd_finch-self-care-pet.png`: Finch onboarding chapters (pet bonding → notifications → quiz → plan → paywall)
- `sd_calm.png`, `sd_headspace-meditation-sleep.png`: Calm and Headspace flows
- `sd_how-we-feel.png`: How We Feel (first check-in → reminder time → permission)
- `sd_rise-sleep-tracker.png`: RISE (quiz → building plan → personal numbers → paywall)
- `sd_fabulous-daily-habit-tracker.png`: Fabulous (commitment contract before the paywall)
- `sd_duolingo-language-lessons.png`: Duolingo (commitment level, notification warm-up after the paywall)
- `sd_i-am-daily-affirmations.png`: I am (notification schedule setup)
- `sd_rosebud-ai-journal-diary.png`: Rosebud (first journal entry before subscribing)
- `sd_honestly-wellbeing-coaching.png`: Lightly (statement questions → plan summary → paywall)
- `sd_mindday-mental-health-stress.png`: MindDay (CBT method + building program)
- `sd_tangerine-self-care-goals.png`: Tangerine (notification warm-up first)

Contact sheets (4 per image, for quick review) are in `…\scratchpad\research\sheets\`.

---

## 6. What could not be accessed

- **The founder's link** `paywallscreens.com/?category=6004` is the Sports category (golf, fishing, betting), so it wasn't used. Health & Fitness (6013) and search were used instead.
- **screensdesign.com**: screen images and video frames beyond the opening seconds are blurred behind "Unlock Pro". I did not log in or pay, and I deleted the blurred captures. Only the free chapter lists and app header pages were used. WebFetch returns an empty page (the site is JS-rendered), so Playwright was used instead.
- **Not in the libraries (or not found by slug or search):** Bumble, Hinge, MindShift, How We Feel (no paywall: it's free), stoic. and BetterMe on screensdesign, Breeze on screensdesign. Hunch is the only modern dating paywall reviewed.
- **Limit sheets, mid-session upsells and win-back screens** are rarely captured by either library (paywallscreens shows only main paywalls). The R16 and R19 evidence is therefore indirect: Agapé and Balance.
- **Close-button delay** can't be judged from static captures. The X or Skip is present in every captured frame.
- One library entry was mislabeled (QUITTR's second capture shows a different app, "Listen AI PRO") and was excluded.
