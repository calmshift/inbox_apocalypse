# Inbox Apocalypse

A satirical office-sim bullet-hell game built in Godot, blending absurd workplace humor with frantic dodge-and-shoot action.

## Game Overview

In Inbox Apocalypse, you navigate a drab office desk, treating incoming emails as literal enemies. Each email (enemy) drifts onto the screen; if left unanswered it "opens," unleashing a barrage of junk-mail projectiles. You must move your office-worker avatar and use response-actions (Reply, Forward, Delete) as attacks to clear the inbox.

As levels escalate in difficulty and absurdity, each day packs more emails, faster patterns, and increasingly bizarre office hazards. The world is bathed in a bleak corporate aesthetic to underscore a subtle dystopian tone.

## Controls

- **Arrow Keys/WASD**: Move the player character
- **Shift**: Hold to focus (slow movement for precise dodging)
- **R**: Reply attack (straight-line projectile)
- **F**: Forward attack (spread projectiles)
- **D**: Delete attack (area-of-effect bomb)
- **ESC**: Pause game/Return to menu
- **P**: Pause game

## Gameplay Features

- **Email Enemies**: Different types of emails with unique bullet patterns
- **Response-Attacks**: Three different attack types (Reply, Forward, Delete)
- **Stress Meter**: Your health bar - don't let it fill up!
- **Wave-based Levels**: Multiple waves of emails per level
- **Score System**: Earn points for defeating emails
- **Focus Mode**: Slow movement for precise dodging

## Development

This game is built with Godot 4.2.1. To run the project:

1. Open the project in Godot Engine
2. Click the "Play" button or press F5

To export the game for web:

```bash
godot --headless --export-release "Web" export/web/index.html
python3 -m http.server 12000 --directory export/web
```

This will export the game to the `export/web` directory and start a web server.

## Project Structure

- `assets/`: Contains all game assets (images, sounds, fonts)
- `scenes/`: Contains all scene files (.tscn)
- `scripts/`: Contains all GDScript files
- `resources/`: Contains resource files like level data

## Credits

Created as a prototype based on the Inbox Apocalypse Game Design Document.

## Future Improvements

- Add more enemy types with unique bullet patterns
- Implement boss battles
- Add more levels with increasing difficulty
- Improve visual effects and animations
- Add more sound effects and music
- Implement save/load system for high scores