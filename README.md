<div align="center">

✧ quantum ✧
<p align="center"><b>Hyprland setup by Ren</b></p>

<p align="center">
  <img src="https://img.shields.io/badge/Arch_Linux-1793d1?style=for-the-badge&logo=arch-linux&logoColor=white" alt="Arch Linux" />
  <img src="https://img.shields.io/badge/Hyprland-00a8cc?style=for-the-badge&logo=hyprland&logoColor=white" alt="Hyprland" />
  <img src="https://img.shields.io/badge/Quickshell-ff69b4?style=for-the-badge" alt="Quickshell" />
  <img src="https://img.shields.io/badge/Rust-ea7335?style=for-the-badge&logo=rust&logoColor=white" alt="Rust" />
</p>
</div>

<table align="center">
  <tr>
    <td align="center"><img src="assets/disco_elysium.webp" width="400"><br><b>Disco Elysium</b></td>
    <td align="center"><img src="assets/hollow_knight.webp" width="400"><br><b>Hollow Knight</b></td>
  </tr>
  <tr>
    <td align="center"><img src="assets/miku.webp" width="400"><br><b>Miku</b></td>
    <td align="center"><img src="assets/outer_wilds.webp" width="400"><br><b>Outer Wilds</b></td>
  </tr>
  <tr>
    <td colspan="2" align="center"><img src="assets/wallpicker.webp" width="600"><br><b>Wallpicker</b></td>
  </tr>
</table>

## ✦ Features

➢ **Dynamic Theming** : powered by `Pywal`. Select a wallpaper and colors instantly bleed into Hyprland, Kitty, Rofi, and Obsidian. 

➢ **Quickshell UI** : a custom, animated QML sidebar for media controls, power profiles, system tools, and draggable screen stickers.

➢ **Holograph TUI** : a Rust-based terminal interface to browse images and swap your Fastfetch avatar and sticker themes on the fly.

## ✦ Working File Structure

Here is an example of how your home directory will look once everything is set up. 

```text
/home/user/
 │
 ├── 📁 dotfiles/                  # The cloned repository
 │    ├── 📁 logo/holograph/       # Drop your Fastfetch theme folders here
 │    │    ├── 📁 /                # (Holograph themes)
 │    │    └── 📁 myTheme/   
 │    │
 │    ├── 📁 local/                # Hardware & local paths
 │    │    ├── hypr-local.conf     # Local configs
 │    │    └── post-wallpaper.env  # Obsidian vault path
 │    │
 │    └── 📁 ...                   # (Kitty, Rofi, Quickshell, Pywal configs)
 │
 ├── 📁 Pictures/
 │    └── 📁 Wallpapers/           # Drop your wallpapers here
 │                                 
 │
 └── 📁 Documents/
      └── 📁 Obsidian/
           └── 📁 Vault/           # Your personal Obsidian vault
                                   # (CSS snippets are auto-injected here)
```

## ✦ Installation

>  Built **exclusively** for **Arch Linux** and its derivatives.

Clone the repository and launch the Installer. Do **not** run as root.

```bash
git clone https://github.com/lorediggia/quantum ~/dotfiles
cd ~/dotfiles
chmod +x install.sh
./install.sh
```

_Existing configs are safely backed up to `~/.config-backup-YYYYMMDD`._

## ✦ Keybinds

<table>
  <tr>
    <td align="right"><kbd>SUPER</kbd> + <kbd>W</kbd></td>
    <td><b>Wallpicker</b> <i>(Select Wallpaper & Apply Theme)</i></td>
  </tr>
  <tr>
    <td align="right"><kbd>SUPER</kbd> + <kbd>X</kbd></td>
    <td>Toggle <b>Sidebar</b> <i>(Quickshell)</i></td>
  </tr>
  <tr>
    <td align="right"><kbd>SUPER</kbd> + <kbd>Enter</kbd></td>
    <td>Open Terminal <i>(Kitty)</i></td>
  </tr>
  <tr>
    <td align="right"><kbd>SUPER</kbd> + <kbd>CTRL</kbd> + <kbd>Enter</kbd></td>
    <td>Open App Launcher <i>(Rofi)</i></td>
  </tr>
  <tr>
    <td align="right"><kbd>SUPER</kbd> + <kbd>E</kbd></td>
    <td>File Manager <i>(Nautilus)</i></td>
  </tr>
  <tr>
    <td align="right"><kbd>SUPER</kbd> + <kbd>B</kbd></td>
    <td>Web Browser <i>(Zen)</i></td>
  </tr>
  <tr>
    <td align="right"><kbd>SUPER</kbd> + <kbd>S</kbd></td>
    <td>Interactive Screenshot</td>
  </tr>
  <tr>
    <td align="right"><kbd>SUPER</kbd> + <kbd>Q</kbd></td>
    <td>Close active window</td>
  </tr>
</table>

## ✦ Theming Engine

The system aesthetic is driven by the **Wallpicker** (SUPER + W).

1. `Awww` sets the wallpaper with a smooth transition.
2. `Pywal` extracts the dominant color palette.
3. Templates in `pywal/` generate configuration files.
4. Background `wal-hooks` instantly reload Kitty, Quickshell, and inject the new CSS into your Obsidian Vault.

## ✦ Holograph

Holograph is a TUI that organizes your Fastfetch stickers into theme folders, letting you swap them on the fly.

➢ **Add a New Theme**

1. Go to `~/dotfiles/logo/holograph/`
2. Create a new directory here (e.g. `.../holograph/MyTheme/`).
3. Drop your `.png`, `.jpg`, or `.webp` images inside.

➢ **Change Cover & Apply Theme**

1. Type `holograph` in your terminal.
2. Use the **arrow keys** to browse through your folders and images.
3. Press <kbd>C</kbd> to set the selected image as your Fastfetch **Cover**.
4. Press <kbd>Enter</kbd> to **Apply** the theme. Fastfetch updates automatically!

## ✦ Obsidian Integration

During the **Installation**, the script will ask for your Vault's location and automatically configure the path in `~/dotfiles/local/post-wallpaper.env`. 

1. Open Obsidian and navigate to `Settings` ➔ `Appearance`.
2. At the bottom of the menu, find the `CSS snippets` section.
3. Activate `pywal.css` and `layout-obsidian.css`.

Every time you use the **Wallpicker** (<kbd>SUPER</kbd> + <kbd>W</kbd>), the system generates a fresh palette and pushes it directly into your Vault. 

> If you move your Vault later, you can simply re-run the installer or update the path in your `local/` folder.

## ✦ Uninstaller

```
cd ~/dotfiles
./uninstall.sh
```

_Removes symlinks, clears caches, uninstalls downloaded packages, and restores your original backups._

## ✦ Credits 

⋄ [WhiteSur GTK](https://github.com/vinceliuice/WhiteSur-gtk-theme) 

⋄ [Bibata Cursors](https://github.com/ful1e5/Bibata_Cursor) 

⋄ [Pywal](https://github.com/dylanaraps/pywal) 

⋄ [awww](https://codeberg.org/LGFae/awww)

<div align="center">
  <br>
  <i>"The universe is, and we are."</i>
  <br>
  <br>
</div>
