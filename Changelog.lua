--- @type AddOn
local _, AddOn = ...

AddOn.Changelog = [=[
2021.4.17 (2022-09-08)
* misc 036621e

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