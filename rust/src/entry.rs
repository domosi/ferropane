use serde::{Deserialize, Serialize};
use std::cmp::Ordering;

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[repr(u8)]
pub enum SortField {
    Name = 0,
    Extension = 1,
    Size = 2,
    Modified = 3,
}

impl SortField {
    pub fn from_u8(val: u8) -> Self {
        match val {
            1 => SortField::Extension,
            2 => SortField::Size,
            3 => SortField::Modified,
            _ => SortField::Name,
        }
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct DirEntry {
    pub name: String,
    pub stem: String,
    pub ext: String,
    pub full_path: String,
    pub size: u64,
    pub size_calculated: bool,
    pub modified_sec: i64,
    pub is_dir: bool,
    pub is_parent: bool,
    pub is_symlink: bool,
    pub is_hidden: bool,
    pub permissions: String,
    pub selected: bool,
}

impl DirEntry {
    pub fn parent_entry(parent_path: String) -> Self {
        Self {
            name: "..".to_string(),
            stem: "..".to_string(),
            ext: String::new(),
            full_path: parent_path,
            size: 0,
            size_calculated: false,
            modified_sec: 0,
            is_dir: true,
            is_parent: true,
            is_symlink: false,
            is_hidden: false,
            permissions: "drwxr-xr-x".to_string(),
            selected: false,
        }
    }
}

pub fn format_mode(mode: u32, is_dir: bool, is_symlink: bool) -> String {
    let file_type = if is_symlink {
        'l'
    } else if is_dir {
        'd'
    } else {
        '-'
    };
    let ur = if mode & 0o400 != 0 { 'r' } else { '-' };
    let uw = if mode & 0o200 != 0 { 'w' } else { '-' };
    let ux = if mode & 0o100 != 0 { 'x' } else { '-' };
    let gr = if mode & 0o040 != 0 { 'r' } else { '-' };
    let gw = if mode & 0o020 != 0 { 'w' } else { '-' };
    let gx = if mode & 0o010 != 0 { 'x' } else { '-' };
    let or = if mode & 0o004 != 0 { 'r' } else { '-' };
    let ow = if mode & 0o002 != 0 { 'w' } else { '-' };
    let ox = if mode & 0o001 != 0 { 'x' } else { '-' };
    format!("{file_type}{ur}{uw}{ux}{gr}{gw}{gx}{or}{ow}{ox}")
}

/// Natural case-insensitive comparison so "file2" < "file10"
pub fn natural_cmp(a: &str, b: &str) -> Ordering {
    let mut chars_a = a.chars().peekable();
    let mut chars_b = b.chars().peekable();

    while let (Some(&ca), Some(&cb)) = (chars_a.peek(), chars_b.peek()) {
        if ca.is_ascii_digit() && cb.is_ascii_digit() {
            let mut num_a: u64 = 0;
            while let Some(&d) = chars_a.peek() {
                if d.is_ascii_digit() {
                    num_a = num_a.saturating_mul(10).saturating_add((d as u8 - b'0') as u64);
                    chars_a.next();
                } else {
                    break;
                }
            }
            let mut num_b: u64 = 0;
            while let Some(&d) = chars_b.peek() {
                if d.is_ascii_digit() {
                    num_b = num_b.saturating_mul(10).saturating_add((d as u8 - b'0') as u64);
                    chars_b.next();
                } else {
                    break;
                }
            }
            match num_a.cmp(&num_b) {
                Ordering::Equal => continue,
                non_eq => return non_eq,
            }
        } else {
            let la = ca.to_ascii_lowercase();
            let lb = cb.to_ascii_lowercase();
            match la.cmp(&lb) {
                Ordering::Equal => {
                    chars_a.next();
                    chars_b.next();
                }
                non_eq => return non_eq,
            }
        }
    }

    match (chars_a.peek().is_some(), chars_b.peek().is_some()) {
        (true, false) => Ordering::Greater,
        (false, true) => Ordering::Less,
        _ => a.cmp(b),
    }
}

pub fn compare_entries(
    a: &DirEntry,
    b: &DirEntry,
    field: SortField,
    ascending: bool,
) -> Ordering {
    // ".." always stays at the very top
    if a.is_parent && !b.is_parent {
        return Ordering::Less;
    }
    if !a.is_parent && b.is_parent {
        return Ordering::Greater;
    }
    // Directories always come before files (Total Commander convention)
    if a.is_dir != b.is_dir {
        return if a.is_dir {
            Ordering::Less
        } else {
            Ordering::Greater
        };
    }

    let primary = match field {
        SortField::Name => natural_cmp(&a.name, &b.name),
        SortField::Extension => {
            let ext_cmp = natural_cmp(&a.ext, &b.ext);
            if ext_cmp == Ordering::Equal {
                natural_cmp(&a.stem, &b.stem)
            } else {
                ext_cmp
            }
        }
        SortField::Size => {
            let sz_cmp = a.size.cmp(&b.size);
            if sz_cmp == Ordering::Equal {
                natural_cmp(&a.name, &b.name)
            } else {
                sz_cmp
            }
        }
        SortField::Modified => {
            let mod_cmp = a.modified_sec.cmp(&b.modified_sec);
            if mod_cmp == Ordering::Equal {
                natural_cmp(&a.name, &b.name)
            } else {
                mod_cmp
            }
        }
    };

    if ascending {
        primary
    } else {
        primary.reverse()
    }
}
