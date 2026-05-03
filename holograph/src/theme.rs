use std::{env, fs, path::PathBuf};
use regex::Regex;

#[derive(Clone, Debug)]
pub struct ThemeFolder {
    pub path: PathBuf,
    pub name: String,
    pub images: Vec<PathBuf>,
}

pub struct AppPaths {
    pub home: String,
    pub holograph_dir: PathBuf,
    pub dest_dir: PathBuf,
    pub config_path: PathBuf,
    pub ui_state_path: PathBuf,
}

impl AppPaths {
    pub fn new() -> Self {
        let home = env::var("HOME").unwrap_or_default();
        Self {
            holograph_dir: PathBuf::from(&home).join("dotfiles/logo/holograph"),
            dest_dir: PathBuf::from(&home).join("dotfiles/logo/img"),
            config_path: PathBuf::from(&home).join("dotfiles/fastfetch/.config/fastfetch/config.jsonc"),
            ui_state_path: PathBuf::from(&home).join(".cache/holograph_ui_hidden"),
            home,
        }
    }
}

pub fn load_themes(base_dir: &PathBuf) -> Vec<ThemeFolder> {
    let mut themes = Vec::new();
    if let Ok(entries) = fs::read_dir(base_dir) {
        for entry in entries.flatten().filter(|e| e.path().is_dir()) {
            let path = entry.path();
            let mut images: Vec<_> = fs::read_dir(&path)
                .into_iter()
                .flatten()
                .flatten()
                .map(|e| e.path())
                .filter(|p| {
                    p.is_file()
                        && matches!(
                            p.extension().and_then(|s| s.to_str()),
                            Some("jpg" | "jpeg" | "png" | "webp")
                        )
                })
                .collect();

            if !images.is_empty() {
                images.sort();
                themes.push(ThemeFolder {
                    name: entry.file_name().to_string_lossy().into_owned(),
                    path,
                    images,
                });
            }
        }
    }
    themes.sort_by(|a, b| a.name.cmp(&b.name));
    themes
}

pub fn set_cover(themes: &mut Vec<ThemeFolder>, selected_theme: usize, selected_image: usize, base_dir: &PathBuf) -> Result<String, String> {
    if themes.is_empty() { return Err("No themes available".into()); }
    
    let theme = &themes[selected_theme];
    let current_path = &theme.images[selected_image];
    let file_name = current_path.file_name().unwrap().to_string_lossy();

    if file_name.starts_with("00_cover_") {
        return Ok(" Already set as cover ".to_string());
    }

    for img_path in &theme.images {
        let name = img_path.file_name().unwrap().to_string_lossy();
        if name.starts_with("00_cover_") {
            let restored_name = name.replacen("00_cover_", "", 1);
            let _ = fs::rename(img_path, img_path.with_file_name(restored_name));
        }
    }

    let clean_name = file_name.replace("00_cover_", "");
    let new_path = current_path.with_file_name(format!("00_cover_{}", clean_name));

    if fs::rename(current_path, &new_path).is_ok() {
        *themes = load_themes(base_dir);
        Ok(format!(" Cover set for theme: {} ", themes[selected_theme].name))
    } else {
        Err(" Error setting cover ".to_string())
    }
}

pub fn apply_theme(themes: &[ThemeFolder], selected_theme: usize, paths: &AppPaths) -> Result<String, String> {
    if themes.is_empty() { return Err("No themes".into()); }
    let theme = &themes[selected_theme];

    let _ = fs::create_dir_all(&paths.dest_dir);
    if let Ok(entries) = fs::read_dir(&paths.dest_dir) {
        for entry in entries.flatten() {
            let _ = fs::remove_file(entry.path());
        }
    }

    let mut cover_dest_path = PathBuf::new();
    if let Ok(entries) = fs::read_dir(&theme.path) {
        for entry in entries.flatten().filter(|e| e.path().is_file()) {
            let file_name = entry.file_name();
            let dest_file = paths.dest_dir.join(&file_name);

            if fs::copy(entry.path(), &dest_file).is_ok() {
                let name_str = file_name.to_string_lossy();
                if name_str.starts_with("00_cover_") || cover_dest_path.as_os_str().is_empty() {
                    cover_dest_path = dest_file;
                }
            }
        }
    }

    if cover_dest_path.exists() {
        if let Ok(data) = fs::read_to_string(&paths.config_path) {
            if let Ok(re) = Regex::new(r#"("source"\s*:\s*)"[^"]+""#) {
                let abs_path = cover_dest_path.to_string_lossy().into_owned();
                let portable_path = if !paths.home.is_empty() && abs_path.starts_with(&paths.home) {
                    abs_path.replacen(&paths.home, "~", 1)
                } else {
                    abs_path
                };

                let new_data = re.replace(&data, |caps: &regex::Captures| format!(r#"{}"{}""#, &caps[1], portable_path));
                if fs::write(&paths.config_path, new_data.as_bytes()).is_ok() {
                    return Ok(format!(" Theme applied: {} ", theme.name));
                }
            }
        }
    }
    Err(" Error applying theme ".to_string())
}