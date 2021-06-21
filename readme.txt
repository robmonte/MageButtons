MageButtons
- Purpose: Adds "menu" buttons for mage spell categories: water, food, teleports, portals, mana gems, polymorph
- Author: Moxxe <Evolved> - Pagle (NA) - Discord Neko/Moxey#2051

Features
- Consolidates spells into collapsible buttons to save bar space (like modern teleports/portals buttons)
- Horizontal or Vertical layouts
- Menu direction left/right/up/down
- Customizable button size, padding, background color, border
- Can specify button order
- Buttons can be keybound via standard bindings page (under Addons)

Other
- First time loading it will default to a set button order, need to go into Options and actually set them for them to save (will say "set me")

Usage
- Right click buttons to show menu, or enable mouseover option
- Left click menu buttons to set them, then left the base button to cast the spell
- /magebuttons (show usage)
- /magebuttons config (open options window)
- /magebuttons minimap 0 (hide minimap icon)
- /magebuttons minimap 1 (show minimap icon)
- /magebuttons unlock (show anchor to move the bar)
- /magebuttons lock (hide anchor to move the bar)
- /magebuttons move (toggle move anchor on/off)

Known issues / TODO:
- Keybindings are wonky, probably because I'm doing something wrong, but they mostly work?
-- 0.99 release appears to require a reload after setting keybinds
- Not sure if the Polymorph button is worth it, was thinking it would be nice to easily switch from Sheep to Turtle to Pig
- Could add AI for easy access to lower ranks for lower level players
- Lock/unlock from options panel is out of sync with minimap click
- New spells learned from trainers are not automatically added, need to /reload

Revision History
2021-05-18 - 1.03 - Increased startup delay
2021-05-13 - 1.02 - Updated with TBC spells
2019-08-31 - 1.01 - Set menu button strata to HIGH, updated usage
2019-08-15 - 1.00 - Added mouseover option, minimap icon will now default to on
2019-08-11 - 0.99 - Minimap button should now stay hidden
2019-07-28 - 0.99 - Largely rewritten, most settings changes should now occur without needing to reload
2019-06-23 - 0.90 - Initial Classic WoW Beta release