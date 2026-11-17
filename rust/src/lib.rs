pub mod entry;
pub mod lister;
pub mod ops;
pub mod pane;

use entry::SortField;
use pane::PaneState;
use std::collections::HashMap;
use std::ffi::{CStr, CString};
use std::os::raw::c_char;
use std::sync::{Mutex, OnceLock};

struct EngineRegistry {
    next_id: u32,
    panes: HashMap<u32, PaneState>,
}

static REGISTRY: OnceLock<Mutex<EngineRegistry>> = OnceLock::new();

fn registry() -> &'static Mutex<EngineRegistry> {
    REGISTRY.get_or_init(|| {
        Mutex::new(EngineRegistry {
            next_id: 1,
            panes: HashMap::new(),
        })
    })
}

fn cstr_to_string(ptr: *const c_char) -> String {
    if ptr.is_null() {
        return String::new();
    }
    unsafe { CStr::from_ptr(ptr).to_string_lossy().into_owned() }
}

fn string_to_cchar(s: String) -> *mut c_char {
    CString::new(s)
        .unwrap_or_else(|_| CString::new("{}").unwrap())
        .into_raw()
}

#[no_mangle]
pub extern "C" fn tc_string_free(ptr: *mut c_char) {
    if !ptr.is_null() {
        unsafe {
            let _ = CString::from_raw(ptr);
        }
    }
}

#[no_mangle]
pub extern "C" fn tc_pane_create(initial_path: *const c_char) -> u32 {
    let path = cstr_to_string(initial_path);
    let pane = PaneState::new(&path);
    let mut reg = registry().lock().unwrap();
    let id = reg.next_id;
    reg.next_id += 1;
    reg.panes.insert(id, pane);
    id
}

#[no_mangle]
pub extern "C" fn tc_pane_destroy(pane_id: u32) {
    let mut reg = registry().lock().unwrap();
    reg.panes.remove(&pane_id);
}

#[no_mangle]
pub extern "C" fn tc_pane_load_dir(pane_id: u32, path_ptr: *const c_char) -> bool {
    let path_str = cstr_to_string(path_ptr);
    let mut reg = registry().lock().unwrap();
    if let Some(pane) = reg.panes.get_mut(&pane_id) {
        pane.load_directory(std::path::Path::new(&path_str))
    } else {
        false
    }
}

#[no_mangle]
pub extern "C" fn tc_pane_reload(pane_id: u32) {
    let mut reg = registry().lock().unwrap();
    if let Some(pane) = reg.panes.get_mut(&pane_id) {
        pane.reload();
    }
}

#[no_mangle]
pub extern "C" fn tc_pane_set_sort(pane_id: u32, sort_field: u8, ascending: bool) {
    let mut reg = registry().lock().unwrap();
    if let Some(pane) = reg.panes.get_mut(&pane_id) {
        pane.set_sort(SortField::from_u8(sort_field), ascending);
    }
}

#[no_mangle]
pub extern "C" fn tc_pane_set_hidden(pane_id: u32, show_hidden: bool) {
    let mut reg = registry().lock().unwrap();
    if let Some(pane) = reg.panes.get_mut(&pane_id) {
        pane.set_show_hidden(show_hidden);
    }
}

#[no_mangle]
pub extern "C" fn tc_pane_set_filter(pane_id: u32, query_ptr: *const c_char) {
    let query = cstr_to_string(query_ptr);
    let mut reg = registry().lock().unwrap();
    if let Some(pane) = reg.panes.get_mut(&pane_id) {
        pane.set_filter(&query);
    }
}

#[no_mangle]
pub extern "C" fn tc_pane_toggle_select(
    pane_id: u32,
    visible_row: usize,
    calc_dir_size: bool,
) -> bool {
    let mut reg = registry().lock().unwrap();
    if let Some(pane) = reg.panes.get_mut(&pane_id) {
        pane.toggle_select(visible_row, calc_dir_size)
    } else {
        false
    }
}

#[no_mangle]
pub extern "C" fn tc_pane_select_all(pane_id: u32, select: bool) {
    let mut reg = registry().lock().unwrap();
    if let Some(pane) = reg.panes.get_mut(&pane_id) {
        pane.select_all(select);
    }
}

#[no_mangle]
pub extern "C" fn tc_pane_invert_selection(pane_id: u32) {
    let mut reg = registry().lock().unwrap();
    if let Some(pane) = reg.panes.get_mut(&pane_id) {
        pane.invert_selection();
    }
}

#[no_mangle]
pub extern "C" fn tc_pane_select_pattern(
    pane_id: u32,
    pattern_ptr: *const c_char,
    select: bool,
) {
    let pattern = cstr_to_string(pattern_ptr);
    let mut reg = registry().lock().unwrap();
    if let Some(pane) = reg.panes.get_mut(&pane_id) {
        pane.select_by_pattern(&pattern, select);
    }
}

#[no_mangle]
pub extern "C" fn tc_pane_summary_json(pane_id: u32) -> *mut c_char {
    let reg = registry().lock().unwrap();
    if let Some(pane) = reg.panes.get(&pane_id) {
        let sum = pane.summary();
        let json = serde_json::to_string(&sum).unwrap_or_else(|_| "{}".to_string());
        string_to_cchar(json)
    } else {
        string_to_cchar("{}".to_string())
    }
}

#[no_mangle]
pub extern "C" fn tc_pane_slice_json(
    pane_id: u32,
    start: usize,
    count: usize,
) -> *mut c_char {
    let reg = registry().lock().unwrap();
    if let Some(pane) = reg.panes.get(&pane_id) {
        let slice = pane.get_visible_slice(start, count);
        let json = serde_json::to_string(&slice).unwrap_or_else(|_| "[]".to_string());
        string_to_cchar(json)
    } else {
        string_to_cchar("[]".to_string())
    }
}

#[no_mangle]
pub extern "C" fn tc_pane_selected_paths_json(pane_id: u32) -> *mut c_char {
    let reg = registry().lock().unwrap();
    if let Some(pane) = reg.panes.get(&pane_id) {
        let paths: Vec<String> = pane
            .visible_indices
            .iter()
            .filter_map(|&idx| pane.all_entries.get(idx))
            .filter(|e| e.selected && !e.is_parent)
            .map(|e| e.full_path.clone())
            .collect();
        let json = serde_json::to_string(&paths).unwrap_or_else(|_| "[]".to_string());
        string_to_cchar(json)
    } else {
        string_to_cchar("[]".to_string())
    }
}

#[no_mangle]
pub extern "C" fn tc_ops_copy(
    sources_json_ptr: *const c_char,
    dest_dir_ptr: *const c_char,
) -> *mut c_char {
    let sources_json = cstr_to_string(sources_json_ptr);
    let dest_dir = cstr_to_string(dest_dir_ptr);
    let sources: Vec<String> = serde_json::from_str(&sources_json).unwrap_or_default();
    let res = ops::copy_items(&sources, &dest_dir);
    string_to_cchar(serde_json::to_string(&res).unwrap_or_else(|_| "{}".to_string()))
}

#[no_mangle]
pub extern "C" fn tc_ops_move(
    sources_json_ptr: *const c_char,
    dest_dir_ptr: *const c_char,
) -> *mut c_char {
    let sources_json = cstr_to_string(sources_json_ptr);
    let dest_dir = cstr_to_string(dest_dir_ptr);
    let sources: Vec<String> = serde_json::from_str(&sources_json).unwrap_or_default();
    let res = ops::move_items(&sources, &dest_dir);
    string_to_cchar(serde_json::to_string(&res).unwrap_or_else(|_| "{}".to_string()))
}

#[no_mangle]
pub extern "C" fn tc_ops_mkdir(
    base_dir_ptr: *const c_char,
    name_ptr: *const c_char,
) -> *mut c_char {
    let base_dir = cstr_to_string(base_dir_ptr);
    let name = cstr_to_string(name_ptr);
    let res = ops::create_directory(&base_dir, &name);
    string_to_cchar(serde_json::to_string(&res).unwrap_or_else(|_| "{}".to_string()))
}

#[no_mangle]
pub extern "C" fn tc_ops_delete(
    sources_json_ptr: *const c_char,
    use_trash: bool,
) -> *mut c_char {
    let sources_json = cstr_to_string(sources_json_ptr);
    let sources: Vec<String> = serde_json::from_str(&sources_json).unwrap_or_default();
    let res = ops::delete_items(&sources, use_trash);
    string_to_cchar(serde_json::to_string(&res).unwrap_or_else(|_| "{}".to_string()))
}

#[no_mangle]
pub extern "C" fn tc_lister_read(
    file_path_ptr: *const c_char,
    offset: u64,
    max_bytes: usize,
    hex_mode: bool,
) -> *mut c_char {
    let file_path = cstr_to_string(file_path_ptr);
    let res = lister::read_lister_slice(&file_path, offset, max_bytes, hex_mode);
    string_to_cchar(serde_json::to_string(&res).unwrap_or_else(|_| "{}".to_string()))
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::fs;

    #[test]
    fn test_natural_sort_and_dirs_first() {
        let tmp = std::env::temp_dir().join("tc_mac_rust_test_1");
        let _ = fs::remove_dir_all(&tmp);
        fs::create_dir_all(tmp.join("b_folder")).unwrap();
        fs::create_dir_all(tmp.join("a_folder")).unwrap();
        fs::write(tmp.join("file10.txt"), b"hello 10").unwrap();
        fs::write(tmp.join("file2.txt"), b"hello 2").unwrap();
        fs::write(tmp.join(".hidden_file"), b"secret").unwrap();

        let mut pane = PaneState::new(tmp.to_str().unwrap());
        // Hidden files should be hidden by default
        let slice = pane.get_visible_slice(0, 20);
        assert_eq!(slice[0].name, "..");
        assert_eq!(slice[1].name, "a_folder");
        assert_eq!(slice[2].name, "b_folder");
        assert_eq!(slice[3].name, "file2.txt");
        assert_eq!(slice[4].name, "file10.txt");
        assert_eq!(slice.len(), 5);

        // Enable hidden files
        pane.set_show_hidden(true);
        assert_eq!(pane.get_visible_slice(0, 20).len(), 6);

        // Quick filter
        pane.set_filter("file10");
        let filtered = pane.get_visible_slice(0, 20);
        assert_eq!(filtered.len(), 2); // ".." + "file10.txt"
        assert_eq!(filtered[1].name, "file10.txt");

        // Lister test (text & hex)
        let f_path = tmp.join("file10.txt").to_string_lossy().into_owned();
        let text_slice = lister::read_lister_slice(&f_path, 0, 4096, false);
        assert!(text_slice.ok);
        assert_eq!(text_slice.content, "hello 10");

        let hex_slice = lister::read_lister_slice(&f_path, 0, 4096, true);
        assert!(hex_slice.ok);
        assert!(hex_slice.content.contains("68 65 6C 6C 6F 20 31 30"));

        let _ = fs::remove_dir_all(&tmp);
    }
}
