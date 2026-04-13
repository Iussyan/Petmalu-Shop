# 🐾 Petmalu Shop - Game Design Document

**Genre**: Cozy Simulation + Exploration (Stardew Valley × Pokémon)  
**Style**: 2D Top-Down Pixel Art  
**Core Fantasy**: You inherited your Lola’s pet shop and must restore its legacy by rescuing, caring for, and rehoming animals across diverse landscapes.

---

## 🔁 Core Game Loop
1.  **Explore**: Traverse different biomes to find animals in need.
2.  **Rescue/Help**: Perform field rescues or assist injured animals.
3.  **Refuge**: Bring the animals back to your shop.
4.  **Caretaking**: Maintain their basic needs (Food, Health, Play).
5.  **Mini-Games**: Play to earn coins and improve pet happiness.
6.  **Commerce**: Buy food, medicine, and shop upgrades.
7.  **Adoption**: Prepare pets for their forever homes.
8.  **Progression**: Earn money and reputation to unlock new areas.

---

## 🗺️ World Structure

### 1. Town Area (The Starter)
*   **Description**: A cozy residential neighborhood where it all begins.
*   **Pets**: Dogs, Cats
*   **Features**: 
    *   Introductory Tutorial
    *   Simple Rescues (Found lost pets)
*   **Unlock**: Default Area

### 2. Desert Area
*   **Description**: A sun-scorched wasteland with hidden creatures surviving the heat.
*   **Pets**: Lizards, Sand Cats, Snakes, Desert Foxes
*   **Mechanics**: Heat survival mechanics for both player and pets.
*   **Unlock**: 5 Pets Rescued + Shop Level 2

### 3. Forest Area
*   **Description**: A lush, green woodland teeming with small life.
*   **Pets**: Rabbits, Birds, Hamsters
*   **Mechanics**: Tracking animals through bushes and trees.
*   **Unlock**: 10 Pets Rescued + Shop Level 3

### 4. Beach Area (The Endgame)
*   **Description**: A sunny coastline with both shore and shallow water biomes.
*   **Pets**: Fish, Crabs, Turtles, Injured Sea Animals
*   **Mechanics**: Water-based rescue challenges.
*   **Unlock**: 15 Pets Rescued + Shop Level 4

---

## 🐕 Pet System (Core Mechanics)

### Vital Stats
Each pet has three primary needs that the player must manage:
*   🍖 **Hunger**: Needs regular feeding.
*   💊 **Health**: Needs medicine, rest, and hygiene.
*   🎾 **Happiness**: Needs interaction and play through mini-games.

### Behavior & Consequences
*   **Low Hunger**: The pet begins to lose Health.
*   **Low Happiness**: The pet becomes harder to adopt (requires more preparation).
*   **High Stats (Maxed)**: The pet is ready for adoption, yielding better rewards and reputation.

---

## 🚀 Development Roadmap
- [x] Basic Top-Down Movement (8-Way + WASD)
- [x] Camera Following & Smoothing
- [x] Initial World Layout (4 Colors/Biomes)
- [x] Character Animation System (Idle/Walk)
- [ ] Pet Interaction System
- [ ] Rescue Mechanics
- [ ] Shop Management UI
