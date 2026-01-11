# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Godot 4.5 game project using the Forward Plus renderer. The project name is "holodelive".

## Development Commands

```bash
# Open the project in Godot Editor
godot --editor --path .

# Run the project
godot --path .

# Export for Windows (requires export preset configuration)
godot --headless --export-release "Windows Desktop" build/holodelive.exe
```

## Project Structure

- `scenes/` - Contains game scenes organized by feature
  - `app/` - Main application scene
  - `title/` - Title/menu scene
- `project.godot` - Godot project configuration (version 5 config format)
- `.godot/` - Editor-generated cache files (gitignored)

## Architecture Notes

- Uses Godot 4.5 scene format (format=3)
- All scenes use Node2D as root nodes
- UTF-8 encoding enforced via .editorconfig
