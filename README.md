<body style="background-color:black;">

# <font color="#FFA62F">**Cleopatra**</font>

[![Build Status](https://github.com/therice/Cleo/actions/workflows/build.yml/badge.svg)](https://github.com/therice/Cleo/actions/workflows/build.yml)
[![Coverage Status](https://coveralls.io/repos/github/therice/Cleo/badge.svg?branch=master)](https://coveralls.io/github/therice/Cleo?branch=master)
[![Conventional Commits](https://img.shields.io/badge/Conventional%20Commits-1.0.0-yellow.svg)](https://conventionalcommits.org)
[![CurseForge](https://cf.way2muchnoise.eu/1201094.svg)](https://legacy.curseforge.com/wow/addons/cleopatra)

![](https://github.com/therice/Cleo/blob/da931314a56cf9ee2bd6b1a84c513b92c2420b96/Media/Textures/Cleo_Banner.png?raw=true)

## <font color="#728FCE">Description</font>

**Cleopatra**, aka **Cleo**, is an in-game loot distribution addon for World of Warcraft (_Classic_) inspired by [Suicide Kings](https://wowpedia.fandom.com/wiki/Suicide_Kings). 

Designed to distribute items based upon a player's interest and priority (relative to other players), it offers a comprehensive set of features for handling loot and can be used in any scenario that supports a Master Looter.

Developed over the lifetime of World of Warcraft (Classic), Cleo makes loot management effortless and offers a transparent, streamlined, and enjoyable user experience.

## <font color="#728FCE">Basics</font>

* A configuration is created, which consists of one or more priority lists.
* Each priority list is associated with one or more equipment slots (e.g. Chest Amor, Two-Handed Sword) or specific items (e.g. [Kiril, Fury of Beasts](https://www.wowhead.com/cata/item=78473/kiril-fury-of-beasts)).
* Players are added to each of the priority lists. Typically, this is done in a random manner but can be done via alternative approaches.
* When loot drops, players are able to specify their interest. The person with the highest priority and interest wins the loot and drops (suicides) to the bottom of the list.
* Players who are not currently in the raid do not move up or down on the lists in their absence.

<font color="#98AFC7">**_Caveats_**</font>

* Cleo supports a modified (if desired) version of Suicide Kings, in which players can qualify their interest in loot.
  * _Suicide_ : Follows the same rules as outlined above.
  * _Minor Upgrade_ : Instead of being dropped to the bottom of the list, the player is dropped 5 positions on the associated list.
  * _Off-Spec_ : Instead of being dropped to the bottom of the list, the player is dropped 2 positions on the associated list.
* Cleo supports attendance based list maintenance, allowing you to drop players spots on all lists or remove entirely in the face of specified attendance metrics (e.g. absent for past two raids).

## <font color="#728FCE">Features</font>

### <font color="#98AFC7">Fully Automated Loot Experience</font>
* A fully customizable loot interaction and distribution interface for both the Master Looter and each raid member. 
* Only relevant items are shown to each player, displaying only usable armor and weapon types.
* Automatic loot distribution to specific players based on item quality.
* Loot is presented to players via an intuitive custom interface, easily allowing them to view detailed item information, their priority, and declare their interest (or lack thereof).
* Consolidated interface for the Master Looter, allowing them to review all player's interest in items sorted by response and priority. Loot can be assigned and distributed in a single click. 

### <font color="#98AFC7">Deferred Loot Distribution</font>
* If you prefer to NOT distribute loot as it drops on a per-encounter basis, you can defer allocation until the raid is complete.

### <font color="#98AFC7">Customizable and Configurable</font>
* Supports multiple distinct loot configurations, each tailored to meet the unique needs of the group.
* Create loot priority lists based on equipment slots, equipment categories, or specific items.
* Create custom items based on existing ones, with the flexibility to modify attributes such as item level, equipment slot, and more.
* Adjust the core Suicide Kings system to allow priority modifications beyond pure "suicide," including options like Minor Upgrade and Open Roll.
* Support for associating "alts" with a "main," treating them as the same character for loot priorities.
* Intuitive configuration interface with clear, detailed instructions for available settings.

### <font color="#98AFC7">Just-in-Time Data Synchronization</font>
* Real-time synchronization of loot priorities and configuration within guild and raid settings.

### <font color="#98AFC7">Bulk Operations</font>
* Bulk modification of loot priorities based on raid attendance.
* Supports export and import of loot priority lists via CSV.

### <font color="#98AFC7">Auditability</font>
* Comprehensive auditing features, tracking loot priority modifications, loot allocation, and raid encounters.

</body>