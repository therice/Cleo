--- @type AddOn
local _, AddOn = ...

AddOn.Changelog = [=[
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