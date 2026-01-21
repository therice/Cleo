--- @type AddOn
local _, AddOn = ...

AddOn.Changelog = [=[
2026.1.4 (2026-01-21)
* minor changes to loot allocation and unit names with respect to realms 920a6a6

2026.1.3 (2026-01-17)
* address issues with realm name not being properly set when player is in guild but from different realm 02dc748

2026.1.2 (2025-12-18)
* /named/name/g to resolve issue with map not being found for Throne of Thunder 719c3ea

2026.1.1 (2025-12-11)
* remove thunderforged variants of tier, these are not applicable 32393dd

2026.1.0 (2025-12-08)
* Add support for Throne of Thunder, MOP Phase 3 9d1d2eb

2026.0.10 (2025-10-02)
* Cleanup changes related to master loot to use declared constants rather than inline literals 40181d5

2026.0.9 (2025-10-02)
* Correct issue with master looter being changed to enum instead of strings 6601201
* Fix failing tests to due GetLootMethod changes 6135e18
* Fix linting issue with change 052a55f

2026.0.8 (2025-10-01)
* Add support for multiple realms to list configurationa and priorities 010e96f

2026.0.7 (2025-09-23)
* Add support for MOP Phase 2 df40ab7

2026.0.6 (2025-09-20)
* Very minor change to logging which could result in errors under very specific (and rare) conditions 9881b7c

2026.0.5 (2025-09-07)
* Address edge cases where list priorities may not be adjusted correctly beb4074

2026.0.4 (2025-09-03)
* Address non-deterministic transmission of required data for configuration activation and neuter LibGuildStorage 9507c69

2026.0.3 (2025-08-26)
* Misc changes including changing terms used on loot screen and correcting what weapons can be used by Monks d8ca4f5

2026.0.2 (2025-08-11)
* Game version is 'mists', not 'mop' 626e53e

2026.0.1 (2025-08-11)
* Update packager to MOP from Cata b6c6670

2026.0.0 (2025-08-11)
* Update TOC for Mists of Pandaria a9613e8
* Update versions of actions f9d8838
* Add Monk 5157096
* Add MOP Phase 1 Encounters 305d0f2
* Add T14 items 62130da
* Add test items for MOP Phase 1 990378b
* Additional logging to assist with any issues that may arise during raid testing fcd7e1c
* Fix incorrect item number for Gauntlets of the Shadowy Conqueror (Paladin, Priest, Warlock) 
* Hide non-preferred types of armor by default in loot window 8f5e4c9
* Remove Thrown and Relic item types 49e7fd9

2025.0.22 (2025-02-18)
* Add additional images for documentation da93131
* Add license f67b4fc
* Add more detailed README b4c63c1
* Update for Dragon Soul (TOC and Items) 5baab57
* Actually update TOC for Dragon Soul game version 77c68e6
* Add Dragon Soul encounters 83e8544

2025.0.21 (2025-02-15)
* Correct tokens and add support for uploading to Curseforge 8248e84
* Update TOC with CurseForge Project ID 5b83110
* Publish to CurseForge ccc0d47

2025.0.20 (2025-01-12)
* Address potential issue with corrupted Raid Audit records 81660a1

2025.0.19 (2024-12-16)
* Address issues with retry via LOOT_READY and LOOT_OPENED a858af0

2025.0.18 (2024-11-28)
* Attempt to address issues with LibWindow by incrementing version 0776952

2025.0.17 (2024-11-26)
* Fix race condition with logging on login. Fix issue with Replication interface being incorrectly referenced. 85c4637

2025.0.16 (2024-11-21)
* Add basic framework for handling traing of items that were awarded from a player's bags instead of a loot table 73e8b1e
* Add descriptions and help to announcements configuration 0dbbdc6
* Add Firelands encounters 30dd15a
* Add Firelands loot e5af8da
* Add icon and tooltip for source of item in the loot session interface 8834325
* Add item owner as a transmitted attribute which is made available for announcing items 687f6df
* Add item owner as an available attribute for announcing items awards 8d03b1b
* Add owner and item status to loot allocation interface. Add right-click menu to loot ledger interface. bfad0e4
* Add support for updating loot ledger when items are for 'award later' or 'to trade' f072da3
* Added shell of interface for displaying loot ledger through UI 2cea873
* Added source of loot to Loot Ledger, if dropped from an encounter 65821c1
* Added winner of loot to Loot Ledger, if has been awarded d7e9063
* Address issue with time remaining bar not being properly handled on sort and refresh 5efb00e
* Address issues with loot slots not properly being accessed 5b3980b
* Attempt to resolve NPM issues by using '--legacy-peer-deps' f3651ed
* Augmented item which was looted to bags (for later award), with ability store/restore the associated award attributes c540631
* Capture encounter from award if present when auditing and add tests for loot trading bd46971
* Completed support for 'award later' via loot session interface 5c6f162
* Correct interface version for Firelands 4e96a3d
* Disable 'award later' if items are added to loot session from ledger c466796
* Finalize award lader and item trading support 33b378d
* Fix testing regressions a8578fa
* Highlight specific item(s) on the loot session interface in order to prevent incorrect allocation a41149b
* Include Vehicle, GameObject, and Pet as valid 'creature' GUIDs 5d6e1e2
* Simplify the representation of an item award, allowing for use when awarding/trading from items in bags 1db6db3
* Support 'award later' from loot allocation interface 8e32aa7
* Support removal of items from loot ledger, by specific item or state a61602d
* Update support for requesting and automatically adding random rolls during loot allocation c516132
* First round of changes in the effort to support awarding loot from player's bags instead of directly from creature ae7915b

2025.0.15 (2024-10-29)
* Add Firelands encounters 398c6c8
* Add Firelands loot 5841023
* Attempt to resolve NPM issues by using '--legacy-peer-deps' 01812ee
* Compatibility with Firelands Patch 06b5e93

2025.0.14 (2024-09-01)
* Add comments to Item and Loot classes for future reference and clarity bd10d49
* Update handling of item links to be consistent with number of indices currently used (provided) bfdab19

2025.0.13 (2024-08-12)
* Correct regression with logging when no cached player entry 7a47411

2025.0.12 (2024-08-08)
* Correct regression with player information, which was introduced upon removal of tracking guild rank c7dbe77

2025.0.11 (2024-08-06)
* Purge expired player cache entries on login when addon is enabled e4b4805
* Remove guild rank as a displayed column in loot allocation and use WOW API for calculating average item level fe2dffc
* Request player info when they join the group in addition to when new master looter is established 422cf22

2025.0.10 (2024-07-18)
* Enabled audit purging by default, retain less data, and execute more frequently 27c2ada
* Send updates less frequently for configuration/lists after raid based updates and be more tolerant of time allowed to synchronize bd590a1

2025.0.9 (2024-07-13)
* Various small changes to comments and changelog 90011ad
* Check if an item is self referencing (the item itself, not equipment location) prior to evaluating based upon token 388ac9a
* Remove the ugly shadow border on dialog popups dcddd57

2025.0.8 (2024-07-11)
* Address a few minor UI issues, including changelog not being completely displayed, fixing typo in Omnitron encounter, and displaying difficulty for raid encounters f988e6c
* Address issue with trailing space causing linting to fail bed6145
* Minor modifications to WOW API stubs used by encounter(s) 3a66707
* Track loot source in addition to slots, which resolves issue with ALT clicking on loot window not allowing for multi-boss loot sessions 146cce9

2025.0.7 (2024-07-05)
* You spin me right 'round, baby, right 'round b38cbf1

2025.0.6 (2024-06-21)
* Like a blind man at an orgy, I was going to have to feel my way through (fuck you Glyph) 6a8075c

2025.0.5 (2024-06-16)
* On broadcast of Configuration, verify that lists are removed if present and not included in the broadcast 2d40f4f
* On request for Configuration/List, verify it could be found when sending a response 3df5bba

2025.0.4 (2024-06-01)
* Add an additional row of alts to Configuration c90c9b1
* Add an additional row of priorities to Loot Lists 312cb70
* Reposition the available equipment dual listbox based upon size increase of containing tab f2c372d

2025.0.3 (2024-05-11)
* Cleanup change log and modify template for CHANGES.MD 3dcacf2
* Modify commit hashes to short in changelog a7ca1f9

2025.0.2 (2024-05-11)
* Modify output of change log to use short commit hashes 5a8087b
* Update Library versions, cleanup tests, and add Cata P1 Raid Items 3580d3e

2025.0.1 (2024-05-10)
* Add Cata P1 raid items
* Add Cata P1 raid maps, creatures, and encounters

2025.0.0 (2024-05-07)
* Actually publish first build of Cataclysm 3d326c6
* attempt to fix issues with semantic-release configuration 7112735

2024.0.5 (2023-11-28)
* Correct a few mispelled boss names for encounter tracking bd7e313

2024.0.4 (2023-10-28)
* add missing API stub to correct test failure 18e5137
* Cache player resolution by Configuration when performing lookup for raid statistics 130faad
* Resolve all players to their 'mains' when calculating attendance stats for list priority popup and overall player stats bb4fb92
* Resolve to main for calculating raid attendance when bulk managing loot priority lists 25f5e94
* retain numeric labeling for priority if a player is present in the list slot 7da37a1

2024.0.3 (2023-10-25)
* Fix test regression b5490d7
* Miscellaneous changes which do not impact functionality, but rather qualtify of life improvements 460e8b4

2024.0.2 (2023-10-08)
* Address issues uncovered through test suite related to Ace and LibGuildStorage changes ce27325
* Address race condition in LibGuildStorage that could lead to frame drops and game lock-ups 40e9406
* Annoate Libraries to reflect classes 11f9c74
* Minor tweaks to event processing and configuration activation, which should reduce overhead for both ML and other players 2526dcb
* Update Ace3 Libraries to latest version(s) 2da406a

2024.0.1 (2023-10-06)
* Add Phase 4 items to test data a87095f

2024.0.0 (2023-10-01)
* Add support for WOTLK P4 (Icecrown Citadel) c96b49d

2023.0.2 (2023-07-12)
* Address issues with only 'suicide' showing up on loot window for trophies and regalia 7b7d327
* Do not transition response to offline/not installed if an ACK has been received within timeout. 162fa5f
* Fix test regression due to not considering WAIT as being eligibile for transition to NOTHING. 0479f84
* Only send ML DB (Settings) to the requestor on an explicit request. No need to flood the entire group. 8de65b3
* Remove 'transform' from writerOpts in an attempt to avoid date parsing issues in building distributable c9e884c
* Try previous version of @semantic-release/release-notes-generator to avoid error with date parsing 79ab644

2023.0.1 (2023-06-24)
* Reduce complex logging in Loot Allocation, as executed twice per second and typically converting multiple tables into strings. This should address/alleviate game pauses for master looter. adbf4cf

2023.0.0 (2023-06-20)
* Add support for WOTLK P3 and lists being based upon items (instead of equipment slot) a87e8df

2022.4.2 (2023-04-04)
* Polearm(s) are usable by Death Knights bed032b

2022.4.1 (2023-02-23)
* Stop charming the stiffmeister b30d326

2022.4.0 (2023-02-22)
* Update READMER to point to GHA build 
* Add confirmation dialog when broadcasting the deletion of list configuration 20850b0
* Add support for exporting loot lists to CSV 6efe85f
* Additional charms c9da927
* Even more charms 76f1cd1

2022.3.10 (2023-02-07)
* Merge branch 'master' of https://github.com/therice/Cleo 0dfdc39
* Sanitize change log fe0ab6e

2022.3.9 (2023-02-07)
* Use forged packaging script to skip check for future release via GHA 0daf05a

2022.3.8 (2023-02-07)
* Migrate to GitHub actions e5630f3
* Charm a special someone for the season 9b78f64
* Remove prerelease and build from versions when comparing for being on most recent version 298742d

2022.3.7 (2023-01-27)
* Merge branch 'master' of https://github.com/therice/Cleo 7768bb2
* Address issue with invalid channel name being used when announcing to party b26d940
* Address issue with viewing ALTs and editing them due to WOW API changes 9e93ae3
* Fix issue with Master Looter being unable to award loot to themselves due to change in GetContainerNumFreeSlots 69a4f77

2022.3.6 (2023-01-25)
* Address error in Traffic History due to WOW API change in SetNormalTexture() e62a15a

2022.3.5 (2023-01-23)
* Correct issue with redefinition of player in IsUnknown() 6a4ba2c
* Determine group member count via GetNumGroupMembers() instead of _G.MAX_RAID_MEMBERS 9a51e3d
* Eliminate ridiculous formatting in 'about' interface f81198e
* Master Looter - for an item without a loot slot, don't treat as award unless winner is set f938674
* Notify player, via whisper, if Cleo is not installed when joining group where it is in use 2974627
* Player - refactor 'Uknown' into class instance 2a957eb
* Remove redundant check for player information being available 8c1f9c7
* Turn off list replication, it's not currently being used and needs testing before enabling (for all) 5c6026f

2022.3.4 (2023-01-21)
* fix : Add missing Ulduar mappings for token based items to equipment locations. febe185
* Update TOC to reflect Ulduar patch version 1657932

2022.3.3 (2023-01-14)
* Fix compatibility issues with Wrath P2 client f9795bc

2022.3.2 (2023-01-08)
* Add Ulduar encounters and loot 35981a8
* Address race conditions on initial login with player info not being available, which can result in unintended behavior. c61c1bb

2022.3.1 (2022-12-27)
* Address issues with date cutoffs and ordering with bulk list management 9d2ecba
* Remove assertions from date tests which are not consistent as time marches forward 21ee642

2022.3.0 (2022-12-24)
* Add support for auto purging of raid, loot, and traffic history 04ab060

2022.2.0 (2022-12-24)
* Add support for bulk managing list priorities 3d0cecb
* Correct issue with logging regression ead2993

2022.1.7 (2022-11-13)
* revise change log 
* Correct failing test due to undefined symbol f22debe
* Do not include shirt and tabard in any gear gathering or calculations d8068a5
* Key to Focusing Iris to token based items 70798f2
* Use consistent player cache duration unless in test mode, which resolves issues with extra information not being available (such as if player is an enchanter) e86d946

2022.1.6 (2022-11-10)
* Merge branch 'master' of https://github.com/therice/Cleo e991143
* Correct loot allocation window's status to be based upon actual loot table rather than tracked flag bb64ccc
* Do not cache unit names based upon input, this could result in both incorrect mappings and failed resolutions persisting

2022.1.5 (2022-11-10)
* Add last attended raid to tooltip for player on lists and correct issue with rounding errors on calcuating percentages 83e66ab
* Adjust priority adjustment based upon attendance to adhere to our loot rules 349c8fb

2022.1.4 (2022-11-08)
* Attempt to address issue with loot allocation window button not transitioning to 'close' and minor cleanup in detection of 'unknown' player 2b3083b

2022.1.3 (2022-11-01)
* Merge branch 'master' of https://github.com/therice/Cleo ac3325b
* Address loot allocation session not always being ended after last item is distributed 5413fc6
* Correct encounter ids for P1 raids 34d5e1f
* Correct issue that prevented deletion of raid audit entries c109897

2022.1.2 (2022-10-21)
* Address broadcast functions not being initialized correctly 707b1eb

2022.1.1 (2022-10-20)
* Add additional views/statistics for raid history aa0ea7b
* Allow broadcast to remove a configuration 7bf80fa
* Change open roll to a suicide amount of 2 (by default) a989bb0

2022.1.0 (2022-10-16)
* Add support for changing priorities based upon raid attendance d411770
* Address luacheck regressions 15c41c7

2022.0.0 (2022-10-15)
* c'mon man ce4091b
* WTF ed4ae73

2021.5.1 (2022-10-15)
* address syntax error in release file 478c130
* re-attempt bump major version 4dff293
* bump major version 87c7289

2021.5.0 (2022-10-15)
* feat: Add support for raid tracking a7e0469
* Update README to reflect WOTLK 
* Show raid attendance via player priority on list 6de96b9
* address issue with not all raids being included for attendance 8aa40e9
* Cleanup font usage to be consistent 7039ac7

2021.4.21 (2022-10-11)
* revise change log 
* Add support for populating lists randomly from guild ranks. Also, sort lists alphabetically 06850d2
* hide right-click options if context is missing a player 9b4f7f9

2021.4.20 (2022-10-10)
* Add support for player names with utf8 characters as first character in name 42e57b5
* Add tokens from WOTLK Phase 1 7155ea3
* Address regression with UTF8 handling in strings 0f62b24
* Change off spec to open roll in loot window b0c0ef3

2021.4.19 (2022-10-04)
* Add support for dummy players in test mode and don't move scroll on scrolling table refresh 2e191de
* Remove unnecessary boolean return on award announcement fb4d4ee

2021.4.18 (2022-09-09)
* revise change log 
* Add T6 Tokens and Death Knight support to LibItemUtil 525f668
* Address issue with player information not being available on initia login 6a188c7
* Retroactively add SWP encounters to LibEncounter 2a909ab

2021.4.17 (2022-09-08)
* Minor modifications related to sorting and guild ranks for loot allocation 036621e

2021.4.16 (2022-08-30)
* Update manifest for Wrath e2e4130

2021.4.15 (2022-06-16)
* fix issue with partial suicide not working and incorret priorities being displayed in announcements 7d2e92c

2021.4.14 (2022-06-14)
* add minor upgrade as a response option 584f78a
* if player information is not available upon login, defer enabling addon until available 9535f85
* suport partial suicide for a minor upgrade 8a53fd5

2021.4.13 (2022-06-12)
* if player information is not available upon login, defer event handling until available 5eae017

2021.4.12 (2022-05-06)
* add support for capturing logging for forensics ef11b06
* add support for intuitive repositioning of players in loot lists 8d9bfdc

2021.4.11 (2022-04-02)
* add missing translation for version being out of date 330a669
* add support for purging loot audit records and don't record loot audit for auto-award a499a9b

2021.4.10 (2022-03-22)
* cleanup the build file after resolving luarocks build issue c994e3f
* address issue introduced in game version 2.5.4 where GetPlayerInfoByGUID not reliably available on initial login 406b1d8

2021.4.9 (2022-03-22)
* another lanes version attempt 1f595f6
* attempt to resolve build failures be explicitly including server 04568dc
* attempt to resolve build failures be explicitly installing required dependencies 289cf53
* enable verbose logging for installing lanes module a5e22f8
* enable verbose logging for installing lanes module (fix typo) 29c6c58
* FFS 2be6821
* specify explicit version of lanes that does not have the git+https url 2661d0b
* try a different ubuntu dist for build c147319
* update interface version for new patch 9c614f2

2021.4.8 (2022-02-24)
* correct issue with restarting replication 2ede1c5

2021.4.7 (2022-02-23)
* update README with link to CI 
* when joining a group with replication running, it's not being terminated due to exception 24b3e7a

2021.4.6 (2022-02-22)
* implement config/list data replication within guild context (disabled by default) 1b7b40f

2021.4.5 (2022-02-14)
* add encounters and creatures for MH and BT 2cca872
* address incorrect handling of encounter when clearing loot history filter 9ea879d
* correct list resolution for auditing when award reason is not suicide 495ec53
* correct text placement on sync UI and allow for cutom items to be synced e350d08
* correctly sort dates on both loot and traffic audit UI fe14a73
* support encounter as filter on loot history 08f5fba

2021.4.4 (2022-02-04)
* add tier tokens for MH and BT badc46d

2021.4.3 (2022-02-04)
* fuckity fuck fuck fuck 7564361

2021.4.2 (2022-02-04)
* resolve issue with raid priority potentially raising and error AND send active config on player reconnect 199578d
* Rogues cannot use 1H Axes b738990

2021.4.1 (2022-02-03)
* resolve test which was not committed with previous change ec9a93c
* add display of priorities for a list, filtered by players in raid 4c491b3
* display player priority and other player's response on loot response window 7aace4b

2021.4.0 (2022-02-02)
* Merge pull request #1 from therice/feature/dataplane 7fba8ed, closes #1
* update game version in TOC 8a8e0c3
* add support for electing leaders for configurations and lists, in preparation for real time data replication bc0358a

2021.3.9 (2022-01-31)
* address issue where award types that aren't visibile to player were being incorrectly handled in loot history 98f7d6c
* don't include list and priority in auto-award announcements d45ea03
* don't revert player's response to awaiting when requesting rolls 1c60561
* fix regression with configuration activation not being processed when player is not ML fb3036c

2021.3.8 (2021-12-17)
* address issue with UI for configuration/lists not being refreshed when underling data has been modified 9c66b80

2021.3.7 (2021-12-13)
* disable priority in loot window until player events are handled by all group members 91d561c
* fix repeated re-activation of configuration/lists resulting in corruption of priorities when ML 2569cfc

2021.3.6 (2021-12-09)
* address issue with priority not being displayed to player on loot window a8c9022
* address issue with testing loot allocation not working outside of a group 26a9192
* response changes, need to suicide and open to off spec 7f1660e

2021.3.5 (2021-12-03)
* address issue with version checker not being scrollable f824a10
* squash unresolved creature names in loot history fd6dc67
* use constants for guild/group for targets in sync window d96f26d
* add native globals to luacheck a17e643

2021.3.4 (2021-12-01)
* add support for synchronizing data between players bba4eac
* add support for synchronizing loot history 12d2f6f
* add support for synchronizing master looter settings 47acb6d
* add support for synchronizing traffic history 492d9a7
* address issue with display of player's priority shortly after login 922516f
* address version tracking regression 13ec8bd

2021.3.3 (2021-11-29)
* add support for broadcasting config and associated lists via right-click on configuration dac606d
* minor cleanup with logging and tests related to master looter 4ccd96b

2021.3.2 (2021-11-21)
* resole issue with being unable to set a configuration as default or delete (as owner) dfabc50
* resolve issue with priority lists not being requested/sent from ML when in raid 74eb5d5

2021.3.1 (2021-11-19)
* address regression with Lists UI when no Configuration(s) exist 0b8ac26
* enable persistence mode by default 32db14e
* item link missing on loot roll window 679eff0
* when in debug mode, parse version from change log 47f9d47

2021.3.0 (2021-11-17)
* add support for alternate characters (not yet plugged into loot allocation) e0cf4fa
* add support for alternate characters (plug into loot allocation process) e8b6b48
* address incompatibility with Bagnon related to how it iterates all libraries b0edecf
* navigating to award from traffic history selecting incorrect tab 3113abe

2021.2.3 (2021-11-11)
* add additional logging to ML loot table construction 3461690
* auto-award was not working due to award reason lookup being incorrect dc2e8b8
* modify list priority on award before announcement 613c51b
* re-introduce persistence of resources in request/response workflow 0b8a2c2
* require manual refresh instead of periodic on metrics display b09661d

2021.2.2 (2021-11-04)
* change responses displayed text - MS to Need and OS to Open 56a71e5
* add interface for viewing addon metrics 234e804
* add support for sorting by priority in loot allocation window 10eb330
* address 'accessing undefined variable self' in Loot Allocate 42b5cf6
* convert alarm to using native scheduling rather than frame events 909bf86
* make loot window wider and hide rescaling slider 7da177d
* black magic to get scheduling based stuff to work 0726548

2021.2.1 (2021-11-04)
* don't run luacheck on Changelog.lua 32a83d7
* final cleanup of addon packaging and reintroduce tests b80f9fa
* only fire callbacks when persistence mode is enabled and reactive configuration on changes 1f94baf
* respect admin/owner(s) with respect to configuration and list editing a414fbb

2021.2.0 (2021-11-02)
* docs(release): 2021.2.0 
* build(release): update changelog parsing to handle additional details 
* chore(release): 2021.2.0 
* enabled persistence mode by default when not in debug mode dd9741c
* add additional references to eaa5435
* add NPM to build environment 47f1a16
* add python3 to build environment for release processing 86e3f90
* add python3 to build environment for release processing (part 2) 9839f43
* add semantic-release (and deps) to build environment d7675ab
* another attempt to assemble all of the release parts c4e52a1
* another iteration on jobs and stages 1a19d6f
* another iteration on using jobs c3be40a
* change conditional for building distributable 5292876
* cleanup bash rustiness 943fa26
* cleanup references to use f652dc3
* disable dry run of semantic-release 7a55f9f
* execute semantic-release (dry run mode) for deployment ab5ceb6
* first attempt to assemble all of the release parts 2edc414
* first cut at converting build to use jobs and stages 284bdfa
* more deploy changes to accomodate NPM environment 3c17c55
* move conversion from MD to LUA into the prepare stage 13a3443
* remove jobs, don't need speed or extra usage of tokens 1beaa3a
* specify github token in deploy script b989e4b
* fix formatting in LibItemUtil b4e19a2
* fix type in README 02f78e5
* specify the adoption of conventional commits e9201b7
* add support for scaling frames on a per fram basis d7f0324
* address delayed item and player resolution resulting in multiple potential regressions 61028c5
* address multiple regressions identified in beta testing e25f4b6
* address multiple regressions identified in beta testing dc0264f
* cleo /c does not show configuration ui cc6c8f1
* delay display of custom items until item query returns 3b38e8b
* insert random doesn't work if priority list is empty f5b2a99
* only check generating configuration events if a module ba6480d
* only store the attributes of version, not class 2c470ed
* use unknown player when one cannot be resolved a6381b5
* address regression introduced by changing player cache time to be based upon mode 7e19bdd
* remove tests for functions based upon coroutine 047c66a

2021.1.1
* Beta release appropriate for limited testing by users.

2021.1.0
* Initial alpha release, appropriate for developer use only.
]=]