# Petmalu Shop - Audio System Documentation

The **AudioManager** is a global singleton (Autoload) designed to handle background music (BGM) transitions and one-shot sound effects (SFX) with minimal setup.

## 🛠 Integration
The system is registered as an Autoload. You can access it from any script using the global identifier `AudioManager`.

- **Script Path**: `res://src/Autoloads/AudioManager.gd`
- **Autoload Name**: `AudioManager`
- **Audio Buses**: Automatically ensures "Music" and "SFX" buses exist at runtime.

---

## 🎵 Background Music (BGM)
The BGM system handles smooth transitions between different area themes.

### `play_bgm(path: String, fade_duration: float = 1.5)`
Fades out the current track and fades in the new track over the specified duration.

**Usage Example:**
```gdscript
func _ready():
    # Switches to the town theme with a smooth 2-second crossfade
    AudioManager.play_bgm("res://assets/Audio/BGM/town_theme.mp3", 2.0)
```

**Key Features:**
- **Cross-fading**: Uses Tweens to prevent "audio clipping" or jarring silences.
- **Deduplication**: If you call `play_bgm` with the track that is *already playing*, it will ignore the call and continue playing seamlessly.
- **Persistence**: Since it is an Autoload, music persists across scene changes.

---

## 🔊 Sound Effects (SFX)
SFX are played as one-shot instances that clean themselves up automatically.

### `play_sfx(path: String, volume: float = 0.0)`
Instantiates a new temporary `AudioStreamPlayer` to play the requested sound.

**Usage Example:**
```gdscript
func interact():
    AudioManager.play_sfx("res://assets/Audio/SFX/door_open.wav", -5.0)
```

**Key Features:**
- **Automatic Cleanup**: Every SFX player is automatically freed (`queue_free`) once the sound finish playing.
- **Independent Volume**: You can pass a `volume_db` offset per call.
- **Bus Routing**: All SFX are routed to the "SFX" bus for global volume control.

---

## 🎛 Audio Buses
The system automatically creates and targets two primary buses:
1. **Music**: For all `play_bgm` calls.
2. **SFX**: For all `play_sfx` calls.

> [!TIP]
> To control the master volume of your game, you should adjust the volume of these buses in the Godot Audio Mixer or via code using `AudioServer.set_bus_volume_db()`.
