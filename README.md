# FerroPane

**FerroPane** is a high-speed, Total Commander-inspired dual-pane file manager for macOS built on a **Rust systems core (`cdylib`)** and a **pluggable 120Hz Flutter Desktop frontend** (supporting both **macOS Desktop UI** and **Material 3 UI**).

---

## Architecture Highlights

* **Zero-GC Rust Directory Engine (`rust/src/pane.rs`):** Holds directory buffers, natural collation sorting (`file2` < `file10`, directories-first), selection bitsets, and quick-filters in native Rust memory, serving only visible viewport slices synchronously over `dart:ffi`.
* **Native macOS APFS File Operations (`rust/src/ops.rs`):**
  * `F5 Copy`: Uses macOS APFS Copy-on-Write (`libc::clonefile(2)`) with `libc::copyfile(3)` fallback to preserve extended attributes (`xattr`), Finder metadata, and ACLs.
  * `F6 Move / Rename`: Atomic rename with cross-volume fallback.
  * `F7 MkDir`: Create directory (including nested paths).
  * `F8 Trash` / `Shift+F8 Delete`: Native macOS Trash (`NSFileManager.trashItem` via `trash`) or permanent POSIX removal.
* **Memory-Mapped `F3` Lister (`rust/src/lister.rs`):** Opens multi-gigabyte files in `< 1 ms` via `memmap2::Mmap` with instant Text (`1`) and 16-byte Hex (`3`) slice rendering.
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
| `⌘T` / `⌘W` | New folder tab / Close active tab |
| `⌘⇧.` | Toggle hidden dotfiles (`.*`) |
| `⌘Y` / `Option+Space` | Toggle native macOS Quick Look (`QLPreviewPanel`) |
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
