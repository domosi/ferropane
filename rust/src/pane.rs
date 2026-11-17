use crate::entry::{compare_entries, format_mode, DirEntry, SortField};
use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use std::ffi::CString;
use std::fs;
use std::os::unix::fs::MetadataExt;
use std::path::{Path, PathBuf};
use std::time::UNIX_EPOCH;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PaneSummary {
    pub current_path: String,
    pub total_rows: usize,
    pub total_files: usize,
    pub total_dirs: usize,
    pub selected_files: usize,
    pub selected_dirs: usize,
    pub selected_bytes: u64,
    pub total_bytes: u64,
    pub volume_free_bytes: u64,
    pub volume_total_bytes: u64,
    pub sort_field: u8,
    pub sort_ascending: bool,
    pub show_hidden: bool,
    pub filter_query: String,
    pub error_message: Option<String>,
}

pub struct PaneState {
    pub current_path: PathBuf,
    pub all_entries: Vec<DirEntry>,
    pub visible_indices: Vec<usize>,
    pub sort_field: SortField,
    pub sort_ascending: bool,
    pub show_hidden: bool,
    pub filter_query: String,
    pub calculated_dir_sizes: HashMap<String, u64>,
    pub volume_free_bytes: u64,
    pub volume_total_bytes: u64,
    pub last_error: Option<String>,
}

impl PaneState {
    pub fn new(initial_path: &str) -> Self {
        let home_dir = std::env::var("HOME")
            .map(PathBuf::from)
            .unwrap_or_else(|_| PathBuf::from("/"));

        let mut path = if initial_path.is_empty() {
            home_dir.clone()
        } else {
            PathBuf::from(initial_path)
        };

        if !path.exists() || !path.is_dir() {
            path = home_dir;
        }

        let mut state = Self {
            current_path: path.clone(),
            all_entries: Vec::new(),
            visible_indices: Vec::new(),
            sort_field: SortField::Name,
            sort_ascending: true,
            show_hidden: false,
            filter_query: String::new(),
            calculated_dir_sizes: HashMap::new(),
            volume_free_bytes: 0,
            volume_total_bytes: 0,
            last_error: None,
        };
        state.load_directory(&path);
        state
    }

    pub fn load_directory(&mut self, target: &Path) -> bool {
        let canonical = fs::canonicalize(target).unwrap_or_else(|_| target.to_path_buf());
        match fs::read_dir(&canonical) {
            Ok(read_dir) => {
                let mut entries = Vec::with_capacity(256);

                if let Some(parent) = canonical.parent() {
                    entries.push(DirEntry::parent_entry(
                        parent.to_string_lossy().into_owned(),
                    ));
                }

                for item in read_dir.flatten() {
                    let file_name = item.file_name().to_string_lossy().into_owned();
                    if file_name.is_empty() {
                        continue;
                    }
                    let full_path_buf = item.path();
                    let full_path = full_path_buf.to_string_lossy().into_owned();
                    let is_hidden = file_name.starts_with('.');

                    let symlink_meta = fs::symlink_metadata(&full_path_buf);
                    let is_symlink = symlink_meta
                        .as_ref()
                        .map(|m| m.file_type().is_symlink())
                        .unwrap_or(false);

                    let meta = fs::metadata(&full_path_buf).or(symlink_meta);
                    let (is_dir, mut size, modified_sec, mode) = match meta {
                        Ok(m) => {
                            let is_d = m.is_dir();
                            let sz = if is_d { 0 } else { m.len() };
                            let mtime = m
                                .modified()
                                .ok()
                                .and_then(|t| t.duration_since(UNIX_EPOCH).ok())
                                .map(|d| d.as_secs() as i64)
                                .unwrap_or(0);
                            (is_d, sz, mtime, m.mode())
                        }
                        Err(_) => (false, 0, 0, 0o644),
                    };

                    let mut size_calculated = !is_dir;
                    if is_dir {
                        if let Some(&cached_sz) = self.calculated_dir_sizes.get(&full_path) {
                            size = cached_sz;
                            size_calculated = true;
                        }
                    }

                    let (stem, ext) = if is_dir {
                        (file_name.clone(), String::new())
                    } else {
                        split_stem_ext(&file_name)
                    };

                    entries.push(DirEntry {
                        name: file_name,
                        stem,
                        ext,
                        full_path,
                        size,
                        size_calculated,
                        modified_sec,
                        is_dir,
                        is_parent: false,
                        is_symlink,
                        is_hidden,
                        permissions: format_mode(mode, is_dir, is_symlink),
                        selected: false,
                    });
                }

                self.current_path = canonical;
                self.all_entries = entries;
                self.filter_query.clear();
                self.last_error = None;
                self.update_volume_stats();
                self.rebuild_view();
                true
            }
            Err(err) => {
                self.last_error = Some(format!("Cannot open {}: {}", canonical.display(), err));
                false
            }
        }
    }

    pub fn reload(&mut self) {
        // Preserve selection across reload
        let previously_selected: std::collections::HashSet<String> = self
            .all_entries
            .iter()
            .filter(|e| e.selected)
            .map(|e| e.full_path.clone())
            .collect();
        let saved_filter = self.filter_query.clone();
        let current = self.current_path.clone();
        if self.load_directory(&current) {
            self.filter_query = saved_filter;
            for entry in &mut self.all_entries {
                if previously_selected.contains(&entry.full_path) {
                    entry.selected = true;
                }
            }
            self.rebuild_view();
        }
    }

    pub fn rebuild_view(&mut self) {
        let field = self.sort_field;
        let asc = self.sort_ascending;
        self.all_entries
            .sort_by(|a, b| compare_entries(a, b, field, asc));

        let query_lower = self.filter_query.to_lowercase();
        let show_hidden = self.show_hidden;

        self.visible_indices.clear();
        for (idx, entry) in self.all_entries.iter().enumerate() {
            if entry.is_parent {
                self.visible_indices.push(idx);
                continue;
            }
            if !show_hidden && entry.is_hidden {
                continue;
            }
            if !query_lower.is_empty() && !entry.name.to_lowercase().contains(&query_lower) {
                continue;
            }
            self.visible_indices.push(idx);
        }
    }

    pub fn set_sort(&mut self, field: SortField, ascending: bool) {
        self.sort_field = field;
        self.sort_ascending = ascending;
        self.rebuild_view();
    }

    pub fn set_show_hidden(&mut self, show: bool) {
        self.show_hidden = show;
        self.rebuild_view();
    }

    pub fn set_filter(&mut self, query: &str) {
        self.filter_query = query.to_string();
        self.rebuild_view();
    }

    pub fn toggle_select(&mut self, visible_row: usize, calculate_dir_on_space: bool) -> bool {
        let Some(&entry_idx) = self.visible_indices.get(visible_row) else {
            return false;
        };
        if self.all_entries[entry_idx].is_parent {
            return false;
        }
        let new_selected = !self.all_entries[entry_idx].selected;
        self.all_entries[entry_idx].selected = new_selected;

        if calculate_dir_on_space && self.all_entries[entry_idx].is_dir {
            let dir_path = self.all_entries[entry_idx].full_path.clone();
            let dir_size = compute_directory_size(Path::new(&dir_path));
            self.calculated_dir_sizes.insert(dir_path, dir_size);
            self.all_entries[entry_idx].size = dir_size;
            self.all_entries[entry_idx].size_calculated = true;
        }
        new_selected
    }

    pub fn select_all(&mut self, select: bool) {
        for &idx in &self.visible_indices {
            if !self.all_entries[idx].is_parent {
                self.all_entries[idx].selected = select;
            }
        }
    }

    pub fn invert_selection(&mut self) {
        for &idx in &self.visible_indices {
            if !self.all_entries[idx].is_parent && !self.all_entries[idx].is_dir {
                self.all_entries[idx].selected = !self.all_entries[idx].selected;
            }
        }
    }

    pub fn select_by_pattern(&mut self, pattern: &str, select: bool) {
        let pat = pattern.trim().to_lowercase();
        if pat.is_empty() {
            return;
        }
        for &idx in &self.visible_indices {
            let entry = &mut self.all_entries[idx];
            if entry.is_parent {
                continue;
            }
            if wildcard_match(&pat, &entry.name.to_lowercase()) {
                entry.selected = select;
            }
        }
    }

    pub fn get_visible_slice(&self, start: usize, count: usize) -> Vec<&DirEntry> {
        let total = self.visible_indices.len();
        if start >= total || count == 0 {
            return Vec::new();
        }
        let end = (start + count).min(total);
        self.visible_indices[start..end]
            .iter()
            .filter_map(|&idx| self.all_entries.get(idx))
            .collect()
    }

    pub fn summary(&self) -> PaneSummary {
        let mut total_files = 0usize;
        let mut total_dirs = 0usize;
        let mut selected_files = 0usize;
        let mut selected_dirs = 0usize;
        let mut selected_bytes = 0u64;
        let mut total_bytes = 0u64;

        for &idx in &self.visible_indices {
            let entry = &self.all_entries[idx];
            if entry.is_parent {
                continue;
            }
            if entry.is_dir {
                total_dirs += 1;
                if entry.selected {
                    selected_dirs += 1;
                    selected_bytes = selected_bytes.saturating_add(entry.size);
                }
            } else {
                total_files += 1;
                total_bytes = total_bytes.saturating_add(entry.size);
                if entry.selected {
                    selected_files += 1;
                    selected_bytes = selected_bytes.saturating_add(entry.size);
                }
            }
        }

        PaneSummary {
            current_path: self.current_path.to_string_lossy().into_owned(),
            total_rows: self.visible_indices.len(),
            total_files,
            total_dirs,
            selected_files,
            selected_dirs,
            selected_bytes,
            total_bytes,
            volume_free_bytes: self.volume_free_bytes,
            volume_total_bytes: self.volume_total_bytes,
            sort_field: self.sort_field as u8,
            sort_ascending: self.sort_ascending,
            show_hidden: self.show_hidden,
            filter_query: self.filter_query.clone(),
            error_message: self.last_error.clone(),
        }
    }

    fn update_volume_stats(&mut self) {
        let path_str = self.current_path.to_string_lossy();
        if let Ok(c_path) = CString::new(path_str.as_bytes()) {
            unsafe {
                let mut stat: libc::statfs = std::mem::zeroed();
                if libc::statfs(c_path.as_ptr(), &mut stat) == 0 {
                    let bsize = stat.f_bsize as u64;
                    self.volume_free_bytes = (stat.f_bavail as u64).saturating_mul(bsize);
                    self.volume_total_bytes = (stat.f_blocks as u64).saturating_mul(bsize);
                }
            }
        }
    }
}

fn split_stem_ext(name: &str) -> (String, String) {
    // Hidden dotfiles like ".gitignore" have stem ".gitignore" and empty ext
    if let Some(dot_pos) = name.rfind('.') {
        if dot_pos > 0 && dot_pos < name.len() - 1 {
            return (
                name[..dot_pos].to_string(),
                name[dot_pos + 1..].to_string(),
            );
        }
    }
    (name.to_string(), String::new())
}

pub fn compute_directory_size(path: &Path) -> u64 {
    let mut total: u64 = 0;
    let mut stack = vec![path.to_path_buf()];
    let mut visited_files = 0usize;
    // Cap traversal at 100k entries so pressing Space on / doesn't freeze
    while let Some(curr) = stack.pop() {
        if visited_files > 100_000 {
            break;
        }
        if let Ok(rd) = fs::read_dir(&curr) {
            for entry in rd.flatten() {
                visited_files += 1;
                if let Ok(ft) = entry.file_type() {
                    if ft.is_symlink() {
                        continue;
                    }
                    if ft.is_dir() {
                        stack.push(entry.path());
                    } else if ft.is_file() {
                        if let Ok(m) = entry.metadata() {
                            total = total.saturating_add(m.len());
                        }
                    }
                }
            }
        }
    }
    total
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
            if !text[pos..].ends_with(part) {
                return false;
            }
            return true;
        } else if let Some(found) = text[pos..].find(part) {
            pos += found + part.len();
        } else {
            return false;
        }
    }
    true
}
