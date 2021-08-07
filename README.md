# Hide 'n' Seek 2.0 (Codename Hunters)
This is heavily W.I.P, not fully complete yet.
This is a reconstruction of the classic Hide 'n' Seek DXMP mod, rebuilt from the ground up with more optimisations and better handling.

## Installation
```ini
ServerPackages=Hunters
ServerActors=Hunters.HuntersMut
```

## Running
```
mutate hunt
mutate hunt.help
mutate hunt.start
mutate hunt.random
mutate hunt.endless
mutate hunt.final
mutate hunt.set <key> <value>
mutate hunt.end
```

## TODO
- [X] Team handling
    - [X] Hooked in to OpenDX manually to handle.
- [ ] God mode
- [ ] Entity removal
    - [X] Weapons
        - [X] Reversible once game is over.
    - [X] Security terminals
    - [X] Autoturret guns
    - [X] Map exits
    - [X] Datalink triggers (Can I even do this?)
- [X] Alerts
    - [X] "Player found by X"
    - [X] List players still to find.
    - [X] Sound effect
    - [X] Lighting
- [X] Fix leaving/joining breaking the counting
    - [X] In theory fixed just due to how the new framework works.
- [X] Fix players loosing the item
    - [X] Item should now be given each respawn to any player that needs it.
- [X] Endless mode
    - [X] Automatically start new round when one ends with a random hunter
- [ ] Max timer for round.
- [X] Random hunter
- [X] Disable IFF
    - [X] Hooking OpenDX extended HUD
- [ ] Automatic map rotation
    - [ ] Store list of valid maps in config
    - [ ] Index of current map as a config
    - [ ] Config for rotation type
        - [ ] Cycle (Increment +1)
        - [ ] Random
