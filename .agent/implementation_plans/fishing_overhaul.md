# Implementation Plan: Fishing System Overhaul

## Overview
Major refactoring of the fishing system with new UI components and economy changes.

## ✅ COMPLETED Tasks

### 1. Equipment UI (DONE)
**File:** `src/client/EquipmentSystemClient.client.lua`
- ✅ Same style as Fish Collection UI
- ✅ Floating circular button with "Equip" text
- ✅ Tabs: "Rods", "Floaters"
- ✅ Press G to open

### 2. Fish Collection UI (DONE)
**File:** `src/client/FishCollectionClient.client.lua`
- ✅ Tab "Inventory" - fish player owns
- ✅ Tab "Index" - Pokedex-style all fish
- ✅ Sort and filter
- ✅ Press F to open

### 3. Fish Economy Change (DONE)
- ✅ Fish goes to FishInventory, not money
- ✅ Money only given when sold at shop

### 4. Fisherman Shop (DONE)
**File:** `src/client/FishermanShopClient.client.lua`
- ✅ ProximityPrompt on "FishermanShop" part
- ✅ Fish disappears from list when added to cart
- ✅ Quantity slider popup for bulk add
- ✅ Quick add (+1) button
- ✅ Cart with confirm/discard
- ✅ Same style as Fish Collection

### 5. Fishing System Water Detection (DONE)
**File:** `src/client/FishingSystemHandler.client.lua`
- ✅ Floater only bobs if in water
- ✅ Fish detection only if in water
- ✅ Can retrieve floater even if on land

### 6. Data Persistence (DONE)
**Files:** `src/server/DataHandler.lua`, `src/server/ToolGiver.server.lua`
- ✅ FishInventory saved
- ✅ DiscoveredFish saved
- ✅ EquippedRod & EquippedFloater saved
- ✅ Auto-equip rod on respawn/join

### 7. UI/Throwing Fixes (DONE)
**File:** `src/client/FishingSystemHandler.client.lua`
- ✅ Cannot throw when any UI is open
- ✅ UI state tracked continuously
- ✅ Click to retrieve floater even if stuck on land

### 8. AFK Mode Improvements (DONE)
**File:** `src/client/FishingSystemHandler.client.lua`
- ✅ Wait 5 seconds after new fish UI appears
- ✅ Auto-close new fish UI after 5 seconds
- ✅ Skip throwing while UI is open
- ✅ Auto-close Equipment/Fish UI on rare+ fish catch

---

## New Features Summary

### Keybinds
| Key | Action |
|-----|--------|
| G | Equipment UI (Rods & Floaters) |
| F | Fish Collection (Inventory & Index) |
| I | Inventory (Auras, Tools, Titles) |

### Data Saved
- FishInventory (fish not yet sold)
- DiscoveredFish (for Index)
- EquippedRod (auto-equipped on join)
- EquippedFloater (remembered)
- TotalFishCaught (stats)

### Files Created/Modified

**NEW FILES:**
1. `src/client/EquipmentSystemClient.client.lua`
2. `src/client/FishCollectionClient.client.lua`
3. `src/client/FishermanShopClient.client.lua`
4. `src/server/FishermanShopServer.server.lua`

**MODIFIED FILES:**
1. `src/server/DataHandler.lua` - Added FishInventory, DiscoveredFish
2. `src/server/FishingRewardServer.server.lua` - Fish to inventory
3. `src/client/FishingSystemHandler.client.lua` - Water detection, UI blocking, AFK improvements
4. `src/client/InventorySystemClient.client.lua` - Removed Rods/Floaters tabs
5. `src/server/ToolGiver.server.lua` - Auto-equip saved rod

---

## Setup Required

1. **FishermanShop Part:**
   - Create Part in Workspace named `FishermanShop`
   - ProximityPrompt auto-created

2. **Water Detection:**
   - Uses Terrain water material
   - Also detects parts named "water" or tagged "Water"
