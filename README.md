# FerroPane

[![Build & Publish macOS Release](https://github.com/domosi/ferropane/actions/workflows/release.yml/badge.svg)](https://github.com/domosi/ferropane/actions/workflows/release.yml)
[![Latest Release](https://img.shields.io/github/v/release/domosi/ferropane?include_prereleases&label=Download%20macOS%20App)](https://github.com/domosi/ferropane/releases)

**FerroPane** is a high-speed, Total Commander-inspired dual-pane file manager for macOS built on a **Rust systems core (`cdylib`)** and a **pluggable 120Hz Flutter Desktop frontend** (supporting both **macOS Desktop UI** and **Material 3 UI**).

---

## Download (No Build Required — Apple Notarized)

Grab the signed & Apple-notarized macOS Apple Silicon (`M1` / `M2` / `M3` / `M4`) app directly from [**GitHub Releases**](https://github.com/domosi/ferropane/releases):

* **[Download `FerroPane-macos-arm64.dmg`](https://github.com/domosi/ferropane/releases/latest/download/FerroPane-macos-arm64.dmg)** — Open the `.dmg` and drag `FerroPane.app` into `Applications`.
* **[Download `FerroPane-macos-arm64.zip`](https://github.com/domosi/ferropane/releases/latest/download/FerroPane-macos-arm64.zip)** — Portable `.app` bundle archive.

---

## Architecture Highlights

* **Zero-GC Rust Directory Engine (`rust/src/pane.rs`):** Holds directory buffers, natural collation sorting (`file2` < `file10`, directories-first), selection bitsets, and quick-filters in native Rust memory, serving only visible viewport slices synchronously over `dart:ffi`.
* **Native macOS APFS File Operations (`rust/src/ops.rs`):**
  * `F5 Copy`: Uses macOS APFS Copy-on-Write (`libc::clonefile(2)`) with `libc::copyfile(3)` fallback to preserve extended attributes (`xattr`), Finder metadata, and ACLs.
  * `F6 Move / Rename`: Atomic rename with cross-volume fallback.
  * `F7 MkDir`: Create directory (including nested paths).
  * `F8 Trash` / `Shift+F8 Delete`: Native macOS Trash (`NSFileManager.trashItem` via `trash`) or permanent POSIX removal.
* **Memory-Mapped `F3` Lister (`rust/src/lister.rs`):** Opens multi-gigabyte files in `< 1 ms` via `memmap2::Mmap` with instant Text (`1`) and 16-byte Hex (`3`) slice rendering.
* **Recursive Folder Deep Compare & Synchronize (`rust/src/compare.rs`):**
  * Press `⌘D` (or click **Compare** in the toolbar) to recursively compare the active Left and Right directory trees.
  * Classifies items into `→ Only Left`, `≠ Different` (`L newer` / `R newer`), `← Only Right`, and `= Identical`, with optional 64 KB buffered **Byte-by-Byte Content Verification**.
  * Supports 1-click single-file sync and batch synchronization (`Sync Left → Right` / `Sync Right ← Left`).
* **Native macOS LaunchServices ("Open With…") & Quick Look (`macos/Runner/MainFlutterWindow.swift`):**
  * Queries `NSWorkspace.shared.urlsForApplications(toOpen:)` for compatible macOS `.app` bundles.
  * Exposes 3 workflows: **`⇧Enter` / `⌘O` Numbered App Palette (`1`–`9`)**, **`Right-Click` Context Menu**, and **Smart `F4 Open With ▾`** (with per-extension remembered editor support).
  * Native macOS Quick Look preview (`QLPreviewPanel` via `⌘Y` or `Option+Space`).
* **Dual Pluggable UI Engines & 5 Semantic Themes:**
  * Switchable between **macOS Desktop UI (`CupertinoApp`)** and **Material 3 UI (`MaterialApp`)** via the top-right dropdown or `⌘U`.
  * Includes 5 semantic themes (`Dark`, `Day`, `TC Blue`, `Dracula`, `Emerald`) with 3-tier visual contrast hierarchy.

---

## Keyboard Shortcuts

| Shortcut | Action |
| :--- | :--- |
| `Tab` | Switch active pane (Left $\leftrightarrow$ Right) |
| `↑` / `↓` / `PgUp` / `PgDn` / `Home` / `End` | Navigate file list |
| `Enter` | Enter directory or open file with default macOS app |
| `⇧Enter` or `⌘O` | Open **"Open With…"** numbered app palette (`1`–`9`) |
| `Backspace` | Navigate to parent directory (`..`) |
| `Space` | Toggle selection & calculate recursive directory size |
| `Insert` / `⇧↓` | Toggle selection and advance cursor |
| `*` / `+` | Invert selection / Select by wildcard pattern |
| `/` or `⌘F` | Toggle inline Quick Filter bar |
| `⌘G` | Go to directory path |
| `⌘B` / `Ctrl+D` | Open **★ Directory Hotlist & macOS Favorites** (`1`–`9` instant jump, `P` to pin/unpin) |
| `⌘T` / `⌘W` | New folder tab / Close active tab |
| `⌘⇧.` | Toggle hidden dotfiles (`.*`) |
| `⌘Y` / `Option+Space` | Toggle native macOS Quick Look (`QLPreviewPanel`) |
| `⌘D` | Open **Folder Deep Compare & Synchronize** modal |
| `F3` / `⌘3` | Open built-in `mmap` Lister (`1`: Text, `3`: Hex) |
| `F4` / `⇧F4` / `⌘4` | Smart Open With (opens remembered editor for `.ext` or app picker) |
| `F5` / `⌘5` | Copy selected items (APFS `clonefile`/`copyfile`) |
| `F6` / `⌘6` | Move / Rename selected items |
| `F7` / `⌘7` | Create new directory |
| `F8` / `⌘8` / `⌘⌫` | Move selected items to macOS Trash (`⇧F8` for permanent delete) |
| `⌘U` | Switch UI Engine (`macOS Desktop UI` $\leftrightarrow$ `Material 3 UI`) |

---

## Building & Running on macOS

### Prerequisites
* **Rust** (`rustup` stable `aarch64-apple-darwin`)
* **Flutter** (`3.40+` stable)
* **Apple Command Line Tools** (`xcode-select --install`) — *Full `Xcode.app` is not required when using `./scripts/run_macos_no_xcode.sh`.*

### Build & Install `/Applications/FerroPane.app`
```zsh
./scripts/run_macos_no_xcode.sh
```

### Running Tests
```zsh
# Rust core unit tests
cd rust && cargo test

# Flutter + Rust FFI integration tests
flutter analyze && flutter test
```

---

## License
MIT
