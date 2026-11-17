use crate::entry::natural_cmp;
use serde::{Deserialize, Serialize};
use std::collections::BTreeMap;
use std::fs::{self, File};
use std::io::{BufReader, Read};
use std::path::{Path, PathBuf};
use std::time::UNIX_EPOCH;

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
pub struct CompareEntry {
    pub rel_path: String,
    pub is_dir: bool,
    /// "only_left", "only_right", "different", "identical"
    pub status: String,
    /// "left", "right", "same"
    pub newer_side: String,
    pub left_size: u64,
    pub right_size: u64,
    pub left_modified: i64,
    pub right_modified: i64,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct DirCompareResult {
    pub ok: bool,
    pub left_root: String,
    pub right_root: String,
    pub compare_content: bool,
    pub only_left_count: usize,
    pub only_right_count: usize,
    pub different_count: usize,
    pub identical_count: usize,
    pub items: Vec<CompareEntry>,
    pub error: Option<String>,
}

struct FileStatInfo {
    full_path: PathBuf,
    is_dir: bool,
    size: u64,
    modified_sec: i64,
}

pub fn compare_directories(
    left_dir: &str,
    right_dir: &str,
    compare_content: bool,
    show_hidden: bool,
) -> DirCompareResult {
    let left_root = PathBuf::from(left_dir);
    let right_root = PathBuf::from(right_dir);

    if !left_root.is_dir() || !right_root.is_dir() {
        return DirCompareResult {
            ok: false,
            left_root: left_dir.to_string(),
            right_root: right_dir.to_string(),
            compare_content,
            only_left_count: 0,
            only_right_count: 0,
            different_count: 0,
            identical_count: 0,
            items: Vec::new(),
            error: Some("Both panes must point to valid directories.".to_string()),
        };
    }

    let mut left_map: BTreeMap<String, FileStatInfo> = BTreeMap::new();
    let mut right_map: BTreeMap<String, FileStatInfo> = BTreeMap::new();

    collect_tree(&left_root, &left_root, show_hidden, &mut left_map, 25_000);
    collect_tree(&right_root, &right_root, show_hidden, &mut right_map, 25_000);

    let mut all_keys: Vec<String> = left_map
        .keys()
        .chain(right_map.keys())
        .cloned()
        .collect();
    all_keys.sort_by(|a, b| natural_cmp(a, b));
    all_keys.dedup();

    let mut only_left_count = 0usize;
    let mut only_right_count = 0usize;
    let mut different_count = 0usize;
    let mut identical_count = 0usize;
    let mut items = Vec::with_capacity(all_keys.len());

    for rel in all_keys {
        match (left_map.get(&rel), right_map.get(&rel)) {
            (Some(l), None) => {
                only_left_count += 1;
                items.push(CompareEntry {
                    rel_path: rel,
                    is_dir: l.is_dir,
                    status: "only_left".to_string(),
                    newer_side: "left".to_string(),
                    left_size: l.size,
                    right_size: 0,
                    left_modified: l.modified_sec,
                    right_modified: 0,
                });
            }
            (None, Some(r)) => {
                only_right_count += 1;
                items.push(CompareEntry {
                    rel_path: rel,
                    is_dir: r.is_dir,
                    status: "only_right".to_string(),
                    newer_side: "right".to_string(),
                    left_size: 0,
                    right_size: r.size,
                    left_modified: 0,
                    right_modified: r.modified_sec,
                });
            }
            (Some(l), Some(r)) => {
                if l.is_dir && r.is_dir {
                    identical_count += 1;
                    items.push(CompareEntry {
                        rel_path: rel,
                        is_dir: true,
                        status: "identical".to_string(),
                        newer_side: "same".to_string(),
                        left_size: 0,
                        right_size: 0,
                        left_modified: l.modified_sec,
                        right_modified: r.modified_sec,
                    });
                    continue;
                }

                let newer_side = if l.modified_sec > r.modified_sec {
                    "left"
                } else if r.modified_sec > l.modified_sec {
                    "right"
                } else {
                    "same"
                };

                let is_same = if l.is_dir != r.is_dir || l.size != r.size {
                    false
                } else if compare_content {
                    files_have_identical_bytes(&l.full_path, &r.full_path)
                } else {
                    // Consider timestamps within 1s identical unless size differs
                    (l.modified_sec - r.modified_sec).abs() <= 1
                };

                if is_same {
                    identical_count += 1;
                    items.push(CompareEntry {
                        rel_path: rel,
                        is_dir: l.is_dir,
                        status: "identical".to_string(),
                        newer_side: "same".to_string(),
                        left_size: l.size,
                        right_size: r.size,
                        left_modified: l.modified_sec,
                        right_modified: r.modified_sec,
                    });
                } else {
                    different_count += 1;
                    items.push(CompareEntry {
                        rel_path: rel,
                        is_dir: l.is_dir,
                        status: "different".to_string(),
                        newer_side: newer_side.to_string(),
                        left_size: l.size,
                        right_size: r.size,
                        left_modified: l.modified_sec,
                        right_modified: r.modified_sec,
                    });
                }
            }
            (None, None) => {}
        }
    }

    DirCompareResult {
        ok: true,
        left_root: left_dir.to_string(),
        right_root: right_dir.to_string(),
        compare_content,
        only_left_count,
        only_right_count,
        different_count,
        identical_count,
        items,
        error: None,
    }
}

fn collect_tree(
    root: &Path,
    current: &Path,
    show_hidden: bool,
    out: &mut BTreeMap<String, FileStatInfo>,
    max_entries: usize,
) {
    if out.len() >= max_entries {
        return;
    }
    let Ok(rd) = fs::read_dir(current) else {
        return;
    };
    for entry in rd.flatten() {
        if out.len() >= max_entries {
            break;
        }
        let name = entry.file_name().to_string_lossy().into_owned();
        if name == ".DS_Store" || (!show_hidden && name.starts_with('.')) {
            continue;
        }
        let path = entry.path();
        let Ok(rel) = path.strip_prefix(root) else {
            continue;
        };
        let rel_str = rel.to_string_lossy().into_owned();
        let Ok(ft) = entry.file_type() else {
            continue;
        };
        if ft.is_symlink() {
            continue;
        }
        let meta = entry.metadata();
        let (is_dir, size, modified_sec) = match meta {
            Ok(m) => {
                let d = m.is_dir();
                let sz = if d { 0 } else { m.len() };
                let mtime = m
                    .modified()
                    .ok()
                    .and_then(|t| t.duration_since(UNIX_EPOCH).ok())
                    .map(|dur| dur.as_secs() as i64)
                    .unwrap_or(0);
                (d, sz, mtime)
            }
            Err(_) => continue,
        };

        out.insert(
            rel_str,
            FileStatInfo {
                full_path: path.clone(),
                is_dir,
                size,
                modified_sec,
            },
        );

        if is_dir {
            collect_tree(root, &path, show_hidden, out, max_entries);
        }
    }
}

fn files_have_identical_bytes(a: &Path, b: &Path) -> bool {
    let (Ok(fa), Ok(fb)) = (File::open(a), File::open(b)) else {
        return false;
    };
    let mut ra = BufReader::with_capacity(64 * 1024, fa);
    let mut rb = BufReader::with_capacity(64 * 1024, fb);
    let mut buf_a = [0u8; 16384];
    let mut buf_b = [0u8; 16384];

    loop {
        let Ok(na) = ra.read(&mut buf_a) else {
            return false;
        };
        let Ok(nb) = rb.read(&mut buf_b) else {
            return false;
        };
        if na != nb {
            return false;
        }
        if na == 0 {
            return true;
        }
        if buf_a[..na] != buf_b[..nb] {
            return false;
        }
    }
}
