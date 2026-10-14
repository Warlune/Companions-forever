# Companions Forever: Pet Battles & Adventures — 1.3.3

A standalone companion game for WoW Forever. Collect creatures, equip and care for them, and climb a 100-floor tower with native 3D models and animations.

## New in 1.3.0: Housing (beta)

Open Housing in the main addon window to decorate and expand your island. Up to three resident pets can work at placed workstations or join expeditions. Discover furnishings through exploration, progression and furniture crates. Work continues for up to eight hours offline; collect waiting rewards with Claim all. Housing pets are unavailable for tower battles until returned to the stable.

Check Mail for the housing announcement and three free Furniture Crates, claimable once per ruleset, shared across characters in that ruleset. Gifts already received in a ruleset stay claimed. Housing and the addon are still in beta, with more updates and adjustments to come.

Housing settings include background opacity and an instant 30/60 viewport update rate. This controls housing updates; WoW controls native model rendering.

## Install

Extract the single `CompanionsForever` folder from the ZIP into `World of Warcraft/_classic_beta_/Interface/AddOns`, then restart WoW and enable Companions Forever. No other folder or addon is required. If another addon is named `ForeverCompanions`, keep it unchanged; do not overwrite or rename it.

This release targets WoW Forever 1.60.1 (Interface 16001). Other WoW clients are not validated by this release.

## Shared saves and Mail (1.1.24)

Characters on the same WoW account and realm now share one adventure. Log into each existing alt once to merge its pets, equipment, unopened crates, collection and achievements. The highest token balance and progression are kept, not added together; talent allocations come from the save with the most earned points. Other realms/rulesets stay separate. Character-specific window positions stay local.

Overflow pets, gear and crates wait in **Mail** with no expiry. Pets retain their rolls, abilities and equipped gear. The Mail button is available in large and compact views, or use `/cfpets mail`. Make room and collect each delivery once. New earned overflow has room for 200 deliveries; migration overflow is preserved even if it exceeds that limit. Purchased crates and achievement rewards still wait for bag/stable space before claiming.

Old character saves are backed up and imported only once. A pending trade must finish on its original character before another alt can use the shared game. Mail is a small inbox inside your current large or compact view: click **Mail** again to close it. Announcements, gifts, waiting pets and overflow deliveries share this inbox; it has no sending controls. **Delete mail** removes attachment-free letters and stays disabled while rewards are attached. Collected deliveries disappear automatically. Deleted letters stay deleted after reloads and alt-save merges. Read the account-sharing letter through Settings > About account sharing or `/cfpets merge` before deleting it.

## Your first pet

Fresh saves start with **100 tokens, 2 food and 2 herbs**. Open `/cfpets`, select **Crates > Pet**, and buy the 100-token Traveler's Adoption Crate. Your first living pet equips automatically. Existing saves retain their balances and progress; restarting never repeats the starter bundle.

Use **Camp** to view and rotate your pet, inspect stats and equipped gear, or select a companion from the nine-pet stable (16 slots permanently unlocked after normal floor 100). Food restores 35 hunger points and 10% maximum health; herbs restore 40% health before racial bonuses. Rest restores energy first, then heals 1 actual HP every 5 seconds until both health and energy are full. Healing requires food at least 10 and no tower battle. Hunger can drain health and energy to 1 but cannot kill a pet. Tower defeat is permanent.

## Play and collect

- **Tower:** 100 floors with stronger encounters and bosses. Choose a fighting style and start each fight manually. Click Heal for an instant herb heal without spending an attack turn. Healing and control specials have separate buttons: left-click to queue, right-click to toggle automatic use. Multiple-enemy floors also offer target tactics. XP appears over the pet; token and supply gains appear beside their totals. Dead pets fade to grayscale.
- **Hard Mode:** Clearing normal floor 100 permanently unlocks a second 100-floor tower and a 4x4 stable. Deploy three living level-75+ pets, choose tactics and target heals. Exclusive gear speeds up raising replacements, including level-1 pets. Hard-mode training offers 15 four-rank talents, but only 16 points to spend across combat, care, farming and unusual utility bonuses. Respec costs 500 tokens; purchased points can be reassigned free. Normal mode remains available for raising new pets.
- **Equipment:** Regular items and 45 hard-mode set pieces across Weapon, Head, Body, Collar and Trinket slots. Drag to rearrange items in persistent bag slots or to equip matching gear. Right-click also equips; hover for stats or sell unwanted gear for tokens. Coin pouches and XP Treats stack to 30 per type and rarity. The 8x8 bag starts with 20 unlocked slots; buy additional slots individually.
- **Talents:** Retire pets at any level for trainer XP; at trainer level 40, retirement gives a modest token reward capped at 30 instead. Level, rarity, milestone bonuses and death penalties affect the reward. Retirement returns gear and keeps collection discovery. Every third trainer level raises the pet level cap by 10, up to 100.
- **Collection:** Native portraits, highest discovered rarity, farm hints and approximate map locations. Supported source creatures have a 5% base pet drop chance. Rarity is rolled separately. Model availability alone does not mean a creature can be farmed.
- **Loot:** Observed green-through-red enemy kills have a 3% base equipment chance. Eligible kills also have a separate 1% equipment-crate chance (Adventurer, Veteran, Champion or Azeroth). Unopened crates go into the bag and use their shop-box rarity odds when opened; in active Hard Mode, Common and Uncommon results are removed and gear containers have a tiny Mythic chance. Pet containers still top out at Legendary. Enemy level limits direct gear rarity; only in five-player dungeons, hidden enemy levels fall back to your character level. Eligible kills can also yield herbs and have a separate 2% chance of an XP Treat. XP Treats grant 25 / 50 / 100 / 200 / 400 flat pet XP by rarity, separately from food used for feeding. Dungeon bosses have a 20% bag-crate chance, once per boss per 24 hours, through either a successful encounter or direct boss-kill event. Player level caps do not block pet kill XP, which is limited to 12 base XP per minute before hard-mode gear bonuses; hidden PvE instance kills give 1 XP within that same limit.
- **Inspect and trade:** Browse shared living stables, models, rarity, stat totals and abilities. Unlocked stables show 16 pets in the same panel space. Pets become soulbound at level 11, and all hard-mode set gear is soulbound. Bound gear can still move between your own pets. Received pets unlock your collection; the sender keeps their discovery. Both players need 1.1.27 or newer for new trades; older pending trades retain their recovery path. Permanent asset IDs and saved receipts detect known conflicts but cannot prove that client-generated rewards were earned.
- **Tokens:** Earn 2 tokens per five minutes online, plus tower, sales and eligible boss rewards. All tokens, pets, gear and supplies are virtual addon items; no real gold is spent.

The main window, compact window and movable mini portrait share your pet. The mini portrait shows XP, loot, sleeping Zs and a hunger warning. Settings includes font size, window scale, High Contrast, Reduced Motion, and optional purple Hard Mode appearance. High Contrast takes priority over the theme and makes reward and unlock text readable on solid dark backings. Unlock animation replay is available after normal floor 100. The public release contains no sandbox pets, unlocked test floors, or developer grant/reset controls.

## Nearby players and combat feedback

Inspect has Guild, Party, Raid and World checkboxes. World discovers nearby friendly players and recent Trade/Global speakers. It only lists confirmed addon replies and never sends ordinary chat messages. Discovery uses at most six checks per minute total; channel speakers are checked at most twice per minute, only within five seconds of speaking, with no retry of the same name for ten minutes. A rejected channel-discovery send pauses channel checks for ten minutes. Chat contents are not stored. Both players need sharing enabled; turning World or Sharing off stops discovery.

Tower enemy health bars are red for Normal, gold for Elite and silver for Rare. White damage numbers appear on enemies, red negative damage on your pets, and green numbers show healing. Hover debuff squares for effects and remaining turns. Heal also works between fights. New achievements and frames keep a NEW label until you select them. Rare+ pets can roll from 38 abilities; existing pets retain their learned specials.

## Commands

Use `/cfpets` as the main command. `/companionsforever` also works. Legacy `/companions` and `/fcp` macros still work, but `/cf` is no longer registered because other addons use it. Chat messages are labeled `[CF Pets]`.

| Command | Action |
| --- | --- |
| `/cfpets` or `/companionsforever` | Open the main window |
| `/cfpets small` | Toggle compact view |
| `/cfpets pet` | Toggle the mini portrait |
| `/cfpets collection` | Open the collection log |
| `/cfpets gear` | Open equipment |
| `/cfpets trade` | Open trade offers and pending delivery |
| `/cfpets settings` | Open settings |
| `/cfpets errors` | Open the local error log and received-report inbox in Settings |
| `/cfpets errors on` / `/cfpets errors off` | Enable/disable automatic error reporting |
| `/cfpets xp` | Explain the last kill XP check and current 12-XP budget |
| `/cfpets reset` | Reset window/icon positions only; preserves progression |

Drag the minimap paw to reposition it. Drag the mini portrait to move it, or use its minus button to hide it. The main and compact windows also have Settings cogs.

## Trading

Open **Inspect > Trade** or **/cfpets trade**. Your offer and the other player's offer are each a **3x3 bag**. Your existing equipment bag and pet stable sit beside each other on the same page. **Right-click** an item, unopened crate or eligible living pet to add it; right-click your own offered slot to remove it. Hover any slot for its full details and rarity. Bag locks match Equipment; unlock more space there.

Select a player in **Inspect**, then click **Request trade**. Alternatively, target the recipient and use **Request target** on the Trade page. A matching connection reply is required before any assets are held. The recipient gets a small invitation with **Join trade**, **View offer** and **Decline**, a sound and a chat alert. Clicking the Mini alert opens Trade directly. A prepared offer opens for review before joining. Joining never confirms: both players must receive and review every slot, wait **three seconds**, and press **Confirm**. Every offer change clears confirmations and restarts the review countdown once the complete new offer arrives. Invitations expire after two minutes; declining or expiring sends a cancellation to the requester. If disconnected, reopen Trade when both players are online to finish cancellation or delivery.

Each side supports up to **nine mixed assets**. Trade living inactive pets with no worn equipment, loose gear and unopened bag crates. Free recovery pets cannot be traded. Received pets must fit your level cap. Pet discovery stays in the sender's collection. Offered assets are held outside usable inventory and their space is reserved; they cannot be sold, retired, used or offered twice.

If interrupted, reopen Trade and use **Retry delivery** when both players are online. Cancellation may also need the other player online. Once committed, a trade must finish delivery and cannot be refunded. Older single-asset pending trades can still be retried or cancelled. Do not restore an older save to clear a pending trade.

Both players need the **current compatible ability and soulbinding catalog** for new trades; older pending trades remain recoverable. The realm restriction flag alone no longer blocks a connection check: active chat lockdown and actual send errors are respected, and a real reply is required. This is a local-save system, not server-authoritative ownership. Retries and normal saved reloads are protected; edited/restored saves and crashes before saving cannot be made fully atomic. Live two-player verification is still needed.

## Upgrading and feedback

Replace only the `CompanionsForever` addon folder when upgrading. Existing Companions Forever saves are preserved. The obsolete `ForeverCompanions` compatibility folder is no longer distributed; never delete or replace an unrelated addon with that name. A previously installed genuine compatibility loader can still import early saves, but is not needed for current saves. An older Waylaid stable is imported automatically when no Companions Forever character save exists. Once account sharing is active, Settings explains the merge instead of replacing the shared game. Conflicting saves pause migration and remain backed up.

Include addon version, WoW build, steps to reproduce and any Lua error when reporting an issue. Native model appearance and availability depend on the client. See `PET_GUIDE.md` for detailed rules and `RELEASE_NOTES.md` for changes.

**Settings > Chat** has two switches: **Announce drops in party chat** (off by default) and **Receive CF guild messages** (on by default). Only pets and gear from world/dungeon drops and opened chests are shared quietly with updated CF guild members; there are no automatic public guild-chat sends. Turn guild receiving off to hide other guild members' notices. Your own reward messages and party notices remain visible. Party announcements use public party chat when enabled and permitted, otherwise updated party members receive quiet CF notices. Names keep their rarity colors, and gear names can be hovered to see stats and effects. Crates, furnishings, supplies, coin pouches and XP Treats are not shared. Chest sharing starts when opening succeeds; your local reward text waits for the reveal. Achievement rewards stay local. These notices never grant another player the announced reward. Both players need an updated CF build.

Coin bags and XP treats are excluded from outgoing announcements and incoming CF notices, including notices sent by older builds. Your own reward messages still show.

Chat settings show whether WoW accepted or rejected the last announcement for each route. Acceptance is not confirmation that another player received it. Temporary addon throttling or lockdown failures retry at most five times, with a 60-second expiry. Share party prepares your last announcement in native party chat; review it and press Enter to send. No test messages are sent by opening settings. An existing CF-message opt-out carries over to guild receiving.

Equipment hover comparisons show the hovered item and the active pet's matching equipped item in separate panels, with signed item-stat changes. Normal equipment shares a rarity-scaled stat budget: 4 health equals 1 attack, armor or speed; special effects use part of the budget. Existing items keep their identity and gain the revised stats automatically. Hard-mode set stats are unchanged.

**Settings > Error reports > Share errors with War Lune** sends new, distinct Companions Forever errors to **War Lune on Classic Beta PvP 2 (Horde)**. Both players need this version and must be online on the supported realm/faction. Error reporting defaults on, including a one-time migration for existing saves; an explicit subsequent opt-out remains saved. Reports contain version, client build, addon file/line and a short error summary with quoted values redacted. Your character name is visible to the recipient. No chat logs, locals, save contents or full stack dumps are collected. Reports from other addons are ignored. The normal WoW error display and existing error addons continue working.

The automatic delivery test has ended. Updating removes its queued and received test entries; real Lua errors still use the normal reporting system. Tests received from older clients are acknowledged quietly without appearing in the error inbox.

At most 30 distinct local errors and 30 queued reports are retained for seven days; repeated errors increment a bounded count instead of generating more reports. Pending reports remain queued until acknowledged. The addon checks for the receiver once per ten minutes after an accepted probe while reports are waiting, with one retry after ten seconds for a lost reply (failed sends may retry after 30 seconds) and sends at most one report per 30 seconds. Turning sharing off clears unsent reports. The account-wide receiver inbox holds at most 100 reports for seven days; use **Select / copy**, then Ctrl+C, to copy it. Delivery is best effort, and received reports are player-supplied diagnostic claims.

Addon code is MIT licensed; see `LICENSE`. Warcraft assets remain the property of their respective owners.

## Recovery, care and trainer racials

An entirely empty stable can use **Crates > Pet > Free recovery crate** for one Common Wolf pup, Owl or Stonetusk Boar. Dead-pet memorials count as stable records. Recovery pets award no retirement XP at level 1 and no rarity bonus; trained levels and applicable milestone/mentor bonuses still count.

Rest restores energy first, then heals 1 actual HP every 5 seconds at full energy. Camp and the mini portrait show the energy countdown or healing phase. Feed a hungry resting pet to resume recovery. Level-ups fully heal health. Herbs cannot be bought or consumed through Heal at full health; in the tower, healing applies immediately without spending an attack turn, including while paused. The mini portrait opens your last large or compact view. Escape closes the large and compact windows but keeps the mini portrait visible. Its yellow energy bar appears below XP. Only its hide button or explicit toggle saves a hidden preference; reloads and instance transitions preserve your choice.

| Character race | Trainer passive |
| --- | --- |
| Human | +1% trainer XP |
| Orc | +1% pet attack |
| Dwarf | +0.5 percentage points armor |
| Night Elf | +1% pet speed |
| Undead | Herbs restore 2 extra percentage points of health |
| Tauren | +1% pet maximum health |
| Gnome | +2% online token income; fractions accumulate |
| Troll | +2% resting energy recovery |

Stat racials are included with the blue talent contribution. Unsupported races receive no racial bonus. A developer-sent **100 Token Gift Crate** occupies a bag slot; open it from the bag to receive 100 tokens. Sender and recipient both need this update. The public version can receive gifts but contains no developer sending tools.

Diagnostics uses an actual send and receiver handshake instead of treating the realm restriction flag as a blanket block. Active messaging lockdown is respected. Failed connection sends retry after 30 seconds; accepted but unanswered probes remain limited to one per ten minutes. Reports stay queued until War Lune acknowledges them. Settings shows send failures and connection status. Reporting defaults on for new players; saved opt-outs remain off. Recent local errors are queued once when error sharing is enabled, with existing size and seven-day retention limits. Both players still need to be online on the configured realm/faction. Use **Select / copy** for manual reports when delivery is unavailable. Only Companions Forever error summaries are collected.

## History checks

In **Inspect**, hover the history status for an explanation and the selected pet's recorded origin. **My history** shows your own accounting status and recent token changes; click it again to return to the selected player's status. Inspect target requests a fresh peer checkpoint while Sharing is on.

**No known conflicts** means the available records agree. **Limited history** means earlier records are unavailable, including older saves, first encounters and gaps beyond the proof window. **History conflict** explains a specific disagreement; it does not label anyone a cheater. A restored save can also cause a disagreement. Missing history does not block normal play or trading. A specific asset that contradicts an existing receipt cannot be traded until the conflict is resolved; the item is kept.

Token sources and spending are recorded in a bounded chain. Purchase and crate-origin receipts stay attached through trades, and peers can compare recent history against checkpoints they previously saw. These are consistency checks, not authentication: someone controlling their addon and save can still fabricate plausible history. There is no public reputation score, voting, gossip network or external blockchain.

## Collections, achievements and frames

Open **Collection** for four sub-tabs. **Pets** lists normal companions whether found or missing, plus secret companions only after discovery. **Achievements** offers 75 challenges with one-time token, crate, pet and frame rewards. A few secret pets come from accessible exploration and retirement goals; most belong to long-term challenges. **Frames** selects the cosmetic border around your Inspect pet preview.

There are 20 frame styles, including 10 illustrated borders with leaves, lava, shadow, frost and other themes. The illustrated frames are completely absent from the gallery until earned; their achievement reward previews show a question mark. Secret pet rewards also hide their identities. Once discovered, secret pets remain in Pets after retirement or trading, but do not count toward the normal 311-pet total or enter ordinary drop/crate pools.

Bigger milestones can award tokens, a secret pet and a frame together. If the whole reward cannot fit, it waits for bag/stable room or wallet space. Previously claimed achievements offer **Claim bonus** for newly added rewards, without repeating the challenge or paying old rewards again. Earned frame IDs and existing progress are preserved.

Long-term feats track readable personal/nearby-party creature kills, your actual WoW companion book, outdoor exploration, tower clears and training. Kill/visit tracking began in 0.6.51; restricted identities and unavailable book data are ignored safely. Achievement icons stay gray until completion. Update both players to 0.6.53 for new secret pets and illustrated frames in Inspect and trades; older Inspect formats are retried automatically.

## City rest, PvP recovery and interface updates

Your active pet automatically rests in cities and inns when energy or health needs recovery, using the existing 25% rested-area energy bonus. At full energy, rest heals 1 HP every 5 seconds; fully recovered pets wake. Tower battles are not interrupted. Clicking Wake keeps the pet awake for that visit.

Credited enemy-player PvP kills restore 10% maximum health, 5 food and 10 energy to the active living pet, including at the level cap. A saved PvP kill count appears on Achievements. The same opponent has a five-minute recovery/count cooldown, preserved across reloads.

Only the large window fades while moving with the cursor outside it; hovering anywhere over it or stopping restores opacity. Achievements has All, Completed and Closest sorting. Hovering bag equipment compares its item stats with the active pet's equipped item in that slot.


### Tower rewards and chest reveals (1.1.1)

A clear shows token, supply, gear and crate rewards in the middle of the battle scene, then selects the next floor. Press Fight when ready; it does not automatically start combat or switch into Hard Mode at floor 100. Crate purchases and bag-crate opens show a native chest opening with the rolled reward rarity as its glow. The animation never changes the roll or grants a second reward.


## Adventure achievements (1.1.15)

30 new challenges bring the total to 75: six PvP milestones, five jumping milestones, nine exploration goals and ten dungeon goals. Easy challenges give tokens; medium challenges give tokens and adoption crates; the hardest give tokens and one of six hidden Epic companions. No new frames were added. Rewards are claimed once per shared realm adventure and stay waiting when the bag, stable or wallet is full.

Existing tracked PvP kills and zone visits count. Jump and dungeon tracking starts with this version. Jumps require a jump command followed by a takeoff; swimming and flying do not count. Dungeon completion means a recognized final boss defeat or a complete client encounter checklist after a confirmed boss kill, not merely entering an instance. Boss notifications are deduplicated; repeat clears of the same instance map have a five-minute cooldown. Raid bosses do not count toward dungeon achievements.

Forever final-boss fallbacks cover Hall of Thanes, Ruins of Lordaeron, Excavation Site: Wetlands and City of Dalaran. The other named Forever dungeons use the client encounter checklist when available. Unreadable or unavailable completion data does not award a guessed clear. Name-based fallbacks currently use English client names.

In Talents, scroll the retirement stable with the mouse wheel or scrollbar. A gold frame highlights the selected pet; locked pets remain gray and cannot be retired. The panel keeps its original size and works with both 9- and 16-pet stables. Both trading players should update for the new secret pet catalog.
