use crate::entry::natural_cmp;
use serde::{Deserialize, Serialize};
use std::cmp::Ordering;
use std::fs;
use std::io::Read;
use std::path::Path;
use std::time::UNIX_EPOCH;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SearchHitItem {
    pub name: String,
    pub rel_path: String,
    pub full_path: String,
    pub parent_dir: String,
    pub is_dir: bool,
    pub size: u64,
    pub modified_sec: i64,
    pub is_prefix_match: bool,
    pub matched_line: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct DirSearchResult {
    pub ok: bool,
    pub root_dir: String,
    pub scanned_count: usize,
    pub items: Vec<SearchHitItem>,
    pub error: Option<String>,
}

pub fn search_directory(
    root_dir: &str,
    name_query: &str,
    content_query: &str,
    recursive: bool,
    show_hidden: bool,
    max_results: usize,
) -> DirSearchResult {
    let root_path = Path::new(root_dir);
    if !root_path.exists() || !root_path.is_dir() {
        return DirSearchResult {
            ok: false,
            root_dir: root_dir.to_string(),
            scanned_count: 0,
            items: Vec::new(),
            error: Some(format!("Directory does not exist: {}", root_dir)),
        };
    }

    let q_name = name_query.trim().to_lowercase();
    let q_content = content_query.trim().to_lowercase();
    let has_wildcard = q_name.contains('*');
    let cap = if max_results == 0 { 300 } else { max_results };

    let mut hits: Vec<SearchHitItem> = Vec::new();
    let mut scanned = 0usize;
    let mut stack = vec![root_path.to_path_buf()];

    while let Some(dir) = stack.pop() {
        if scanned >= 40_000 || hits.len() >= cap * 2 {
            break;
        }
        let Ok(rd) = fs::read_dir(&dir) else {
            continue;
        };

        for entry in rd.flatten() {
            scanned += 1;
            if scanned >= 40_000 {
                break;
            }
            let file_name = entry.file_name().to_string_lossy().into_owned();
            if file_name.is_empty() {
                continue;
            }
            let is_hidden = file_name.starts_with('.');
            if !show_hidden && is_hidden {
                continue;
            }

            let entry_path = entry.path();
            let Ok(ft) = entry.file_type() else {
                continue;
            };
            if ft.is_symlink() {
                continue;
            }
            let is_dir = ft.is_dir();

            if is_dir && recursive {
                // Skip heavy build/cache folders unless show_hidden is true
                if !show_hidden
                    && matches!(
                        file_name.as_str(),
                        "node_modules" | "target" | "build" | "Pods" | "DerivedData"
                    )
                {
                    // still check if the folder name itself matches the query before skipping recursion
                } else {
                    stack.push(entry_path.clone());
                }
            }

            let name_lower = file_name.to_lowercase();
            let (name_matched, is_prefix) = if q_name.is_empty() {
                (true, false)
            } else if has_wildcard {
                (
                    wildcard_match(&q_name, &name_lower),
                    name_lower.starts_with(q_name.trim_start_matches('*')),
                )
            } else {
                let starts = name_lower.starts_with(&q_name);
                let contains = starts || name_lower.contains(&q_name);
                (contains, starts)
            };

            if !name_matched {
                continue;
            }

            // If content_query is provided, only files containing content_query match
            let mut matched_line: Option<String> = None;
            if !q_content.is_empty() {
                if is_dir {
                    continue;
                }
                match find_content_snippet(&entry_path, &q_content) {
                    Some(snippet) => matched_line = Some(snippet),
                    None => continue,
                }
            }

            let (size, modified_sec) = match entry.metadata() {
                Ok(m) => {
                    let sz = if is_dir { 0 } else { m.len() };
                    let mtime = m
                        .modified()
                        .ok()
                        .and_then(|t| t.duration_since(UNIX_EPOCH).ok())
                        .map(|d| d.as_secs() as i64)
                        .unwrap_or(0);
                    (sz, mtime)
                }
                Err(_) => (0, 0),
            };

            let rel_path = entry_path
                .strip_prefix(root_path)
                .unwrap_or(&entry_path)
                .to_string_lossy()
                .into_owned();
            let parent_dir = entry_path
                .parent()
                .unwrap_or(root_path)
                .to_string_lossy()
                .into_owned();

            hits.push(SearchHitItem {
                name: file_name,
                rel_path,
                full_path: entry_path.to_string_lossy().into_owned(),
                parent_dir,
                is_dir,
                size,
                modified_sec,
                is_prefix_match: is_prefix,
                matched_line,
            });
        }
    }

    // Rank prefix matches first, then directories, then natural filename order
    hits.sort_by(|a, b| {
        if a.is_prefix_match != b.is_prefix_match {
            return if a.is_prefix_match {
                Ordering::Less
            } else {
                Ordering::Greater
            };
        }
        let depth_a = a.rel_path.matches('/').count();
        let depth_b = b.rel_path.matches('/').count();
        if depth_a != depth_b {
            return depth_a.cmp(&depth_b);
        }
        if a.is_dir != b.is_dir {
            return if a.is_dir {
                Ordering::Less
            } else {
                Ordering::Greater
            };
        }
        natural_cmp(&a.name, &b.name)
    });

    if hits.len() > cap {
        hits.truncate(cap);
    }

    DirSearchResult {
        ok: true,
        root_dir: root_dir.to_string(),
        scanned_count: scanned,
        items: hits,
        error: None,
    }
}

fn find_content_snippet(path: &Path, query_lower: &str) -> Option<String> {
    let meta = fs::metadata(path).ok()?;
    if meta.len() == 0 || meta.len() > 4 * 1024 * 1024 {
        return None;
    }
    let mut f = fs::File::open(path).ok()?;
    let mut buf = Vec::with_capacity((meta.len() as usize).min(512 * 1024));
    f.by_ref().take(512 * 1024).read_to_end(&mut buf).ok()?;
    // Skip binary files containing null bytes in the first 1024 bytes
    let check_len = buf.len().min(1024);
    if buf[..check_len].contains(&0) {
        return None;
    }
    let text = String::from_utf8_lossy(&buf);
    for (idx, line) in text.lines().enumerate() {
        if line.to_lowercase().contains(query_lower) {
            let trimmed = line.trim();
            let snippet = if trimmed.chars().count() > 96 {
                let s: String = trimmed.chars().take(96).collect();
                format!("L{}: {}…", idx + 1, s)
            } else {
                format!("L{}: {}", idx + 1, trimmed)
            };
            return Some(snippet);
        }
    }
    None
}

fn wildcard_match(pattern: &str, text: &str) -> bool {
    if pattern == "*" || pattern == "*.*" {
        return true;
    }
    let parts: Vec<&str> = pattern.split('*').collect();
    if parts.len() == 1 {
        return text.contains(pattern);
    }
    let mut pos = 0usize;
    for (i, part) in parts.iter().enumerate() {
        if part.is_empty() {
            continue;
        }
        if i == 0 && !pattern.starts_with('*') {
            if !text.starts_with(part) {
                return false;
            }
            pos = part.len();
        } else if i == parts.len() - 1 && !pattern.ends_with('*') {
            return text[pos..].ends_with(part);
        } else if let Some(found) = text[pos..].find(part) {
            pos += found + part.len();
        } else {
            return false;
        }
    }
    true
}
