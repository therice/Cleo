--- @type AddOn
local _, AddOn = ...

-- todo : this is currently being generated before a release is tagged, it should be done with that process
-- conventional-changelog -p eslint -r 0 -v
AddOn.Changelog = [=[
2021.2.0 (2021-11-02)
* enabled persistence mode by default when not in debug mode dd9741c
* add additional references to eaa5435
* add NPM to build environment 47f1a16
* add python3 to build environment for release processing 86e3f90
* add python3 to build environment for release processing (part 2) 9839f43
* add semantic-release (and deps) to build environment d7675ab
* another iteration on jobs and stages 1a19d6f
* another iteration on using jobs c3be40a
* change conditional for building distributable 5292876
* cleanup bash rustiness 943fa26
* cleanup references to use f652dc3
* disable dry run of semantic-release 7a55f9f
* execute semantic-release (dry run mode) for deployment ab5ceb6
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