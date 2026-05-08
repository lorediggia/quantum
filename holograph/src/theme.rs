use std::{env, fs, path::PathBuf};

#[derive(Clone, Debug)]
pub struct ThemeFolder {
    pub path: PathBuf,
    pub name: String,
    pub images: Vec<PathBuf>,
}

pub struct AppPaths {
    pub holograph_dir: PathBuf,
    pub dest_dir: PathBuf,
    pub ui_state_path: PathBuf,
}

impl AppPaths {
    pub fn new() -> Self {
        let home = env::var("HOME").unwrap_or_default();
        Self {
            holograph_dir: PathBuf::from(&home).join("dotfiles/logo/holograph"),
            dest_dir: PathBuf::from(&home).join("dotfiles/logo/img"),
            ui_state_path: PathBuf::from(&home).join(".cache/holograph_ui_hidden"),
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

pub fn apply_theme(themes: &[ThemeFolder], selected_theme: usize, paths: &AppPaths) -> Result<String, String> {
    if themes.is_empty() { return Err(" No themes ".into()); }
    let theme = &themes[selected_theme];

    if paths.dest_dir.is_symlink() {
        fs::remove_file(&paths.dest_dir).map_err(|e| format!(" Error: {} ", e))?;
    } else if paths.dest_dir.exists() {
        fs::remove_dir_all(&paths.dest_dir).map_err(|e| format!(" Error: {} ", e))?;
    }

    std::os::unix::fs::symlink(&theme.path, &paths.dest_dir)
        .map_err(|e| format!(" Symlink failed: {} ", e))?;

    Ok(format!(" Theme applied: {} ", theme.name))
}