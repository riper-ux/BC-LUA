# Blue Coop

> **⚠️ DISCLAIMER**
>
> This repository is provided "as is", without any warranties or guarantees of any kind, either express or implied.
>
> By using any code, scripts, or tools found here, you acknowledge that you are doing so **at your own risk**. The contributors and maintainers of this project shall not be held liable for any data loss, system crashes, hardware damage, or any other issues that may arise from the use or misuse of this repository.
>
> **If you discover a bug**, please create an issue with the `BUG` label so we can look into it. Thank you!

---

## 📌 About

Blue Coop is an **unstable, early-prototype** co-op mod for *Voices of the Void*.  
It is raw, buggy, and may crash your game or corrupt your save files. You have been warned.

The mod introduces a **modular synchronization system** built around three core modules:

| Module | Status | Description |
|--------|--------|-------------|
| **Player** | ✅ Basic | Tracks player position and sends their transform to the server. Most stable part. |
| **Event** | ⚠️ Stable-ish | Universal sync handler for function calls. Works only under strict conditions (see below). |
| **Prop** | 🔥 Very unstable | Aims to sync physics-based props. Architecture is still undecided — details may change drastically. |

---

## 🧩 Modules Overview

### 👤 Player Module
- Finds the player in the game world.  
- Sends the player's `transform` (position, rotation, scale) to the server.  
- Simple, works as expected.

### 📡 Event Module
Universal handler for syncing **function calls** across clients.  
Works **only if** all three conditions are met:

1. **Static object** – The object does not spawn, despawn, or change its access path during a session.  
2. **Primitive parameters only** – `int`, `float`, `string`, `bool`, etc. No pointers (`userdata`), no direct references to game objects.  
3. **Player-independent** – The function's behavior does not change based on player actions. The function can still be *called* by a player, but it must execute identically on all clients.

> If any condition is violated, the Event module may behave unpredictably or crash.

### 🧱 Prop Module
> **Status: Highly unstable, experimental**

Designed to synchronize **props** — physics-enabled items scattered around the map.  

Current state:
- Tries very hard to sync props. Sometimes even succeeds.  
- No final architecture yet — sync method and internal design are still being explored.  
- Details cannot be shared yet because nothing is finalized.  
- **Expect frequent changes, broken commits, and weird behavior.**

---

## ⚠️ Known Issues

- Game crashes are common  
- Render freezes ([Issue](https://github.com/riper-ux/BC-LUA/issues/2))
- Prop desync is normal  
- Some events may fire incorrectly or not at all  
- No multiplayer UI or session management yet  

---

## 🧪 Development Status

**Pre-alpha / prototype stage**  
Everything is subject to change. The mod is being built and tested live. Contributions and bug reports are welcome, but please keep expectations low.

---

## 🐞 Reporting Bugs

If you find a bug:

1. Make sure it's not already listed in Issues  
2. Create a **new issue** with the `BUG` label  
3. Describe what happened, what you expected to happen, and (if possible) steps to reproduce

Thank you for your patience and courage.

--- 

## 📄 License

MIT