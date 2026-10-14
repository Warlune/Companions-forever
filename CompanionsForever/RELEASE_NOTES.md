# 1.3.3 - Housing settings and fixes

- Compacted housing settings into View and Scene tabs, with a close button.
- Added optional soft ground shadows beneath housing pets and furnishings.
- Added skybox choices and a shortcut to restore the original sky.
- Day and Night settings now change the lighting smoothly.
- Added Close in combat for the large and compact windows; the mini pet stays available.
- Updated XP Treat icons.
- Fixed an achievement reward tooltip Lua error.
- Fixed dragging housing pets back into the stable.

Housing is still in beta. Please share suggestions and bug reports in the CurseForge comments!

# 1.3.2 - Housing polish and fixes

- Improved housing camera controls, with adjustable movement speed and easier furniture duplication.
- Added an automatic day/night cycle with realm-time and fixed lighting options.
- Unlocked furnishings now appear first, with clearer unlock information.
- Improved housing layouts, portraits, furnishing previews and overlapping pet-window displays.
- Fixed a blocked action when opening housing and lowered the Settings panel.
- Land expansions now start at 500 gold tokens and increase by 250 per plot.
- Tommy Nookle will mail eligible players a one-time refund for earlier land overcharges.
- Improved special-ability cooldown handling and made minor combat balance adjustments.
- Restored healing combat text and fixed stable-space checks for housing pets.
- Fixed a compact-view Lua error and other interface issues.

Housing is still in beta. Please keep sharing suggestions and bug reports in the CurseForge comments!

# 1.3.1 - Housing fixes and clearer rewards

- Furniture crates now reveal the actual 3D furnishing, including both items on a double reward.
- Mail gifts are now separate for each ruleset. Gifts already received in that ruleset stay claimed.
- Fixed missing tower loot messages, including furniture drops, and improved High Contrast reward displays.
- Restored compact action labels in High Contrast.
- Party and guild announcements now share pets and gear only.
- Hover gear names in CF notices and party announcements to see stats and effects.
- Added feedback mail inviting suggestions and bug reports on CurseForge, with a Discord server coming soon.

Companions Forever and housing are still in beta. Update to this build for the new hover tooltips.

# 1.3.0 - A home for your companions

- Housing is here! Build, decorate and expand your own island.
- Give up to three pets a home, put them to work, and send them on expeditions.
- Discover furnishings, furniture crates, housing abilities and new rewards as you explore and progress.
- Housing pets can keep working while you are away, with rewards waiting to claim when you return.
- Added a housing welcome mail with 3 Furniture Crates, claimable once per account. Previous gifts stay claimed.
- Expanded equipment bags and added five free bag-slot unlock credits to spend when you choose.
- Reworked overlapping combat abilities and improved ability collection displays.
- Improved housing controls, camera movement, pet behavior and performance, with an instant 30/60 viewport FPS setting.
- Fixed assorted combat, mail, reward and background-message issues.

Companions Forever and housing are still in beta. More updates, fixes and balance adjustments are on the way. Thank you for playing and sharing feedback!

Both players should update before trading.

# 1.2.3 - Adventure updates and improvements

- Added more to discover as your adventure progresses.
- Adjusted tower encounters, equipment, talents, and rewards.
- Added a bonus for adventuring with other CF players.
- Drag and drop pets to organize your stable, with saved positions.
- Updated the talent layout. Affected branches receive a one-time free point refund.
- Improved talent explanations and retirement previews.
- Improved battle controls to prevent accidental repeat fights.
- Fixed collection achievement tracking and duplicate loot announcements.
- Existing mail and reward claims are preserved; claimed gifts are not resent.

Both players should update before trading.

# 1.2.2 - Announcements and reliability

- Compact Mail and Supplies use closely stacked side tabs with green NEW above unread mail. Larger unread envelopes appear in Camp, with a smaller one on the mini pet window; they ignore clicks, clear when read, and stay hidden over Tower fights. Reduced Motion uses a steady envelope.
- Mail now shows attachment icons with rarity borders, quantities and hover details, including both beta gift chests. Veteran, Champion and Azeroth containers use the standard 2D chest item icon in bags, mail and achievement rewards; corrected the missing texture that left attachment squares blank.
- Removed the automatic Lua-report delivery test and its status display. Old queued/received test entries are cleared; real error reporting stays active. Older clients' test reports are acknowledged quietly to stop retries.
- Reduced normal-tower gear rewards before talents: floors 40-49 have a 1% Epic chance; 50-60 have 3%; 61-100 have 15% Rare, 10% Epic and 5% Legendary. These are chances per eligible first clear, retaining 30% total gear and 70% no gear. World loot, crate contents and Hard Mode rewards keep their previous rates.
- Added a beta thank-you mail with one Azeroth's Adoption Chest and one Azeroth's Equipment Chest. Collect once per addon account across characters and realms; full bags preserve the gifts, and the letter cannot be deleted before collection.
- Added Forever Companion Beta Tester, awarding 1,000 companion tokens once per addon account. The beta badge and reward claim are stored separately from realm progress.
- Mail shows a green NEW label for unread letters or waiting attachments in large and compact views, clearing once everything is read or collected.
- Removed the Collection "Claim waiting pet" button; waiting pets are collected through Mail. Added Delete mail for attachment-free letters, disabled while rewards remain attached. Deleted letters stay deleted across reloads and alt-save merges.
- Lucky Find now grants 0.3 percentage points per rank to each crate's highest non-Mythic rarity (1.5 points at 5/5). The same amount comes out of the lowest rarity, keeping the total at 100%. Two ranks change Azeroth Legendary from 7% to 7.6%. Actual rolls and displayed chances match, with no second upgrade roll. Fortune adds its existing bonus; Mythic stays fixed. World-drop upgrade chance also increases to 0.3% per Lucky Find rank.
- Rest uses its original Sleep icon again. Pet and gear containers use matching shop, drop, bag and opening colors: Traveler/Scout green, Adventurer/Veteran blue, Champion purple, Azeroth orange. Existing bag and mailed crates update on reload. High Contrast preserves brighter versions of these colors.
- Queued manual abilities and remaining turn cooldowns are explicitly cleared between fights. Large and compact ability buttons refresh immediately when a fight starts or ends; per-pet automatic-use preferences remain saved.
- Pet and gear crate percentages now automatically include Lucky Find and Fortune bonuses. Bag tooltips show the same adjusted odds; Mythic's fixed chance stays unchanged.
- Coin bags and XP treats no longer trigger party or CF guild announcements. Your own reward messages still show; incoming consumable notices from older CF builds are also hidden.
- Chat now has two settings: Announce drops in party chat and Receive CF guild messages. Guild drops and chest results use quiet CF notifications only, avoiding the blocked public guild-chat calls. Guild receiving defaults on and preserves an existing CF-message opt-out. Your own rewards and party notices remain visible when guild receiving is off.
- Party announcements stay on the original reward action instead of animation/retry timers. Chest sharing starts when opening succeeds; local reward text still waits for the reveal. Rejected or rapid party announcements fall back to bounded CF messages, with rejected contexts suppressed for the session.
- Chat settings show transport status and client rejection reasons. Temporary addon-send failures retry up to five times, with a 60-second expiry; party changes no longer discard pending guild notices. Share party prepares the last drop in native party chat for you to review and send.
- Clicking the settings cog again returns to your previous page or compact view.
- Inspect can discover recent Trade and Global speakers with Sharing and World discovery enabled. Checks are limited to twice per minute, require an addon reply, and pause for ten minutes after a rejected chat-discovery send.
- Fixed a Lua error when opening or refreshing Error reports, and corrected scrolling while selecting long reports.
- Opened pet and equipment chests share results with updated CF party and guild members, with rarity-colored names. Party public announcements default off. Both players need the updated addon for CF notices.

# 1.2.1 - Accessibility, gear balance and quality of life

- Equipment comparison now uses two native tooltip panels for the hovered item and matching equipped item, with signed stat changes, opaque backgrounds and readable High Contrast text.
- Added Settings > Chat switches for party drop announcements and local CF drop messages. Party announcements default off and cover your world/dungeon drops; local messages default on. Rarity colors appear locally and in party chat for updated addon users.
- Rebalanced all 75 normal equipment definitions to a consistent rarity-scaled stat budget, including an allowance for special effects. Existing items receive the improvements automatically; no normal item loses stats, and hard-mode sets keep their existing stats.
- Fixed error-report handshake timing, lost-reply retries and wrapped Lua error capture. This build queues one clearly labeled delivery test per character for eligible players with error sharing enabled; confirmed receipt appears in Error reports. Test reports do not raise real Lua errors.
- Added Claim All for ready achievement rewards across every category. Full-stable pet rewards go to Mail; blocked rewards remain unclaimed with a warning. All Collection sub-tabs use green NEW labels; main-tab labels keep their existing style.
- Renamed the Collection sub-tab to Pets and clarified the secret count as secrets found. Feeding supplies are now called Food throughout the UI, separate from XP Treats.
- Replaced cycling sort/filter buttons with dropdown selections for achievements, companions, abilities and equipment. Moved compact Mail back to the bottom beside Supplies.
- Added separate Appearance settings for cosmetic frames in large Camp, compact Camp and the mini pet. Inspect always keeps the equipped frame.
- High Contrast keeps readable rarity-colored loot names, crate shakes and rarity effects before the pet reveal. Reduced Motion disables movement while preserving a steady color effect. Tower loot appears above health bars, with extra room for large text.
- Equipped cosmetic frames now appear on the mini pet and Camp portrait, with visibility options in Settings. A new inbox letter explains the basics. Special Thanks now lists Sylie first.

# 1.2.0 - Release polish and reliability

- Simplified all 31 normal and hard-mode talent tooltips to the effect per rank and the current bonus from that talent. Unconfirmed points are not shown as applied bonuses.
- Separated the Hard Mode and Error reports sections in Settings, kept the compact Mail button accessible while its inbox is open, and fixed long letters being clipped or refusing mouse-wheel scrolling after resizing or changing text size.
- Reworked Mail into a small inbox inside the current large or compact view. Click Mail again to close it. Read announcements and collect gifts, migration overflow, or older waiting rewards in the same tray, with no sending controls or login announcement popup. Read markers persist across reloads and account merges.
- Normal and Hard Mode are included in one public addon, with the updated collection spellbook, Sparkly appearances, equipment dragging, stacking coin pouches and XP Treats, crate/chest reveals, and ten companion milestones.
- Reduced temporary memory allocation during bag refreshes while preserving item positions, stacks, overflow and old saved layouts.
- Pet crates and purchased adoptions now commit their reward and receipt before showing animations. A presentation error cannot leave both a rewarded pet and a reusable source crate. Waiting companion claims use the same protection.
- Full or unavailable asset/token history refuses new pet creation without spending adoption tokens, consuming a pet crate or losing a boss reward. Crate-opening guards recover after errors.
- Reviewed malformed and unsolicited addon messages, trade recovery, account saves, upgrade compatibility, idle UI work and release packaging. Expanded automated coverage for failure recovery and bag allocations.
- High Contrast and reduced-motion options remain available across both modes. Public packages contain no sandbox unlocks, spawned test pets or developer commands.

# 1.1.28 - Companion milestones

- Added ten achievements: discover 1 / 3 / 5 different Sparkly species, eat 10 / 50 / 250 treats, discover 5 / 10 / 20 abilities, and obtain a pet with a perfect gold base stat. Rewards range from 25 to 1,000 tokens and can each be claimed once.
- Feeding treats and XP Treats both count when successfully consumed. Tracking begins with this update; herbs, failed uses and capped-pet XP Treat refusals do not count.
- Saved Sparkly and ability discoveries count immediately. Existing owned pets, memorials, Mail and outgoing trade escrow are checked for a perfect 100/100 base stat. Progress persists after retirement, trading, reloads and account merging.
- Find the milestones under Companions: Collection, Abilities, and Training & care. High Contrast keeps their normal readable achievement layout.

# 1.1.27 - Unified normal and hard-mode release

- Normal and Hard Mode ship together in the standard addon. Clear normal tower floor 100 to unlock Hard Mode; public installs contain no sandbox pets, starter sets, test commands or unlocked floors. Existing saves keep their progress.
- Extended High Contrast across the unlock banner, crate reveals, tower rewards, talent selections and XP tracks. These use solid dark backings, readable text and clear selection markers; appearance changes never alter rewards.
- Ornate equipped portrait frames keep their square proportions, with the pet and background inset inside the border.
- Added dropped XP Treats in Common through Legendary rarity, granting 25 / 50 / 100 / 200 / 400 flat XP to the equipped living pet. Treats have an independent 2% eligible-enemy drop chance; no XP multiplier applies. Capped pets keep the item. These are separate from feeding supplies. Coin pouches and XP treats now stack to 30 per type/rarity, with visible counts, one-unit use, drag-to-merge, persistent positions, partial-stack mail claims, and stack-aware trade space. Each unit retains its own consumption receipt. Both players need the updated trade catalog for new trades.
- Equipment bag slots now retain item positions and empty spaces through refreshes and reloads. Drag to move/swap bag items, equip matching gear, or return worn gear to a chosen bag slot; replaced equipment occupies the source slot. Filters dim unmatched items instead of rearranging them. Dropping outside or pressing Escape cancels, and locked/incompatible/stale drops preserve items. Bag and equipped-icon rims now retain their item rarity colors separately from selection highlights.
- Rebuilt both Crates subtabs with three wooden crates above three treasure chests, native 3D previews on the left, and vertical rarity odds on the right. Opening reveals use the matching container with rarity effects; Reduced Motion keeps a still reveal. Active Hard Mode removes Common/Uncommon from purchased and ordinary bag-container contents. Pets stop at Legendary; gear has a separate 0.01%–0.5% Mythic chance by price tier. Normal-mode odds, prices and container IDs are preserved.
- At trainer level 40, retirement gives tokens instead of trainer XP: 2 per rarity tier plus 1 per 5 pet levels, capped at 30. Dead pets receive half; free recovery pets receive a reduced earned-level-only payout. Retirement previews and confirmation show the token reward. Below level 40, retirement XP is unchanged.
- Sparkly pets now use reviewed native alternate skins throughout the eligible collection. Unique pets without a suitable color-only alternate keep their original colors with sparkles. Removed the silver filter, preserved the seven approved preview colors, and corrected sparkle placement at different UI scales. Stats, rolls and achievement-only pet rules are unchanged.
- Hard-mode talents now show the same Available Points bar as normal talents, with a separate confirmed point purchase. New point prices are 400 / 800 / 1,600 / 3,200 tokens in groups of four (24,000 total). Previously purchased points are kept; allocation uses points and the 500-token respec still returns them.
- Hard-mode Training now sits beside Reset Talents and switches to a full-page talent grid with a Back button, owned/unspent point counts and the next token purchase cost.
- Tower manual-ability buttons now follow the selected teammate before combat as well as during it, including both buttons on pets with two manual abilities. Auto-use preferences apply to that selected pet; portrait hints now describe both herbs and abilities.
- Clearing normal floor 100 now introduces Hard Mode with a full-screen purple reveal after the finishing attack. The unlocked purple UI theme and unlock animation have separate settings, plus a replay button. High Contrast takes priority, and Reduced Motion uses a still banner. Already-unlocked saves get the theme without repeated login animations.
- Camp, Tower and Talents share a slim native WoW XP-bar frame, dark track, fill and metallic dividers. Camp shows its numbers above the bar; Talents keeps readable text over the thinner bar; Tower stays number-free, and Talents keeps its blue retirement preview.
- Collection now includes a parchment-style Abilities spellbook with search, discovery filters and page arrows. Undiscovered abilities are gray; discovered abilities explain their effects on hover. Discoveries persist through retirement, trades and account merges; existing owned pets are added automatically.
- Added silver-rimmed, segmented pet XP bars to Camp and Tower in both window sizes. Camp shows level and XP; Tower shows a slim bar under each pet's health, without numbers.
- Adopted the native-style layout as the default, including connected navigation tabs, aligned achievement categories and details, compact Camp/Tower controls, and segmented trainer XP with a silver rim.
- High Contrast keeps this layout with solid dark panels, white text and distinct selections. Decorative talent backgrounds are hidden and stat-roll highlights are dimmed for readability.
- Perfect and top-ten-percent stat rolls use borderless gold/silver row highlights with steady text; Reduced Motion makes the highlights steady too.
- Removed the local appearance-preview switch, command and duplicate legacy window border.

# 1.1.26 - Clean list-counter text

- Fixed corrupted range separators beneath the Achievements and Frames lists.
- Cleaned two older documentation passages and added a packaged-text encoding check to catch common corruption patterns before release.

# 1.1.25 - Easier trade invitations

- Select a player in Inspect and press Request trade to send the request immediately. The button changes to Join trade or Open trade when appropriate.
- Incoming requests show a small invitation with Join trade, View offer and Decline, even when addon windows are hidden. A sound plays once per invitation, and the Mini alert opens Trade directly.
- Inspect keeps the requesting player visible during the invitation, including when discovery filters are off. Clearer trade status text shows connecting, waiting for a player to join and offer updates.
- Declining or expiring a request notifies the sender so uncommitted items can return. Delayed offer fragments cannot reopen a recently dismissed invitation. Simultaneous requests between two players resolve into one trade.
- Joining never confirms a trade. Prepared offers open for review first, and the existing three-second confirmation delay, ownership rules and interrupted-delivery recovery remain in place.

# 1.1.24 - Shared adventure and overflow mailbox

- Alts on the same account and realm now share pets, gear, tokens, supplies, talents, collection, achievements and tower progress. Log into each existing alt once to merge its old save.
- Keeps the highest token balance and progression instead of adding them. Existing rolls, abilities, pet gear and claimed rewards are preserved; each character imports only once with a backup.
- Added Mail in large and compact views for overflow companions, equipment and unopened crates. Pets keep attached gear. Deliveries never expire, and collection requires free space.
- Newly earned overflow supports 200 waiting deliveries; larger migration overflow is preserved. Purchases and achievement claims continue to require room.
- Added an account-wide merge notice with a Don't show again checkbox. Reopen it in Settings or with /cfpets merge; /cfpets mail opens deliveries.
- Pending trades remain tied to their original character until resolved. Missing or conflicting saves stop migration and keep backups for recovery.
- Other realms/rulesets keep separate adventures. Window positions remain per character.

# 1.1.23 - Soulbound companions and hard-mode gear

- Pets become soulbound at level 11. Level 10 and below remain tradeable under the existing living-pet, inactive-pet and unequipped rules. Free recovery pets remain untradeable.
- All hard-mode set equipment is soulbound, including existing items. You can still equip it on any of your own pets, remove it, or sell it.
- Bound assets show a padlock and dimmed portrait in the trade inventory, with a clear explanation on hover. Pet and equipment descriptions show Soulbound.
- Trading pets still unlocks the recipient's collection and preserves the sender's discovery. Rarity and Sparkly discoveries remain supported.
- Both players must update for new trades. Older unconfirmed offers containing bound assets must remove those assets or cancel; already-sent confirmations keep their safe delivery path.
- Save data remains per character. This update does not merge accounts or alter existing pets' stats or gear bonuses.

# 1.1.22 - Sparkly companions and hard-mode builds

- Expanded hard-mode training to 15 talents with four ranks each. Only 16 points can be purchased, so choosing a build matters. Unlock remains normal tower floor 100, independent of trainer level.
- Added health, attack, armor, speed, damage-over-time resistance, herb healing, equipment finding and rarity talents, plus three unusual utility choices: Pocket Change, Hop Along and Daydream.
- Pocket Change and Hop Along give one token or one pet XP every 100/80/60/40 tracked jumps. Daydream gives one active-pet XP every 120/100/80/60 online seconds while resting in a city or inn. Utility XP has no gear multiplier and cannot heal a pet during battle.
- Hard-mode respec costs 500 tokens and returns all purchased points for free reassignment. Normal talents stay separate. Purchases and respecs require confirmation, and existing ranks are retained.
- The first four purchased points cost 200 tokens each, then 400, 800 and 1,600 per group of four. Buying all 16 still costs 12,000 tokens total.

- Newly obtained pets have a 0.1% (1 in 1,000) chance to be Sparkly, available from the beginning. Achievement-exclusive pets and unlimited free recovery crates cannot be Sparkly.
- Sparkly is cosmetic: a pale silver appearance, native animated twinkles, a portrait star and a Sparkly name. Stats, rarity and abilities are unchanged.
- Existing pets are never rerolled. The variant survives reloads, Inspect and trades; both traders need the current version. Collection records remember Sparkly discoveries after retirement.
- Reduced Motion keeps the twinkles still. Visual fitting is awaiting in-game review.
- Reaching trainer level 40 no longer blocks retirement. Retiring at the cap gives no further talent XP and still requires confirmation; locks, gear and collection records are preserved.
- Free recovery pets give no retirement XP at level 1 and only 25% of their previous reward after training. Recovery pets remain untradeable.

# 1.1.21 - Special actions and clearer rewards

- Herbs keep their own instant Heal action. Healing and control specials have separate buttons, use the pet's next action, and share the existing cooldown.
- Right-click a special to toggle automatic use for that pet. Left-click queues or cancels one use. Automatic healing specials wait until health is below 85%; they never spend herbs or tokens.
- Added Frost Nova and Hammer of Justice to new pet ability rolls. Existing pets retain their abilities and rolled strength. Control immunity prevents uninterrupted stun chains.
- Hard Mode enemies can use the expanded ability catalog, including healing, shielding and control.
- Normal tower floors with multiple opponents now offer all four target tactics in both window sizes.
- Achievement rewards explain their contents on hover, while unrevealed rewards remain secret. Shortened several care, adoption, progression and inspection tooltips.
- New ordinary gear drops no longer select duplicate stat profiles within the same slot. Existing equipment retains its name, stats and item identity.
- Updated Inspect and trade compatibility for the new abilities. Both trading players need the current version; compatible in-progress older trades remain recoverable.

# 1.1.20 - Release readiness and compatibility

- Keep trade and party-witness channels available when WoW reports they are already registered.
- Ignore unreadable addon-message prefixes before routing messages.
- Strengthen package checks for the correct title, commands, saved-data names, version consistency, Windows path collisions and unexpected files.
- Validate every staged file against its ZIP before local installation.
- Repair the public-build test workflow and separate stable companion releases from Waylaid beta releases.
- Verified upgrading during a pending pet, equipment and crate trade from actual 1.1.18 and 1.1.19 packages.

# 1.1.19 - Clearer identity and command compatibility

- Display title is now Companions Forever: Pet Battles & Adventures.
- Use /cfpets or /companionsforever. Removed the /cf alias, which conflicts with Hermes; /companions and /fcp remain available for existing macros. Updated in-game help and guides.
- Chat messages use the compact [CF Pets] label.
- Keeps the single CompanionsForever installation folder, existing saves and multiplayer message identifiers. No rename, save migration or extra compatibility folder is required.

# 1.1.18 - UI polish

- The All achievements view now lists ready-to-claim and unpaid bonus rewards first, preserving the normal order within each group.
- Perfect and top-10% stat names flash gold or silver in Camp and Inspect. Reduced Motion keeps static colors; legacy and ordinary rolls retain normal labels.
- Tokens, treats and herbs sit closer together, with spacing measured from the current text and font size.
- Full gameplay regression checks and all 16 focused audit groups passed. Includes the nearby discovery fix and release cleanup from 1.1.16-1.1.17.

# 1.1.17 - Nearby discovery recipient checks

- Recheck a nearby player's identity, visibility and connection immediately before sending a queued addon discovery message. Departed players and reused target/nameplate slots are discarded instead of messaging old names.
- Skip hostile players and unreadable unit information. Use the client's unmodified character name, preserving Forever surnames rather than sending to a disguised display name.
- Discovery uses hidden addon messages over the whisper transport, not regular player chat whispers. World OFF still stops nearby discovery; ordinary chat error messages are not globally hidden.
- Validated departed, disconnected, invisible, hostile, recycled and restricted units, plus working friendly discovery/replies, send limits and opt-out. Full regression and 15 focused audit groups passed.

# 1.1.16 - Release audit and cleanup

- Apply incoming trade-message limits before decoding items and assembling invitations, bounding unsolicited packet processing as well as active trades.
- Stop the chest animation update frame when no reveal is pending; opening another crate wakes it automatically.
- Remove dormant chest-preview routing, developer UI hooks and the development faction-art override from the public runtime.
- Update achievement regression fixtures for the expanded catalog and strengthen upload checks against preview/developer files and hooks.
- Validation: full gameplay regressions and 14 focused audit groups, including protected tooltip data, diagnostic redaction/spoof rejection, reward replay/full-inventory guards, collection scrolling, legacy save/reward migration, and 24 randomized multi-item trade exchanges with lost/duplicate/reordered messages and reloads. No lost or duplicated assets in those simulations. Live client FPS and visuals are not measured by these tests.
- Existing saves, earned items, old gift-crate redemption and interrupted-trade recovery are preserved.

# 1.1.15 - More adventures, clearer retirement

- Added 30 achievements (75 total): PvP kills, jumps, exploration, dungeon bosses and dungeon clears, including new Forever dungeons.
- Easy rewards are tokens; medium rewards add adoption crates; six hard milestones award hidden Epic pets plus tokens. No new frames.
- Existing tracked PvP kills and exploration count. Jump and dungeon progress starts with this update; dungeon credits require confirmed boss evidence and ignore duplicate notifications.
- Added a gold selection frame and mouse-wheel/scrollbar browsing to the Talents retirement stable, including 16-pet stables.
- Reward claims remain one-time across reloads. Full bags/stables leave the whole reward waiting. New secret pets stay hidden until discovered and are excluded from normal drops/crates.
- Both players should update before trading the new pet catalog; older Inspect clients continue to receive compatible pets.

# 1.1.14 - Floating pet health bars

- Smaller retirement padlock with a distinct keyhole and padding inside the button.
- Optional tower HP bars use a slim green/red overhead display with current/max HP above it.
- Overhead bars follow the actual model position every frame, including attack movement, in large and compact tower views. Loading portraits keep their bar attached; offscreen models no longer leave bars pinned to the window edge.

# 1.1.13 - Pet rolls and stable improvements

- Classic game-style borders are now permanent on the large and compact windows.
- Lock pets against retirement from Camp. Locked pets appear gray and show Locked instead of retirement XP.
- Optional Settings > Tower: HP above pets displays current/max HP over companions in normal and hard tower, in large and compact views.
- Shift-left-click equipment to select several items, then sell them together. Equipped gear, stale selections and duplicate sales are rejected before any selected item is consumed.
- Settings now include Short pet tooltips and Show pet roll ranges. Maximum rolls shimmer gold; the top 10% below perfect shimmer silver. Reduced Motion keeps static colors.
- Newly obtained pets receive permanent individual base-stat and ability-quality rolls. Existing pets keep their exact fixed stats and abilities; they are never rerolled.
- New base stats vary over a narrow range: Common 96-104%, Uncommon 97-105%, Rare 98-106%, Epic 99-107%, Legendary 100-108% of that species/level/rarity's previous base value. Each stat rolls independently and retains its percentile while leveling.
- Per-ability quality odds: Rare pets 93% Rare / 6% Epic / 1% Legendary; Epic pets 94% Epic / 6% Legendary; Legendary pets 98% Legendary / 2% Mythic. Epic and Legendary still have two abilities.
- Ability strength ranges from 90-100% of the original effect at Rare, 100-110% at Epic, 110-120% at Legendary and 120-130% at Mythic. Shield reduction cannot exceed 75%.
- Roll data survives reloads, full-stable Inspect and trades. Both players must update before starting a new trade; existing pending trades retain their recovery path.

# 1.1.12 — Special thanks

- Added Settings credits thanking Unda, Obijay, Shampanda and Sylie for their help.

# 1.1.11 — Release

- Unda's Darnak the Tunneler can now be discovered in any regular pet adoption crate, including bought and bag-held crates. Rarity follows the crate's normal odds. The sunglasses portrait remains a surprise in Collection until discovered.
- Existing Unda gift crates remain usable and tradeable.
- Public release excludes the chest-preview API, test panels, private delivery scripts, developer gift commands and the developer gift-message receiver. Existing earned items and saves are preserved.
- Includes faster chest reveals, native rarity effects and sounds, and equipment-crate drops from 1.1.10.
# 1.1.10 beta — Faster reveals and equipment-crate drops

- Chest reveals take 35% less time: about 4.1 seconds including the reward display.
- Eligible world and dungeon kills now have a separate 1% equipment-crate chance. Direct gear remains at its 3% base chance.
- Among dropped equipment crates: Adventurer 63.49%, Veteran 31.75%, Champion 3.17%, Azeroth 1.59%. Each uses the same contents odds as its shop equipment box, allowing higher-rarity surprises without dropping hard-mode sets.
- Equipment crates are unopened bag items. Right-click replaces the crate with one gear item using the same rarity effects and sounds. Full stables do not block them, and a full bag can exchange the crate in place.
- Crate identities, consumed receipts and gear origins persist through reloads and trades. Both players need this equipment-crate catalog for new trades; older pending trades retain their recovery path.
# 1.1.9 beta — Spellbursts and pet reveals

- Chest effects stay inside the reveal frame. Higher rarities add native spell bursts, layered rings and spiraling sparks; Legendary adds a level-up pillar, holy nova and fireworks.
- Every chest plays an opening sound. Uncommon and higher add a rarity reveal sound after the lid opens.
- The chest and its effects fade away, then reveal the pet's 3D model (or the equipment icon).
- Common remains still. Rarity colors remain hidden until opening, and Reduced Motion keeps a simpler reveal.
# 1.1.8 beta — Bigger chest reveals

- Common chests stay still. Uncommon shakes gently; Rare, Epic and Legendary shake progressively harder before opening.
- Rare and higher release more rays, spiraling sparks and expanding rings, with the strongest reveal reserved for Legendary.
- The native 3D chest lighting changes to the reward color only after the lid opens. Reduced motion keeps a static reveal.

# 1.1.7 beta — Rarity reveal effects

- Closed chests briefly shake before opening; every rarity uses the same anticipation to keep the result a surprise.
- Reveal effects grow from a small Common glow to more rays and sparks at each rarity. Epic adds an expanding ring; Legendary adds a larger burst and two rings.
- Uses native game models and textures. Reduced motion removes shaking, moving sparks, flash bursts and expanding rings.

# 1.1.6 beta — Chest opening surprise

- Chests stay neutral until their lid opens, then shine with the reward rarity's color from inside the chest.
- Uses native game chest animations and spell textures, with a corrected camera angle and room for the opening lid.
- Reward chat and mini alerts wait for the reveal, so they do not spoil it. Closing all addon views still delivers earned reward alerts.

# 1.1.5 beta — Chest reveal loading

- Chest reveals wait for the native model to load and fit it to the camera before opening.
- A slow or missing asset no longer silently skips the reveal: loading is polled, the legacy game path is retried, and a bounded icon fallback remains available.
- The opened chest stays visible behind the reward, with the actual reward's rarity glow.

# 1.1.4 beta — Stable resting

- Pets set to rest keep recovering when unequipped, including while other pets fight in the tower.
- Towns and inns automatically rest every living pet in the stable. Leaving the rest area ends automatic rest; manually started rest continues.
- Each resting pet has its own healing timer. Hunger still pauses recovery, fallen pets stay dead, and combatants cannot rest-heal.

# 1.1.3 beta — Unda's Darnak

- Adds Unda's Darnak the Tunneler as a separate pet with sunglasses added to the original game portrait. His tradeable gift crate opens once into a level-1 Rare companion. Hidden in Collections until discovered; absent from ordinary crates and world drops. Original Darnak and native moving models remain unchanged. Both trading players need this version for the new pet/crate.

# 1.1.2 beta — Crate capacity labels

- Pet-crate Buy buttons show Stable full when no companion space remains. Equipment-box Buy buttons show Bag full when gear storage is full. Buttons return to their prices when room is available, including after trade reservations are released.

# 1.1.1 beta — Tower rewards and chest reveals

- Combat text now shows Guard over its pet and green +N HP for healing, regeneration and life drain, including hard-mode teammates.

- Winning a normal or hard tower encounter now selects the next floor after the finishing animation and a short reward display. The next battle still requires Fight; floor 100 never switches tower modes automatically.
- Tokens, treats, herbs, equipment and crate rewards rise in the middle of both battle views with game icons and rarity colors. Bag-full rewards retain their claim-in-Equipment message. Displaying a reward never grants it again.
- Successful pet-crate, recovery-crate, equipment-box and bag-crate opens show the native treasure chest opening, a glow matching the actual reward rarity, then the reward portrait/icon. Uses only client models, UI textures and animations; no new external artwork. A native chest icon remains available if the model fails to load.
- Chest reveals stay inside the current addon window and are presentation only: no rerolls, repeat consumption or animation-driven grants. Reduced Motion skips the opening movement. Existing chat and mini loot receipts remain available.
- Automated tests cover both tower modes, floor-100 boundaries, one-time rewards, actual loot rows, blocked/repeated crate opens and chest animation sequencing. Live chest framing and model availability still require client verification.

# 1.1.0 beta — Combat clarity and social updates

- Large Tower floor arrows now sit inside the battle scene, matching Compact. Heal living pets between encounters with herbs or tokens; full-health and dead pets cannot consume healing supplies.
- Normal tower team HP follows the finishing attack instead of showing the level-up full heal early. Restore the heal animation receipt and green healing numbers on the selected pet.
- Normal enemy bars are red, elites gold, and rares silver, with outlined white HP numbers and labeled tooltips.
- Replace action narration with pooled scrolling damage: white on enemies, red negative damage on allies, green healing and Miss indicators. Frozen, Poison, Burn and Slowed labels accompany small hoverable debuff icons with remaining turns.
- Stat tooltips now use the selected pet's current health, attack, armor, speed, hit/miss chance and XP, with plain explanations.
- New achievements and newly unlocked frames display NEW until selected. Existing claimed rewards are not marked new on migration.
- Add 30 randomly rolled Rare+ specials (36 total), covering single-target and area damage, healing, drains and shields. Existing abilities are preserved; Rare pets still have one special and Epic+ pets two.
- Inspect adds Guild, Party, Raid and World list filters. World discovery checks visible nameplates, targets and mouseover at most six times per minute; only addon replies add players. Sharing OFF and World OFF stop nearby discovery. This is not a realm-wide player search and requires an updated peer with sharing enabled.
- Start a trade with the player selected in Inspect without targeting them. Incoming requests flash the Mini and your own Inspect portrait and print a chat notice. Click the Mini alert to open Inspect.
- Expanded abilities use a new Inspect/trade capability. Both trading players need this ability catalog (1.1.0); old pending trades keep their recovery path. Older Inspect clients receive only pets their catalog can decode.
- Beta validation: full regression suite, production normal/hard combat, all 36 normal-combat abilities, secret/oversized discovery inputs, bounded UI pools and queues, expanded Inspect and two-client pet transfer/reload simulations. Live client visuals and two-player discovery still need playtesting.

# 1.0.1 — Folder compatibility fix

- The release ZIP now contains only `CompanionsForever`. The obsolete `ForeverCompanions` save-loader folder is no longer bundled, avoiding a name collision with another addon.
- An unrelated addon named `ForeverCompanions` no longer blocks startup. Its saved data is left untouched and is not imported. Genuine early save-loader imports remain supported when that loader is already installed.
- Existing Companions Forever progress is preserved. Install or replace only the `CompanionsForever` folder; do not rename, overwrite or delete another addon's `ForeverCompanions` folder.

# 1.0.0 — Release

- First stable release of Companions Forever, bringing together companion collecting, the normal and hard-mode towers, equipment and set bonuses, talents, achievements, cosmetic frames, Inspect and trading.
- Includes the latest fixes for window layering and hover fading, instant tower healing, city auto-rest, equipment comparisons, achievement sorting and PvP recovery.
- Pet crates and equipment boxes use the rebalanced rarity progression; Adventurer's and higher crates no longer award Common quality.
- Existing saves, pets, gear, collections, talents and tower unlocks are preserved. No reset or gameplay rebalance from 0.8.12.
- Public package excludes developer grant/reset controls and separate test addons. Updated bundled guides and removed beta labels.

# 0.8.12 beta

- Fix the large window staying faded when hovered. Movement fading now checks the cursor against the entire window's scaled screen bounds, including child controls and models. Unreadable cursor data keeps the window visible. Compact and Mini remain unaffected.

# 0.8.11 beta

- Rebalance equipment boxes to the matching pet-crate base odds. Traveler's: 80% Common / 20% Uncommon. Scout's: 50% / 35% / 13% Rare / 2% Epic. Adventurer's and higher no longer contain Common gear: Adventurer's 70% Uncommon / 23% Rare / 7% Epic; Veteran's 55% / 32% / 12% / 1% Legendary; Champion's 35% / 40% / 22% / 3%; Azeroth's 15% / 45% / 33% / 7%. Prices and Lucky Find remain unchanged.
- Your active pet automatically rests in cities and inns while energy or health needs recovery, using the existing 25% rested-area energy bonus. Full energy still allows slow health recovery; fully recovered pets wake automatically.
- Auto-rest never interrupts tower battles. Leaving the rested area wakes an automatically resting pet; manually started rest stays active. Clicking Wake prevents auto-rest for the current visit.

# 0.8.10 beta

- The large window fades to 25% while moving with the mouse outside it, and returns when hovered or stopped. Compact and Mini stay fully visible.
- Achievements now offer All, Completed and Closest sorting, with a saved PvP kill count.
- Hovering bag equipment compares it with your active pet's equipped item in the same slot, showing colored item-stat differences.
- Normal-tower healing applies immediately, including while paused, without spending an attack turn. Ready healing abilities still work for free; full-health pets do not consume herbs or tokens. Hard-mode healing remains instant.
- Credited enemy-player PvP kills restore 10% max health, 5 food and 10 energy to the active living pet, including at the level cap. Repeated kills of the same opponent have a five-minute recovery/count cooldown that survives reloads; creature rewards are unchanged.

# 0.8.9 beta

- Fix Mini and Compact drawing through one another when they overlap. Each view has a separate frame-level range: Mini below Compact, Compact below the large window, with model scenes, bars and controls kept together.
- Settings menus and confirmations now follow their parent window's level. Game panels still take priority, and saved window positions and visibility are preserved.

# 0.8.8 beta

- Fix player resource bars and action buttons drawing over Camp, Compact and Mini. Companion windows now sit above the gameplay HUD and move behind the map, Auction House and standard game panels while those panels are open.
- Restore the normal layer when game panels close, including overlapping panels and the load-on-demand Auction House. The team stable picker inherits its window's layer; the minimap launcher remains low priority.
- Layer changes preserve open/hidden preferences and use visibility hooks instead of per-frame polling. No gameplay, save or balance changes.

# 0.8.7 beta

- Diagnostic reporting now checks actual send results and a receiver handshake, allowing delivery when the general realm restriction flag is set but whispers work. Active chat lockdown remains respected.
- Failed handshakes retry after 30 seconds; reports are retained until acknowledged. A failed receiver reply no longer blocks the next handshake attempt. Settings shows send failures and connection state.
- Reporting remains enabled by default, with saved opt-outs preserved. Reports still contain only short redacted addon errors, with bounded queues and manual copying available.

# 0.8.6 beta

- Exclude known Snake Trap summons and observed player-controlled creatures from pet farming, XP, kill credit and loot, including readable dungeon fallback kills. Normal wild snakes remain farmable.

- Shorten pet-roll chat to a compact CF line with the roll, cutoff and result; preserve party labeling.

- Lower large, compact, mini and minimap-launcher window priority so game windows can cover them. The stable picker follows its parent window.
- Move the pet-location toggle inside the map viewport with a dark backing, visible in both full-size and half-size maps above map artwork, including when paws are turned off.

# 0.8.5 beta

- Rebalance higher pet crates with no Common outcomes: Veteran's 55% Uncommon / 32% Rare / 12% Epic / 1% Legendary; Champion's 35% / 40% / 22% / 3%; Azeroth's 15% / 45% / 33% / 7%.
- Each higher pet crate now improves the chance of Rare-or-better, Epic-or-better and Legendary rewards. Prices stay the same; shop and unopened bag crates use the same updated odds. Equipment-box odds remain separate.
- Validate all 100 rarity rolls for all six pet crates through both purchase and bag-opening paths.

# 0.8.4 beta

- Battle scenes pulse red when any living team pet is below 25% HP, including unselected teammates. Works in normal/hard and large/compact views; healing clears it, dead pets do not trigger it, and Reduced Motion makes it steady.
- Pet-crate base odds: Traveler's 80% Common / 20% Uncommon; Scout's 50% Common / 35% Uncommon / 13% Rare / 2% Epic; Adventurer's 70% Uncommon / 23% Rare / 7% Epic, with no Common pets. Purchased and bag crates share these odds. Equipment boxes retain their existing odds.
- Inspect lists only recently confirmed addon users and yourself, instead of every guild/party roster entry. Unknown or unanswered targets no longer create empty player buttons. Direct target inspection remains available.
- Validation covers exact thresholds, healing/death/Reduced Motion, every rarity roll through purchased and bag-crate paths, and unknown/stale/confirmed Inspect entries.

# 0.8.3 beta

- Compact tower: move healing-target pet portraits directly below the battle scene, place floor arrows and selection inside the scene, and arrange styles/actions/supplies below the pets.
- Remove Fight/Pause/Heal text under compact action icons; hover descriptions and the herb count remain. Pause uses the game's pocket-watch icon.
- Reduce compact tower height by 42 UI units. Camp supplies and resource layout remain unchanged.

# 0.8.2 beta

- Remove the duplicate Heal selected button from the tower control panel. Use the existing heal icon for the selected pet; the panel still shows its name.

# 0.8.1 beta

- Fix the Lua error when hovering a tower team portrait: its pet lookup is now local to the team UI and safely ignores stale selections.
- Fix flashing duplicate enemy frames in both tower views. The old portrait HUD no longer reappears between updates of the new enemy grid.
- Team portrait tooltips use current displayed battle HP. Added hover and frame-by-frame refresh regression coverage for normal and hard towers.
- No save, progression or balance changes.

# 0.8.0 beta

- Hard Mode is now part of the main addon. Clear normal floor 100 to permanently unlock the Ascendant Spire and a 16-pet stable on that character. Switching towers, leveling new pets, retiring the champion and reloading do not revoke either unlock.
- The stable changes from 3x3 to 4x4 within the same footprint. Camp, Inspect, trading, loot capacity and team selection support all 16 slots. Both players need this update for new trades; older Inspect clients retain a compatible nine-pet view.
- Deploy three living level-75+ pets in Hard Mode. All three attack, each has an HP bar, and clicking a portrait selects the instant herb-heal target. Right-click a portrait to change its pet. Styles lock during combat; targeting tactics remain changeable. Fallen pets stay dead, and only a pet that levels up receives the level-up heal.
- Hard Mode has 100 sequential floors, randomized enemy compositions, up to six elites and four character-specific rare encounters above floor 39. Starter, Ascendant and Mythic equipment sets drop exclusively there; late floors retain the tested demanding set/ability progression.
- Every hard-mode equipment piece grants pet XP: Starter +20%, Ascendant +35%, Mythic +50%. Full five-piece sets give 2x / 2.75x / 3.5x pet XP, including on level-1 pets. Small fractional bonuses accumulate. Kill limits count base XP; bonuses apply afterward. Retirement/trainer XP is unchanged.
- Four separate 4/4 hard-mode talents appear only after normal floor 100: World XP (+100% kill XP at full rank), Tower XP (+40% normal-tower XP), Token Finds (+20% world/dungeon kill tokens), and Quick Rest (+20% resting energy recovery). Each node costs 200 / 400 / 800 / 1,600 tokens for its four ranks. Select, then Confirm; purchases persist through normal talent resets. The ordinary trainer cap stays 40. With five Mythic pieces and maxed XP nodes, the multipliers reach 4.9x normal-tower XP and 7x kill XP.
- Normal Mode uses the team-style tower layout with its original background and single-pet rules. Normal enemy strength, base XP, loot rates and care costs are unchanged.
- Removed prototype grants, refill/reset controls, test floor unlocks and test-addon dependencies from the release. Existing main-addon saves are preserved; prototype saves are not imported.
- Validation covers the public addon boot, real normal-100 unlock, persistent stable expansion, 16-pet Inspect/trades, full-stable refusal, exclusive gear ownership, XP bonus rounding, reward deduplication and the existing security/ownership regression suite. Live in-game visual review is still needed.

# 0.7.2 beta

- Basic tower fights now cost 9 energy instead of 15. Tower XP increases by 50%: first clears award 18 + 3 times the floor; replays award 60% of that, rounded down.
- Sixty randomized full campaigns all cleared floor 100. Median simulated online time fell from 93.0 to 47.6 hours for cautious mixed play, 37.3 to 17.8 hours for optimized mixed play, and 118.3 to 58.9 hours with Common pets only. Real travel, AFK time and player decisions are not included.
- Enemy strength, loot odds, trainer costs, world XP and resting speed are unchanged. Existing pets and saved progress are preserved.
- This prepares basic-tower pacing for a future hard tower requiring a level-75+ pet and completion of the basic tower. Hard mode is not included in this release.

# 0.7.1 beta

- Move native Collection portrait loading out of wheel/slider/search callbacks. New portraits wait for a short pause in scrolling, then load one at a time, at most 25 per second and never more than one per frame.
- Pending requests follow recycled cards: skipped pages are discarded instead of rendered later. Already loaded visible portraits remain, and names, rarity, selection and tooltips update immediately. New portraits briefly show a question mark while loading; the selected preview loads first.
- Loading pauses on hidden pages and other collection sub-tabs, and its update frame stops when the bounded queue is empty. The pool remains 24 cards plus the selected preview; no full-roster texture cache is created.
- Automated checks cover rapid wheel input, stale requests, hidden tabs, slow-frame catch-up, correct portraits after recycling, and queue limits. Forty rapid scroll events produced no native portrait calls during scrolling and only 24 final-view calls afterward. Live WoW CPU usage remains to be retested; the mock benchmark does not measure native model-render costs.
- Saved progress and gameplay balance are unchanged.

# 0.7.0 beta

- Collection scrolling reuses the 18 portraits that stay on screen when moving one row, loading only six new portraits. The same 24 cards are recycled; there is no growing frame/texture pool.
- Cache the alphabetized supported roster and filtered search results. Discovery, rarity upgrades and fresh/loaded saves invalidate the view; new secret companions still appear immediately after discovery. Literal source/name searches and recycled-card clicks retain their existing behavior.
- Scrolling past either end now does no extra rendering. A simulated 240-scroll benchmark reduced portrait render calls from 5,760 to 1,440 and sorts from 240 to zero; Lua CPU time was 0.39 versus 0.04 seconds. This is a mock-API benchmark, not a live WoW FPS measurement.
- Removed unreachable XP-popup queue code left behind after XP moved into the pet frame. Retained stable numeric model IDs, old-save imports and legacy trade recovery because they still protect saved progress and interrupted exchanges.
- Security input sweep exercised 360 malformed, oversized and restricted-value packets across six receivers without errors or unauthorized rewards/trades. Existing duplication, ownership, gift, claim and recovery tests remain part of the regression suite. These checks do not authenticate a modified client or edited save.
- No currency, crate, XP or combat balance changes in this update.

# 0.6.53 beta

- Expanded to 45 achievements and rebalanced token/crate rewards. Major milestones bundle secret pets, frames and tokens; a few secret pets are available earlier through exploration and retirement.
- Added 10 illustrated portrait borders, replacing half of the existing geometric styles. They stay completely hidden from the Frames gallery until earned; unearned achievement previews use a question-mark icon.
- Fifteen achievements now reward secret companions using supported Classic models. Secret companions appear in Collections only after discovery, then remain recorded after retirement or trading. Normal collection totals and ordinary farm/crate pools exclude them.
- Previously claimed achievements offer only newly added rewards through Claim bonus. Paid receipts prevent repeated payouts; full bags, stables or wallets leave the whole new bundle waiting. Existing progress and earned frames are preserved.
- Multi-part reward previews show separate pet, frame and token/crate icons. Vertical scrolling remains available for achievements and visible frames.
- Inspect supports new secret species with a new full-stable format and retries all four older formats. Older peers receive only compatible species; both players should update for the new pets and frame artwork.
- Automated checks cover legacy reward upgrades, repeat/reentrant claims, capacity failures, secret visibility, retirement persistence, gallery filtering, illustration rendering and five Inspect protocol versions. Live in-game artwork/layout checks remain outstanding.

# 0.6.52 beta

- Achievements and Frames use vertical scrollbars and mouse-wheel scrolling instead of page arrows. All 30 achievements and 20 frames remain available.
- Equipment and Inspect model previews restore the selected faction camp background.
- Inspect opens your own complete living stable directly, with current stats and abilities, without relying on addon messages. It also recognizes your own guild broadcast as a local view.
- Fixed duplicate addon-prefix registration disabling full-stable and history requests after reinitialization. Messaging errors now distinguish incomplete replies from basic active-pet broadcasts instead of blaming the addon version.
- Replaced player paging arrows with a horizontal portrait strip for you, online party/raid members, online guild members and recently seen addon users. Hover for names and click to request their stable; long lists scroll horizontally. Roster membership alone does not prove the player has the addon or sharing enabled.
- Full stable requests remain private addon whispers, with version fallback, bounded snapshots and rate limits. Basic guild/party/raid broadcasts still contain only the active pet. Saved pets, rewards and trades are unchanged.

# 0.6.51 - Long-term feats and decorative frames

- The mini portrait is two text rows shorter: rarity remains on the border and tooltip, and token gains share the balance row. Larger font settings still resize the layout.
- Large, compact, and mini windows each have independent 50%–150% size settings, defaulting to 100%.
- Expanded to 30 achievements. New goals cover up to 311 addon discoveries, 100,000 readable creature kills, 30 learned WoW companions, 30 visited outdoor zones, new Forever zones, trainer level 40 and 50 retirements. Existing achievement IDs, claims and progress are preserved.
- Achievement cards now use large native challenge icons, ornamental rims, progress lines and completion marks. Unfinished challenges are gray; achieved challenges regain color. Reward previews show coins, crates, miniature frames or WoW's question-mark icon for an unrevealed secret pet.
- Expanded Frames to 20 styles, with paged previews and achievement unlocks. Borders use solid-color geometric corner and edge decorations, including stepped, diamond and circuit patterns. Removed all overhead crest icons. Decorative geometry is cached until the style/locked state changes.
- New kill counts start with this update, share the existing readable creature-loot deduplication, include nearby party credit and work without an active pet or remaining XP budget. PvP and restricted kills without readable creature identities are excluded.
- Native-pet feats read the character's CRITTER companion book through the available Classic API. Addon pets and mounts do not count. Highest observed progress is kept; an unavailable or restricted API never invents a count.
- Exploration records actual current-player outdoor zone visits, normalizes subzones, and ignores map browsing, continents and instances. Forever milestones recognize Mount Hyjal, Zephras Isle, Riverglades and Shen'dralas by the IDs already used in the bundled map data. Visits begin with this update.
- Inspect now retries older full-stable protocols automatically when a partner cannot answer the newest format. Tests cover all nine pets across four protocol versions. A 0.6.50 partner can see the full stable with a default border for newer frame IDs; update both players to see all 20 frames. Versions predating full-stable sharing can still only report their active pet.
- No save reset, achievement-reward replay, change to existing reward amounts or ordinary farming odds. Existing trade compatibility remains 0.6.50+.

# 0.6.50 - Collections, achievements and portrait frames

- Collection now contains three inline sub-tabs: Collections, Achievements and Frames. The normal collection keeps its A-Z list, collected/missing filters, native portraits and farm hints.
- Eleven character-wide challenges reward tokens, unopened adoption crates, cosmetic frames and two achievement-only companions. Claim rewards from the achievement details; each is paid once per character. Full bags/stables, a full token wallet or a tower battle leave the reward waiting.
- Existing discoveries, trainer level and the highest floor among retained pets contribute to ordinary milestones. Retirement counts, Common-pet victories at floor 30+ and rare-enemy challenges begin with this update. Rare progress counts first-clear victories only.
- Secret companions use supported Classic owl and crimson-whelpling models with new companion names. They have ordinary family/rarity scaling and randomized blue+ abilities. They never appear in the normal collection list, farming table or ordinary crate pool, even after discovery. Their reward names are revealed after claiming. They remain usable in the stable and tradable under the normal living/inactive/unequipped rules.
- Frames includes a preview and a Use frame button. Simple is available immediately; Bronze Pathfinder, Grove Keeper and Tower Champion unlock through achievements. Your character's selected cosmetic border surrounds the pet preview seen by other players in Inspect.
- Inspect validates the frame ID and waits for a complete requested snapshot. Both players need 0.6.50 for the new framed snapshots and new trades; already-held older trades remain recoverable. Sharing settings still apply.
- No save reset or change to ordinary farming/crate odds. Public builds exclude developer tools.

# 0.6.49 - Token accounting and reward history

- Token earnings and spending now use a bounded SHA-256-linked journal. Existing balances become a legacy starting checkpoint without resetting or inventing older progress. An unexplained balance change is recorded with a plain-language reason; progress is preserved.
- Pet-crate purchases, equipment boxes, opened bag crates and developer gifts retain origin receipts. The origin travels with the asset through trades. Conflicting known origins or a known crate claiming a different reward block that exchange without deleting anything.
- Inspect saves checkpoints from the player you request. A later reply can show that up to 32 recent events extend the previous checkpoint. Changed checkpoint contents, inconsistent arithmetic and broken chains show the specific conflict. Missing history, longer gaps and new baselines remain limited history, not accusations.
- Inspect includes a My history button and hover explanations. There are no reputation points, player votes, public blacklists or automatic bans. Unusual luck and absent party witnesses do not lower a score.
- New trades require both clients on 0.6.49 and include all nine origin fragments before confirmation. Older held trades retain recovery support. Full stable snapshots also carry reward origins.
- Normal bag-crate opens reject reentrant calls; gift crates are consumed before payout callbacks. Existing pouch protections remain intact.
- History sharing follows the existing Sharing setting. Proof replies are requested, sender/nonce-bound, limited to 32 events and paced; token journals keep 256 events and peer caches keep 64 players. No external service is involved.
- These checks make simple edits and known replays harder to pass through normal trading. Hashes are not signatures: a modified client can fabricate plausible future events, new IDs or reset its history. They cannot establish that rewards were honestly earned or guarantee persistence through a crash.

# 0.6.48 - Expanded equipment and coin pouches

- Expanded equipment from 15 to 75 named pieces: 15 each for Weapon, Head, Body, Collar and Trinket. Original item IDs and stats are unchanged.
- 60 regular pieces can roll across all six qualities. The other 15 are special items restricted to Rare, Epic and Legendary. Only 1% of blue-or-better equipment rolls select the special pool; this applies to world/dungeon drops, tower rewards and purchased equipment boxes.
- Special items display green Equip text. Effects include Leech, Keen Strikes, True Aim, Guardian Ward and Renewal. These effects work during tower battles; identical effects do not stack. Effects have the same strength across blue/purple/orange, while ordinary stats continue scaling with rarity.
- Eligible green-through-red world and dungeon kills have a separate 2% coin-pouch chance when there is bag room. Restricted dungeon kills use the existing player-level fallback. Pouch quality is 85% Uncommon (10 tokens), 12% Rare (25), 2.7% Epic (60) and 0.3% Legendary (150). Pouches never roll gray or white; these percentages describe pouch quality, not enemy difficulty.
- Pouches occupy bag slots, display rarity borders and a bag icon, announce drops in chat and can be traded unopened. Opening consumes the permanent asset receipt before crediting the fixed token amount. Repeated clicks, reentrant callbacks, known duplicate IDs, individual-item restoration, changed contents and items in trade escrow cannot redeem again. A full wallet keeps the pouch.
- Both trading players need 0.6.48 or newer for new exchanges. Older pending trades remain recoverable; new catalog items cannot be added to an older pending exchange.
- As with other addon assets, this cannot prevent editing the entire save/client or restoring all progression from a backup. No server-authoritative currency is involved.

# 0.6.47 - Stable inspection and asset history

- Inspect now has a prominent player name, a rarity-colored 3x3 living stable, selected pet model, equipped marker, owner-reported stat totals and special ability icons with hover explanations. The snapshot age is visible; Inspect target refreshes it. Older addons still show their active-pet reply.
- Pets, equipment and unopened crates receive permanent IDs preserved through new trades. Both sides save matching transfer receipts. Known duplicates, retired/sold/opened assets, stale ownership revisions and conflicting species/rarity/ability records block confirmation without deleting assets.
- Existing assets are migrated as legacy, and old pending trades retain their original data for recovery. No progress reset or change to drops. New trades require both players on 0.6.47 or newer.
- Optional Party kill witnesses in Settings asks nearby party addons to corroborate a matching, independently observed successful farming kill. This does not certify rarity, prevent collusion or create a global ledger. Solo and hidden kills still work normally without witnesses.
- Network data is bounded and validated; full stable snapshots are requested, paced and assembled before display. Incomplete, unsolicited and wrong-sender snapshots cannot replace the current stable. History records are bounded at 5,000 per character; reaching the limit pauses new audited trades instead of discarding receipts.
- These are transparent consistency checks, not server-authoritative anti-cheat. Edited clients can fabricate new IDs and plausible history; rolling back saves or crashing before persistence remains outside addon guarantees. Missing witnesses or legacy history never labels a player a cheater.

# 0.6.46 - Pet farming roll chat

- Actual pet-drop rolls now appear in chat by default, with the creature, roll out of 10,000, winning cutoff, result and distance above the cutoff on a miss.
- Party rolls are labeled and keep their shared 500 cutoff; solo rolls show Tracker's cutoff when trained. The display never rolls again or changes rewards, and duplicate kill events do not repeat it.
- Toggle Show pet farming rolls in chat in Settings, or use /cf rolls on, /cf rolls off, or /cf rolls to toggle. The preference is saved. Non-farmable enemies, raids and other cases where no pet roll happens remain quiet.

# 0.6.45 - Tower XP and mini rewards

- Centered the trainer level inside a symmetrical circular badge, including at larger text sizes.
- The mini pet window now shows the token icon and balance, with a separate temporary green +amount indicator. Item/crate reveals and pet XP keep their own space.
- Increased first-clear tower XP to 12 + 2 per floor, and repeat clears to 60% of that amount (rounded down). Floor 10 gives 32 XP first-clear / 19 repeat; floor 50 gives 112 / 67. XP still awards once and appears after the final hit.
- No character reset. Existing pet XP, talent points and cleared floors are preserved.

# 0.6.44 - Visible party kill rewards

- Fixed nearby party kills being rejected when Forever hides the distance API. A readable party identity plus readable visibility now allows the normal kill and pet-drop checks to run.
- Confirmed out-of-range players and unknown killers remain excluded. Hidden identities are never inspected; the existing restricted-dungeon fallback remains available.
- Pet farming stays at a shared 5% party chance, including gray critters. No save reset or drop-rate increase.

# 0.6.43 - Tower expeditions and companion care

- Collections sort A-Z; selected bag slots highlight. Larger currency/supply counts, item-style equipped gear tooltips, plain-language stat help and racial icons improve the main and compact views.
- Five saved camp backgrounds per faction, with left/right arrows. Native burn, frost, poison and slow effects follow combat; loading the next enemy no longer hides the pet scene.
- First-clear XP is now 5 + floor number; repeats give 40%. World kill XP uses a shared 12-per-minute cap. Tower XP is presented once, after the finishing animation, separately from recent world XP.
- Better first-clear tokens, first-clear elite loot, and four persistent random rare elites per pet. Rare leaders have 3x normal health and 15% extra attack. Their first defeats guarantee Adventurer crates through floor 30 and Veteran crates above 30. Full-bag tower rewards wait for claiming.
- Rest restores 100 energy in ten minutes, or eight minutes with the character's rested flag. Four Care talents improve max energy, food use, feeding heals and herb heals while keeping the trainer cap at 40.
- Treats and herbs cap at 20; excess existing supplies refund their normal price once. Herb purchases during battle cost 6 tokens instead of 4. Supply action icons show amounts.
- The talent panel includes an available-points box, trainer level badge, XP bar and retirement preview. Spending still requires Confirm.
- New trades require 0.6.43 on both clients to preserve rare-floor layouts. Existing held trades retain recovery handling. No character reset.

# 0.6.42 — Trade bags and verified connections

- Trade now shows your 3x3 offer beside the other player's 3x3 offer. Your existing 8x8 equipment bag and living 3x3 pet stable appear beside each other, with rarity borders, native pet portraits, locked bag slots and hover details. Right-click inventory to add; right-click your offered slot to remove.
- Each player may offer up to nine mixed pets, loose equipment items and unopened crates. The exchange commits as one transaction. Every change invalidates both confirmations; the full new offer must arrive before a fresh three-second review countdown can finish.
- Removed the unconditional realm-flag gate that prevented trading from trying the ordinary whisper API used by Inspect. Active chat lockdown and real send failures remain respected. A matching connection reply is now required before the initiating player places any assets on hold. Failed sends, timeout, cancellation, reload or changed assets during this check leave inventory untouched.
- Both players need 0.6.42 or newer for new trades. Offer packets are paced and bounded, incomplete or old snapshots cannot confirm, bag/stable capacity reserves cover every offered asset, and retry receipts prevent repeat deliveries. Old single-asset pending trades retain Retry/Cancel recovery.
- Connection verification does not replace the final two-player confirmations. Addon saves remain local and cannot guarantee ownership against edited/restored saves or crashes before WoW saves data.
- The supported crate roster remains 311 pets. No pet, item, currency or talent save reset is performed.

# 0.6.41 — Trading and accurate crate counts

- Added Inspect > Trade and /cf trade inside the main window. Each player can offer one living inactive pet, one unequipped equipment item, or one unopened bag crate. One-sided gifts are supported. Pets must have no worn equipment; free recovery pets cannot be traded.
- Both players review the offers and press Confirm after a three-second countdown. Any offer change clears both confirmations and restarts the countdown. Confirmed offers are locked until an offer change or safe cancellation.
- Offered assets are held outside the usable stable/bag. Reserved capacity, saved pending trades, peer/revision checks and permanent delivery receipts protect normal clients against duplicate messages and interrupted delivery. Pet discovery stays in the sender's collection; the recipient receives the original rarity, level and special abilities. Incoming pets must fit the recipient's pet level cap.
- A committed trade cannot be refunded. Pending delivery/cancellation can be retried with the same player after reconnecting. Tower battles and legacy imports are blocked during a pending trade.
- Both players need the updated addon and permitted addon-message transport. Realm restrictions are shown before any new trade removes an asset. Local saves are not server-authoritative: editing/restoring saves or a crash before WoW saves data can still cause loss or duplication. Live two-player verification is still required on the beta realm.
- Crate tooltips and empty-stable text now use the supported Classic/SoD roster count, rather than the full imported catalogue. Crate discovery totals include pets previously retired or traded.

# 0.6.40 — Small pets stay inside the tower

- Fixed model positioning that pushed enlarged critters, including Mechanical Squirrel and frogs, outside the tower view. Pet and enemy positions now compensate for native model scale on all three axes.
- Attack approaches, returns to idle, floor changes and camp/tower switches preserve the intended positions and enemy rows regardless of model size.
- The gold level-up effect uses the same scale correction to stay centered on the pet.

# 0.6.39 — Flight visibility and fractional attack talents

- Compact no longer treats an inherited parent hide as a manual close. After an automatic close, it briefly waits for taxi state and restores itself during flight. Escape and explicit close/toggle actions still close it. World entry refreshes the saved compact preference.
- Attack now retains fractional gear and percentage bonuses instead of flooring the result before combat. A confirmed 1% attack point therefore increases a low-level pet's attack, such as 12 to 12.12. Actual hit damage and health still resolve to whole points.
- Camp stats show attack totals and the blue talent contribution to two decimal places, removing trailing zeroes. Pending talents still grant nothing until Confirm is pressed.

# 0.6.38 — Quiet tokens and clear mini loot icons

- Enemy token drops update the wallet without queueing a mini-window notification.
- Equipment reveals show the actual item icon with NEW ITEM; dropped crates show the crate icon with NEW CRATE, separate from the opening animation. Icons fit the selected text size and reset portrait state between different reward types.
- Equipment and crate finds retain rarity-colored chat alerts. Dungeon crates waiting for bag space now also show their crate icon in the mini and tell the player where to claim them in chat.

# 0.6.37 — Confirm talent allocations

- Talent clicks now create a temporary preview instead of spending points. Pending ranks appear blue and the point counter shows the remaining budget.
- Press Confirm to apply all selections together. Cancel clears pending choices; right-click removes pending ranks from the end of a branch. Closing or leaving the talent screen discards unconfirmed choices.
- Pending talents never affect pet stats, loot, income or retirement bonuses. Confirmation rechecks points, branch limits, prior allocations and combat state before committing. Respec clears pending choices and keeps its separate confirmation.

# 0.6.36 — Enemy tokens, clearer crates and stronger treats

- Eligible NPC kills now roll 0-1 tokens, or 0-2 for known elites, rare elites and bosses. The rolls are uniform and independent of bag capacity, pet ownership and the pet-XP cap. Gray enemies stay excluded; hidden dungeon enemies use the normal roll when classification is unavailable. Existing boss completion rewards remain separate.
- Scout's Adoption Crates now roll 69% Common, 20% Uncommon, 10% Rare and 1% Epic before Lucky Find. This applies to shop and dungeon pet crates. Equipment-box odds are unchanged.
- Crate cards now use aligned, rarity-colored odds with matching border accents. Bag crate tooltips show the same colored base chances.
- XP arriving immediately after a level-up no longer restarts that level's effect or sound. The native gold effect fades sooner to avoid its repeated pulse.
- Treats now heal 10% maximum health instead of 5%, retaining +35 food and the full-health cap. Feed tooltips show both benefits.
- Equipment equip/unequip/sell history now includes the addon version and item ID; movement messages explain where gear went. The direct Equipment shortcut clears filters. Existing tests and a new 30-item test cover every quality and slot through swaps, pet transfers, reload initialization, death and retirement without item loss. Reported loss on friends' unspecified versions has not been reproduced.

# 0.6.35 — Rest recovery, persistent mini and beta diagnostics

- Rest now fills energy first, then restores 1 actual HP every five seconds while fed and outside tower combat. It wakes the pet when both health and energy are full; hunger still pauses recovery.
- Added a yellow energy bar below XP in the mini portrait, with layout space at every font size.
- Escape no longer closes the mini. Removed the OnHide preference write that made reloads and instance loading screens hide it permanently. Only explicit mini toggles/hide buttons persist visibility; old accidental hidden flags are repaired.
- Beta diagnostic sharing defaults on, with a one-time migration and clear notice. A later explicit opt-out remains saved. Recent local reports are queued once within existing bounds.
- Error settings now explain blocked outgoing messages on both senders and the developer receiver. Blocked attempts do not consume the ten-minute handshake interval. This cannot override realm messaging restrictions; reports can still be copied manually.

# 0.6.34 — Explain blocked gift delivery

- Gift sending now reports the actual client/realm messaging restriction instead of a generic failure. Restrictions are respected; no blocked messages are sent.
- The local developer command now supports `/cf gift100 status`, which reports the pending recipient and transport availability without sending anything. Retrying preserves the original gift ID to prevent duplicate rewards.
- Improved handling of unavailable transport APIs, throttling, lockdown and unsuccessful send results. Delivery still requires a recipient acknowledgement.

# 0.6.33 — Forever developer identity fix

- Fixed developer gifting and error-inbox recognition when Forever returns first name and surname separately. War Lune is recognized without accepting a matching first name alone; realm, faction and restricted-value checks remain in place.

# 0.6.32 — Party pets, care and recovery

- Farmed pets now use one shared 5% result per creature in parties. Nearby addon users with stable room receive a copy; rarity rolls individually. Solo farming keeps its 5% base plus pet-drop talents. Raids are excluded. Hillsbrad Snapjaw is a supported source.
- Rest shows an energy countdown in Camp and the mini portrait. Hungry pets show that rest is paused.
- Tower healing works from care controls, queues for the next pet turn, and cannot charge at full health. Low-energy actions show error feedback. Level-ups fully heal, including during battle.
- The mini portrait remembers your large/compact choice. Escape closes addon windows, including the mini portrait; `/cf pet` restores it.
- Added eight small trainer racial passives, shown on Talents.
- Entirely empty stables can open a free recovery crate for a Common Wolf pup, Owl or Stonetusk Boar. Memorials count as occupied. Recovery pets earn retirement XP from trained levels, but no free starting-level or rarity XP.
- Added receipt of 100-token developer gift crates in the bag, with sender checks, acknowledgements, replay protection and bag-space checks. The public download contains no gift-sending developer command.

# 0.6.31 — Dungeon kill XP and optional error reporting

Includes the protected-tooltip fix from 0.6.30. Confirmed PARTY_KILL events in PvE dungeons/raids now award 1 pet XP when the required identity, level or party-range information is restricted. This fallback shares the normal six-XP-per-minute budget, works at the player level cap, uses the mini portrait's XP effect, and cannot award XP to dead or capped pets. It cannot distinguish gray enemies or elite bonuses when those details are hidden. Readable kills retain their normal difficulty/elite rewards and duplicate checks. Unknown but unrestricted levels still give no XP.

Dungeon kills retain the 3% base equipment roll independently of XP limits or an active pet. Readable enemies use their actual level; restricted kills in five-player dungeons use the player's readable level for gear rarity when the enemy level is unavailable. This exception never applies outside dungeons or to readable gray enemies. Fallback gear is marked as player-level-derived, without inventing NPC identities or specific pet drops. Standard herb rolls also remain available on eligible dungeon loot events.

Dungeon crates now accept the direct BOSS_KILL event as well as a matching successful encounter pair. Hidden boss names no longer block an otherwise verified encounter. Both event paths share the same saved boss cooldown, so they cannot double-award. The 20% crate chance and once-per-boss-per-24-hours rule are unchanged. Crates remain right-click-openable bag items, with waiting crates preserved if the bag is full.

Party/raid targets are sampled at kill time instead of relying only on the one-second observation tick. A restricted combat-pet GUID no longer blocks its readable owner's kills. An unavailable range check can use readable visibility; known out-of-range party members remain excluded. `/cf xp` explains the most recent kill check, pet cap and current six-XP budget.

Optional error reporting is available inside Settings and through `/cf errors on` or `/cf errors off`. New, distinct addon errors queue for War Lune on Classic Beta PvP 2 (Horde), with an acknowledgement before removal. Reporting starts off; both clients need the update. The receiver can read and copy reports with `/cf errors`. Errors include version, build, file/line and a short summary with quoted values redacted; no chat logs, locals, full stack dumps or save contents are sent. Character names are visible to the receiver. Storage, traffic and duplicate errors are bounded; turning sharing off clears pending reports. Normal error displays and other error handlers are preserved.

Automated tests cover restricted inputs, dungeon/party rewards, shared XP limits, report handshakes, offline queues, acknowledgements, spoofed/malformed traffic, repeated-error floods, public startup and security/performance. In-game two-player report delivery has not yet been verified.

# 0.6.30 — Protected tooltip GUID fix

Fixed the secret-string error when hovering creatures in the Forever client. Tooltip hooks now check whether GUIDs, tooltip data and unit tokens are readable before parsing, comparing or retaining them. Restricted creature information simply omits the companion farming hint; it does not fall back to another unit. Both modern and legacy tooltip paths are covered, including clients without secret-value APIs.

Regression tests and the full addon security/performance suite pass. Starter supplies, saved progression and public-build settings are unchanged.

# 0.6.29 — Public beta starter bundle

Fresh saves receive 100 tokens, 2 treats and 2 herbs. The starting tokens buy one Traveler's Adoption Crate. Existing pets, balances, supplies and progression are preserved; login and reload never repeat the bundle.

Map paws are smaller on zone, continent and world views, and no longer enlarge with map zoom.

The public package excludes developer grants, character-reset tools, Test Ding controls and faction-art previews. Includes the current 3D camp and tower, collection and farming, equipment and talent progression, in-window reward gains, nonlethal hunger and grayscale death effects.

Security/performance review: inspect messages reject restricted payloads and unsupported species. Equipment rendering builds one ownership lookup, resource counters avoid unchanged text writes, and native portraits refresh only when their model changes. Automated malformed-message, maximum-inventory, frame-reuse and public-package checks passed.

# 0.6.28 — Floor rewards without a victory panel

Removed the victory overlay from both tower views. XP remains over the pet. The large and compact windows now show animated token, treat and herb totals with green gain amounts; saved rewards are awarded once and never depend on animation. Use the floor arrows to move on, with no automatic fight start.

Dead pets fade to black and white in the arena and mini portrait. The tower backdrop also fades to grayscale, and the final pet remains visible after the last combat round. Living pets and new encounters restore color. Reduced motion skips the fade and count-up while preserving gain text.

# 0.6.27 — Rest and hunger in the mini portrait

The mini portrait now shows sleeping Zs and a red hunger pulse below 25 food. Reduced motion uses a steady warning. Rest restores energy only and automatically ends at full energy. Below 10 food, health and energy drain at one point per minute, stopping at 1; hunger no longer kills pets. Treats stop starvation and herbs restore health. Tower defeat remains permanent.

# 0.6.26 — Simpler companion care

Removed happiness, Play, toys and angry indicators. Camp now shows green health, orange food and yellow energy in both large and compact windows, with three care buttons. Existing toys refund 3 tokens each once on reload, up to the wallet cap. Pet levels, gear, talents and discoveries are preserved.

Thirty seeded progression simulations completed floor 100 using only Common pets and random level-30 mob equipment. The WoW character cap limits gear sources; addon pet caps still progress through talents. Timings include farming, care and battle presentation, with prompt healing and no offline advancement.

# 0.6.25 — Gentler mastery progression

Kept the first three talent points at 450 total XP and reduced the later quadratic cost ramp from 20 to 4. The level-80 pet cap now takes 21,036 total XP instead of 54,780; cap 100 takes 39,850 instead of 118,250. Completing all 40 talents remains a longer goal at 113,300 XP.

Existing earned XP and allocated ranks are preserved. On reload, the cheaper curve may grant additional unspent points and pet-level-cap unlocks. Retirement rewards, death penalties and tower combat are unchanged. The stable-full message now correctly allows retirement at any pet level.

# 0.6.24 — Retirement at any level

All owned companions, including level-one pets and memorials, appear in the Talents retirement list. A Retire button beside the Camp name opens the selected pet's reward preview and confirmation. Cancel leaves the pet untouched. Rewards show level XP, rarity, ten-level milestones, Mentor, the 50% death penalty and the rounded total before removal.

Rewards use 10 XP per pet level plus 10/30/50/70/100 rarity XP. Every ten levels adds another 25% of the level portion. Mentor applies before the death penalty. Existing trainer XP, allocations, level-cap milestones and the progression curve are preserved. Returned equipment still needs enough bag space; collection discoveries remain unlocked.

# 0.6.23 — Bag selection and Mini toggle

Equipped gear is back in a horizontal row above the backpack. Locked slots show only padlocks. Clicking a lock selects it without spending tokens; its price and Buy button appear below, replacing Equip/Sell until another item is selected. The gradual unlock pricing is unchanged.

Added a Mini toggle beside Compact in the large window to show or hide the floating pet. Its on/off label follows the floating window's own hide button as well.

# 0.6.22 — Expandable backpack

Equipment now has an 8 by 8 backpack with 20 free slots. Left-click any locked slot to purchase that exact slot permanently; every remaining lock shares the new price. Prices grow gradually (1, 2, 4, 7, 11, 16...), reaching 947 for the final slot and 14,234 total for all 44 upgrades. Hover a lock to see its token cost. Purchases persist per character and are blocked during battles or when funds are insufficient.

Item details, filters and Equip/Sell controls are below the bag. Worn gear appears beside the companion preview. Existing items are preserved: the first migration unlocks room for existing loose items up to 64, and legacy overflow remains reachable on additional pages. All loot, crates, unequipping and retirement checks use the unlocked capacity.

# 0.6.21 — Tower sides and token icons

Tower models now place your companion on the left and opponents on the right, facing each other with the corrected solid-model camera. All enemy unit frames stack in the right column; multi-enemy frames shrink slightly to preserve arena space in large and compact views.

Added a coin icon to token balances, crate prices, supply prices, gear sale prices, talent respec prices and tower rewards. Pet and gear rarity scaling is unchanged.

# 0.6.20 — Solid models and visible specials

Corrected the 3D camera's mirrored coordinate basis, which reversed face culling and made solid models appear hollow. Camp and other solo previews now aim at each model's normalized vertical center with a consistent gentle downward angle. The corrected camera applies to the tower, compact view and floating pet as well. Naturally translucent creature materials remain unchanged.

Pet Stats now displays the selected pet's rolled special abilities as icons: one for Rare and two for Epic/Legendary. Hover for the ability name, damage/healing/defense effect, shared three-round cooldown and activation guidance. These icons are informational and do not change the pet's rolls or trigger combat actions.
# 0.6.19 — Camp portraits, rotation and stat breakdown

Camp now uses a 3×3 portrait bag. Rarity colors the border; click a portrait to preview its model, then Equip to change your active pet. Hover for the name, rarity, specialty and equipped status. The stable limit is nine living pets. Existing overflow and memorials are retained on additional pages; new acquisitions stop until a living slot opens. Farmed pets can wait in the Collection log, and full-stable crates remain unopened without charging tokens.

Left-drag the model in Camp to rotate it. Rotation stays through redraws and resets when switching pets or entering the tower. Window movement still uses the surrounding window.

Pet Stats shows each base value plus effective gear bonuses in green and talent bonuses in blue, with the total on the right. Base includes level, family and rarity. Rounding and the 60% armor cap are reflected in effective contributions. Hit/miss chance and XP remain separate; battle values use the starting snapshot, with temporary effects listed below.

Below the pet and stats panels, five read-only equipment slots show the previewed pet's gear or empty slots. Hover for item details. Go to Equipment opens equipment management for your active companion; previewing never equips a pet or changes gear.

# 0.6.18 — Navigation, mastery and random specials

- Floating pet portrait resizes for the selected font, keeping rarity, level, XP and reward text in separate rows.
- Navigation is Camp, Tower, Equipment, Talents, Collection, Crates, Inspect. Crates has Pet/Gear subtabs. Settings uses a cog at the bottom-right of the large window and top of compact.
- Supplies open in an embedded tray with 1/5/10 purchases. Care icons still buy and use a single item when empty.
- Twelve talent nodes use 2–5 ranks, for 40 total points. Existing allocations are refunded once while earned training XP is retained. Level caps still unlock every three trainer levels, stopping at pet level 100.
- Lucky Find caps at a 1% single-tier upgrade chance. Scavenger caps at +1 percentage point (3% to 4%). Steady Income adds up to 30% online tokens; Tower Bounty adds up to 10% victory tokens, with saved fractional carry.
- Eligible green-through-red NPC kills have a 0.5% herb chance, up to 1.5% with Herbalist. Herbs use the existing mini-window/chat loot notifications.
- Rare pets receive one random special; Epic/Legendary receive two distinct random specials from six effects. Rolls persist, including a one-time assignment for existing pets. Specials share a three-round cooldown; healing remains manual. Family stat specialties are shown separately.
- Sharing defaults on once for existing saves and for new characters. Later opt-outs persist. Inspect and sharing controls remain available; protocol tests cover requests, replies, throttling and opt-out. Live two-player testing is still needed.

# 0.6.17 — Farm-target naming audit

- Corrected nine misleading regional pet labels to match their verified farm sources: Stonetusk Boar, Stranglethorn Raptor, Scorpid Terror, Stone Maw Basilisk, Wild Ram, Duskbat, Plaguehound, Chimaera Matriarch and Snapjaw.
- Snapjaw retains its verified Hillsbrad/Alterac farm hints; it no longer claims to be a Loch Modan turtle. Wild Ram distinguishes the farmable critter from the separate Ram companion variant.
- Audited all 88 farm NPC mappings against cached Classic names and Forever location samples. The incorrect labels, not the target NPCs or coordinate samples, caused these mismatches. Numeric species IDs, models, ownership and progression stay unchanged; old labels still work in collection search.

# 0.6.16 — Gray gear and boss rarity brackets

- Level 0–9 equipment is now gray or white, weighted 75% / 25% before talents. Gray gear grants half the Common bonus and sells for 1 token. Pet qualities are unchanged.
- Level 50–60 equipment stays blue–purple; purple–orange begins at 61. Every bracket uses descending rarity weights; higher tiers are always rarer. The base gear drop chance remains 3%.
- Recognized skull world bosses and boss-unit frames use level 63 for addon loot rules when no numeric level is reported, retaining that recognition through corpse metadata changes.

# 0.6.15 — Enemy-level loot and backpack crates

- Equipment stays at a 3% base drop chance, now restricted to observed green-through-red enemies. Rarity brackets advance at levels 10, 20, 30, 40, 50 and 60; Lucky Find cannot exceed the bracket. The kill-XP cap does not block gear rolls.
- Dungeon bosses again have a 20% chance to award an earned pet crate. Crates occupy backpack slots, persist through reload and open on right-click. Full bags hold the reward for manual claiming; shop and starter rules are unchanged.
- Tiny-window XP text renders above 3D models. Loot reveals wait for ordinary XP feedback as well as level-ups, including the first pet found.
- Added debug buttons for +1 pet XP, a dungeon crate, and current-session kill-loot counts. Existing progression and equipment are preserved.

# 0.6.14 — Mastery, paid boxes and fresh-start tools

- Nine distinct talent nodes: health, armor, poison/burn resistance, attack, retirement XP, a tiny one-tier rarity upgrade chance, speed, pet drops and equipment drops. Each node has three ranks. Old allocations refund once while earned training XP remains.
- Trainer XP costs accelerate after the first three points: 100 + 50L + 20 max(0, L-2)^2. First three points require 450 total XP; all 27 require 118,250. Every third level still raises the pet cap by 10.
- Online income is 2 tokens per five minutes, even with no living or equipped pet. Fresh characters start with zero tokens and starter care supplies. No free rescue or free crates; old crate entitlements no longer bypass purchase costs. Dungeon bosses grant tokens; matching raid pet drops remain.
- The Gear boxes tab sells six boxes for 300–9,600 tokens, three times matching pet-crate prices. Each grants one permanent random gear item using displayed base rarity odds. Full bags and combat block purchases before payment.
- Settings includes clearly labeled beta test controls for tokens, random pets and gear, trainer levels, pet level 10, care restoration and effect previews. Character reset keeps a backup and display settings while clearing progression.

# 0.6.13 — Companion rarity frames

- The tiny pet window shows the active companion rarity with a matching border. Loot reveals add a rarity label, border and colored glow.
- Camp companions show their rarity and a matching frame. Collection cards and the selected preview show the highest rarity ever found, retained after retirement; selection no longer replaces the rarity border.
- Existing collection records reconcile higher rarities from owned pets without lowering historical records.

# 0.6.12 — Rarity colors and bag labels

- Chat loot alerts color the rarity and reward name using the same rarity colors as the collection and equipment. Stats and navigation text keep their normal color.
- Occupied bag slots show a matching colored rarity label below the icon, alongside the existing colored border and NEW marker.

# 0.6.11 — Loot alerts and new-item markers

- Item and companion rewards now reveal an icon with a pulsing glow inside the tiny pet window instead of a separate popup. Queued loot waits for a level-up animation; Reduced motion uses a static reveal. Hover the pet window to read the last reward.
- New gear and companions retain NEW markers through reloads. Hover/select gear or equip it to clear its marker; select a companion or its collection portrait to mark it seen. Camp, Collection and Equipment tabs point out unseen rewards; waiting pets remain marked in Collection.
- Local chat announces each item or companion acquisition with its details, including when the tiny window is hidden. Old saves are not announced again.

# 0.6.10 — Tiny pet window level-up effect

- The floating pet window now plays the native gold 3D effect for real level-ups and Test ding previews, even with Camp and Tower closed.
- Effects expire, share one sound with other views, and respect Reduced motion. No progression changes.

# 0.6.9 — Level-up animation preview

- Added a Test ding debug button inside the Camp and Tower scenes in both window sizes.
- Replays the existing gold 3D level-up effect, arrow and sound using a separate temporary preview. The small portrait also marks the preview. Pet level, XP, rewards and the kill-XP budget remain unchanged.
- Real XP takes priority over a preview. Repeated previews restart the effect, expire automatically and respect Reduced motion.

# 0.6.8 — Elite kill XP bonus

- Elites and rare elites add 1 pet XP to their normal green-through-red reward. Elite totals are green 2, yellow 3-4, orange 4-5 and red 5-6.
- The bonus is included in the shared 6 XP per minute cap. Gray enemies still grant no XP; ordinary rares do not get the elite bonus.
- Readable elite status is cached with the enemy's level so corpse metadata changes do not remove the bonus. Restricted or unknown classifications do not grant a guessed bonus.
- Regression checks cover both elite types, all color ranges, gray exclusion, ordinary rares, restricted classifications, corpse changes, duplicates and partial awards at the cap.

# 0.6.7 — Difficulty-based kill XP

- Green enemies award 1 pet XP; yellow roll 2-3, orange 3-4, and red 4-5.
- Personal, combat-pet and nearby group kills share the existing 6 XP per minute cap. A reward that would cross the cap is reduced to the remaining budget.
- Removed the five-level cutoff so all observed, non-gray difficulty bands can qualify. Unknown or restricted levels still cannot grant XP; loot rules are unchanged.
- Tested color boundaries, both ends of every random range, partial rewards, mass pulls, duplicate kills and the next minute's budget.

# 0.6.6 — Visible XP on the screen portrait

- The small movable pet portrait now includes an XP bar and exact XP total, plus an in-frame XP gain and level-up message. Previously, XP could be awarded correctly while this portrait showed only the pet's level.
- Confirmed a real level-25 Elder Gray Bear kill on a level-30 player increased pet XP from 24 to 25 while player XP stayed unchanged.
- Existing rewards remain 1 pet XP per eligible kill, up to 6 per minute. No saved pet progress is reset.

# 0.6.5 — Pet farming map

- Added a saved Pet locations checkbox to the world map, with light green paw prints for verified addon pet farms.
- Includes 136 approximate coordinate hints across 38 zones, with pet names, source creatures, drop chances and collection status on hover. Pins follow map navigation and supported parent-map projections.
- Only audited kill sources with known coordinates appear. Crate-only pets and instance hints without coordinates are omitted. Retired discoveries still display as collected.

# 0.6.4 — Creature tooltip pet markers

- Hover a verified pet-drop creature in the world or on a unit frame to see its Companions Forever pet name, 5% chance per eligible kill, random rarity, and collection status.
- Markers use the exact same NPC IDs and Classic/SoD allowlist as kill rewards. Unrelated creatures and crate-only model references are not advertised as pet drops.
- Retired pets still count as collected. Supports both Classic unit tooltip hooks and the newer tooltip data API without duplicate lines.

# 0.6.3 — Verified Forever and SoD pets

- Tested 40 exact display IDs and portraits in Forever 1.60.1 build 70205 on October 4, 2026. Idle, attack, run and cast API calls completed; animation variety depends on each model.
- Added 29 named entries and re-enabled 4 existing entries, bringing the allowed collection to 311. Existing IDs and discoveries remain stable. Seven tested entries were already allowed; their references were checked or updated.
- Includes Baby Crocolisk, Excitable Slime, Musical Gustjumper, Spawn of Grubthor, Coldrasp, Skeletal Wind Serpent and Explorer Imp.
- Added source notes that distinguish real-game acquisition from addon rewards. New additions are available from addon crates; no unverified kill farms were enabled. Existing kill farms retain their 5% chance.
- No extra model assets are bundled. The client supplies the models and portraits.

## 0.6.2

- Restricted models to an explicit Classic/SoD allowlist: 278 exact Classic display matches in this build. SoD-only additions require verified references.
- Collection, crate rolls, rescues, kill drops and tower opponents respect the roster restriction.
- Unsupported saved pets/finds are archived; discovery history and gear are retained.
- Corrected Treant and Air Elemental to Classic models.

# Companions Forever 0.6.0 beta


## 0.6.1

- Rebuilt mastery as a connected, three-branch talent tree with ranked icon nodes and visible level-cap milestones. A confirmed 25-token reset refunds spent points and preserves trainer XP and level-cap unlocks.
- Restored both faction camp/tower backgrounds in large and compact views. Static native pet portraits remain; old pet sprite art is not packaged.
- Rebuilt equipment storage as a compact 30-slot backpack with native slot trim and hover tooltips. Right-click equips; equipped gear is hidden from the bag and frees capacity. Right-click a worn item to unequip. Full-bag swaps are allowed when no extra slot is needed; unequipping and retirement check return space first.
- Audited the experimental roster: 88 Classic kill NPCs award 83 species. Removed unverified expansion wild-pet and protected NPC kill mappings. The collection has Farmable, Crate only and Experimental filters, plus searchable zone hints from the installed Forever QuestieDB 1.0.4 snapshot. Coordinates are approximate patrol/spawn samples, not guarantees that an NPC is currently alive.
- Species IDs, discoveries and existing ownership are preserved. A model's availability does not imply a killable world spawn; Durotar Scorpion is crate-only in this build.

- Static native creature portraits replace AI images; package no longer includes generated art.
- Experimental 2,318-entry cross-expansion roster, preserving original species IDs. Sixty-five unmapped source records are excluded; unavailable modern models use family fallbacks after detected load failure.
- 30-slot equipment bag with native-style hover details, rarity borders, equipped markers and token sales. Existing overflow is preserved.
- Talents tab with permanent retirement, retained collection discoveries, returned gear, trainer XP and pet-level cap milestones from 10 to 100.
- XP bars, level arrows and native gold level effects inside both tower views; XP/level effects around the camp pet.
- Kill-based XP works without player XP gains, including nearby group members and pets: 1 XP per eligible kill, maximum 6 per minute.
- Four randomized combat styles, no consecutive automatic guards, manual healing unchanged.

# Companions Forever 0.5.1 beta

- Recommend `/companions` in login hints, portrait tooltips and guides to avoid the Hermes `/cf` command conflict. Existing aliases are retained.

- Increased matching NPC companion drops from 2% to 5%. Equipment remains 3%.
- Rarity remains Common 50%, Uncommon 30%, Rare 15%, Epic 4%, Legendary 1% after a successful pet drop.

# Companions Forever 0.5.0 beta

- Unified Camp, Collection, Equipment, Tower, Crates, Supplies, Inspect and Settings as tabs in one main window.
- Searchable collection grid with scrolling, gray undiscovered portraits, rarity borders and an inline 3D preview/source panel.
- Five equipment slots: Weapon, Head, Body, Collar and Trinket. Added six head/body items; retained all nine original item IDs and bonuses.
- Migrated equipped fangs to Weapon and charms to Trinket, preserving item ownership and inventory.
- Darker panels, quieter borders, compact crate/supply cards, scrolling equipment inventory and clear empty states.
- Main-window navigation closes the optional compact view; existing slash commands open the corresponding tab.

# Companions Forever 0.4.0 beta

- Personal kills can drop matching companions from assigned NPC sources (2%) and equipment (3%), with independent rarity rolls.
- Collection log lists all 100 current species, collected/missing filters, assigned sources and waiting finds.
- Fang, collar and charm equipment slots add real combat stat bonuses. Nine item types, five rarities, one owner per item, no mid-battle swaps.
- All six adoption crates include all 100 species. Token costs: 100 / 200 / 400 / 800 / 1,600 / 3,200. Earned dungeon crates still open free.
- Animated item/pet finds, XP, level-ups and crate opening/reveals, with Reduced Motion support.
- Updated herb icon and supply icons. Existing pets and discoveries migrate without a reset.
- This pass covers collection and loot. Full-roster expansion, PvP, pet trading, collection inspection and ignore/review tools are not included yet.

# Companions Forever 0.3.0 beta

- Native 3D creatures replace the sprites in camp, both tower views, the stable and the draggable pet portrait.
- All 100 species have client model mappings; custom/regional names use matching creature variants.
- Short, size-aware attack steps and wider enemy spacing reduce overlap. Attacks, casts, hit reactions and deaths use native animations.
- Health changes appear at impact. Both tower windows follow the same playback clock; hiding or pausing a battle freezes that clock.
- Larger scene areas leave room for models below the health frames. Sprites remain a fallback when a client model cannot load.
- Existing saves, pets, XP, supplies, tokens and progression are retained. The separate 3D test addon remains independent.

Install both included folders and reload the UI. Creature-specific animation support and custom-client model differences may vary.

# Companions Forever 0.2.0 beta

- Draggable minimap launcher on the minimap rim, drawn above its artwork.
- Independent equipped-pet screen portrait with saved position and a hide button. Restore using `/cf pet` or Settings; `/cf reset` resets all positions.
- Separate combat stat rows, hit/miss chances and active effect durations.
- Steeper tower progression and partial scaling toward overleveled pets, including replays. Enemy stats stay fixed during a fight.
- Both sides can miss. Enemies gain poison, burn, freeze and attack-slow spells from floor 5. Guard blocks new effects; healing remains manual.
- Kill-XP compatibility fixes for missing optional level APIs, disappearing corpse levels and combat-pet targets. Existing eligibility, duplicate and rate limits remain.
- Existing pets, levels, supplies, tokens, memorials, completed floors and save migration are preserved.

Install both included addon folders over the existing installation and restart the client. Do not delete your saved variables. Automated tests cover combat, progression, XP and UI handlers; live client layout and event delivery still need in-game verification.

# Companions Forever 0.1.1 - beta

Renamed from Forever Companions. Windows, tooltips, minimap access, folders and saved variables now use Companions Forever. Open with `/cf` or `/cf small`; `/fcp` still works.

Extract both folders from the ZIP and replace the old TOC. Restart WoW with the main addon and its saved-data compatibility entry enabled. Existing standalone pets and settings are copied once into the new save, while the original is retained. If migrating from the combined Waylaid addon, also install the updated Waylaid Forever package. See README.md for migration details.

The 100 creatures, adoption crates, care system, opt-in inspection and tower balance are unchanged. This remains beta, not 1.0.
