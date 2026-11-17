use memmap2::Mmap;
use serde::{Deserialize, Serialize};
use std::fs::File;
use std::path::Path;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ListerSlice {
    pub ok: bool,
    pub file_path: String,
    pub file_size: u64,
    pub offset: u64,
    pub length: usize,
    pub is_binary: bool,
    pub mode: String, // "text" or "hex"
    pub content: String,
    pub error: Option<String>,
}

pub fn read_lister_slice(
    file_path: &str,
    offset: u64,
    max_bytes: usize,
    hex_mode: bool,
) -> ListerSlice {
    let path = Path::new(file_path);
    let file = match File::open(path) {
        Ok(f) => f,
        Err(e) => {
            return ListerSlice {
                ok: false,
                file_path: file_path.to_string(),
                file_size: 0,
                offset: 0,
                length: 0,
                is_binary: false,
                mode: if hex_mode { "hex" } else { "text" }.to_string(),
                content: String::new(),
                error: Some(format!("Cannot open file: {}", e)),
            };
        }
    };

    let file_size = file.metadata().map(|m| m.len()).unwrap_or(0);
    if file_size == 0 {
        return ListerSlice {
            ok: true,
            file_path: file_path.to_string(),
            file_size: 0,
            offset: 0,
            length: 0,
            is_binary: false,
            mode: if hex_mode { "hex" } else { "text" }.to_string(),
            content: "(Empty file — 0 bytes)".to_string(),
            error: None,
        };
    }

    let mmap = match unsafe { Mmap::map(&file) } {
        Ok(m) => m,
        Err(e) => {
            return ListerSlice {
                ok: false,
                file_path: file_path.to_string(),
                file_size,
                offset: 0,
                length: 0,
                is_binary: false,
                mode: if hex_mode { "hex" } else { "text" }.to_string(),
                content: String::new(),
                error: Some(format!("mmap failed: {}", e)),
            };
        }
    };

    let safe_offset = (offset as usize).min(mmap.len().saturating_sub(1));
    let cap = max_bytes.clamp(512, 256 * 1024);
    let end = (safe_offset + cap).min(mmap.len());
    let slice = &mmap[safe_offset..end];

    let sample_end = mmap.len().min(4096);
    let is_binary = mmap[..sample_end].contains(&0);

    let use_hex = hex_mode || (is_binary && offset == 0 && hex_mode);
    let content = if use_hex {
        format_hex_dump(slice, safe_offset as u64)
    } else {
        String::from_utf8_lossy(slice).into_owned()
    };

    ListerSlice {
        ok: true,
        file_path: file_path.to_string(),
        file_size,
        offset: safe_offset as u64,
        length: slice.len(),
        is_binary,
        mode: if use_hex { "hex" } else { "text" }.to_string(),
        content,
        error: None,
    }
}

fn format_hex_dump(bytes: &[u8], base_offset: u64) -> String {
    let mut out = String::with_capacity(bytes.len() * 4);
    for (row_idx, chunk) in bytes.chunks(16).enumerate() {
        let row_addr = base_offset + (row_idx as u64 * 16);
        out.push_str(&format!("{:08X}  ", row_addr));

        for i in 0..16 {
            if i < chunk.len() {
                out.push_str(&format!("{:02X} ", chunk[i]));
            } else {
                out.push_str("   ");
            }
            if i == 7 {
                out.push(' ');
            }
        }
        out.push_str(" |");
        for &b in chunk {
            let ch = if (0x20..=0x7E).contains(&b) {
                b as char
            } else {
                '.'
            };
            out.push(ch);
        }
        out.push_str("|\n");
    }
    out
}
