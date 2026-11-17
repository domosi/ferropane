use serde::{Deserialize, Serialize};
use std::ffi::CString;
use std::fs;
use std::path::{Path, PathBuf};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct FileOpResult {
    pub ok: bool,
    pub processed_count: usize,
    pub message: String,
}

#[cfg(target_os = "macos")]
fn macos_clone_or_copy_file(src: &Path, dst: &Path) -> std::io::Result<()> {
    let src_c = CString::new(src.to_string_lossy().as_bytes())
        .map_err(|e| std::io::Error::new(std::io::ErrorKind::InvalidInput, e))?;
    let dst_c = CString::new(dst.to_string_lossy().as_bytes())
        .map_err(|e| std::io::Error::new(std::io::ErrorKind::InvalidInput, e))?;

    unsafe {
        // Try APFS Copy-on-Write clonefile(2) first (0 = default flags)
        if dst.exists() {
            let _ = fs::remove_file(dst);
        }
        let clone_rc = libc::clonefile(src_c.as_ptr(), dst_c.as_ptr(), 0);
        if clone_rc == 0 {
            return Ok(());
        }
        // Fallback to macOS copyfile(3) preserving extended attributes, ACLs, stat, data
        // COPYFILE_ALL = 15 (ACL | STAT | XATTR | DATA)
        let copy_rc = libc::copyfile(
            src_c.as_ptr(),
            dst_c.as_ptr(),
            std::ptr::null_mut(),
            15,
        );
        if copy_rc == 0 {
            return Ok(());
        }
    }
    fs::copy(src, dst).map(|_| ())
}

#[cfg(not(target_os = "macos"))]
fn macos_clone_or_copy_file(src: &Path, dst: &Path) -> std::io::Result<()> {
    fs::copy(src, dst).map(|_| ())
}

fn copy_path_recursive(src: &Path, dst: &Path) -> std::io::Result<usize> {
    let meta = fs::symlink_metadata(src)?;
    if meta.file_type().is_symlink() {
        let target = fs::read_link(src)?;
        if dst.exists() {
            let _ = fs::remove_file(dst);
        }
        #[cfg(unix)]
        std::os::unix::fs::symlink(target, dst)?;
        return Ok(1);
    }

    if meta.is_dir() {
        fs::create_dir_all(dst)?;
        let mut count = 1usize;
        for entry in fs::read_dir(src)? {
            let entry = entry?;
            let child_src = entry.path();
            let child_dst = dst.join(entry.file_name());
            count += copy_path_recursive(&child_src, &child_dst)?;
        }
        Ok(count)
    } else {
        if let Some(parent) = dst.parent() {
            fs::create_dir_all(parent)?;
        }
        macos_clone_or_copy_file(src, dst)?;
        Ok(1)
    }
}

pub fn copy_items(sources: &[String], dest_dir: &str) -> FileOpResult {
    let dst_root = PathBuf::from(dest_dir);
    if !dst_root.exists() {
        if let Err(e) = fs::create_dir_all(&dst_root) {
            return FileOpResult {
                ok: false,
                processed_count: 0,
                message: format!("Failed to create destination {}: {}", dest_dir, e),
            };
        }
    }

    let mut total_copied = 0usize;
    for src_str in sources {
        let src_path = PathBuf::from(src_str);
        let Some(file_name) = src_path.file_name() else {
            continue;
        };
        let mut target_path = dst_root.join(file_name);
        // If copying into the exact same directory, create "<name> copy"
        if target_path == src_path {
            let stem = src_path
                .file_stem()
                .map(|s| s.to_string_lossy().into_owned())
                .unwrap_or_else(|| "item".to_string());
            let ext = src_path
                .extension()
                .map(|e| format!(".{}", e.to_string_lossy()))
                .unwrap_or_default();
            target_path = dst_root.join(format!("{stem} copy{ext}"));
        }

        match copy_path_recursive(&src_path, &target_path) {
            Ok(c) => total_copied += c,
            Err(e) => {
                return FileOpResult {
                    ok: false,
                    processed_count: total_copied,
                    message: format!("Error copying {}: {}", src_path.display(), e),
                };
            }
        }
    }

    FileOpResult {
        ok: true,
        processed_count: total_copied,
        message: format!("Copied {} item(s)", sources.len()),
    }
}

pub fn move_items(sources: &[String], dest_dir: &str) -> FileOpResult {
    let dst_root = PathBuf::from(dest_dir);
    // If only 1 source is passed and dest_dir doesn't exist or looks like a rename target:
    if sources.len() == 1 && !dst_root.is_dir() {
        let src_path = PathBuf::from(&sources[0]);
        match fs::rename(&src_path, &dst_root) {
            Ok(()) => {
                return FileOpResult {
                    ok: true,
                    processed_count: 1,
                    message: format!("Renamed to {}", dst_root.display()),
                };
            }
            Err(e) => {
                return FileOpResult {
                    ok: false,
                    processed_count: 0,
                    message: format!("Failed to move/rename: {}", e),
                };
            }
        }
    }

    let mut moved = 0usize;
    for src_str in sources {
        let src_path = PathBuf::from(src_str);
        let Some(file_name) = src_path.file_name() else {
            continue;
        };
        let target_path = dst_root.join(file_name);
        if target_path == src_path {
            continue;
        }
        if fs::rename(&src_path, &target_path).is_ok() {
            moved += 1;
        } else {
            match copy_path_recursive(&src_path, &target_path) {
                Ok(_) => {
                    let remove_res = if src_path.is_dir() {
                        fs::remove_dir_all(&src_path)
                    } else {
                        fs::remove_file(&src_path)
                    };
                    if let Err(e) = remove_res {
                        return FileOpResult {
                            ok: false,
                            processed_count: moved,
                            message: format!(
                                "Copied {} but failed to remove original: {}",
                                src_path.display(),
                                e
                            ),
                        };
                    }
                    moved += 1;
                }
                Err(e) => {
                    return FileOpResult {
                        ok: false,
                        processed_count: moved,
                        message: format!("Failed to move {}: {}", src_path.display(), e),
                    };
                }
            }
        }
    }

    FileOpResult {
        ok: true,
        processed_count: moved,
        message: format!("Moved {} item(s)", moved),
    }
}

pub fn create_directory(base_dir: &str, name: &str) -> FileOpResult {
    let trimmed = name.trim();
    if trimmed.is_empty() {
        return FileOpResult {
            ok: false,
            processed_count: 0,
            message: "Directory name cannot be empty".to_string(),
        };
    }
    let target = if Path::new(trimmed).is_absolute() {
        PathBuf::from(trimmed)
    } else {
        PathBuf::from(base_dir).join(trimmed)
    };

    match fs::create_dir_all(&target) {
        Ok(()) => FileOpResult {
            ok: true,
            processed_count: 1,
            message: format!("Created {}", target.display()),
        },
        Err(e) => FileOpResult {
            ok: false,
            processed_count: 0,
            message: format!("Failed to create directory {}: {}", target.display(), e),
        },
    }
}

pub fn delete_items(sources: &[String], use_trash: bool) -> FileOpResult {
    if sources.is_empty() {
        return FileOpResult {
            ok: false,
            processed_count: 0,
            message: "No items selected".to_string(),
        };
    }

    if use_trash {
        match trash::delete_all(sources) {
            Ok(()) => {
                return FileOpResult {
                    ok: true,
                    processed_count: sources.len(),
                    message: format!("Moved {} item(s) to Trash", sources.len()),
                };
            }
            Err(err) => {
                return FileOpResult {
                    ok: false,
                    processed_count: 0,
                    message: format!("Trash failed: {}", err),
                };
            }
        }
    }

    let mut deleted = 0usize;
    for src_str in sources {
        let p = PathBuf::from(src_str);
        let res = match fs::symlink_metadata(&p) {
            Ok(m) if m.is_dir() && !m.file_type().is_symlink() => fs::remove_dir_all(&p),
            _ => fs::remove_file(&p),
        };
        match res {
            Ok(()) => deleted += 1,
            Err(e) => {
                return FileOpResult {
                    ok: false,
                    processed_count: deleted,
                    message: format!("Failed to delete {}: {}", p.display(), e),
                };
            }
        }
    }

    FileOpResult {
        ok: true,
        processed_count: deleted,
        message: format!("Permanently deleted {} item(s)", deleted),
    }
}
