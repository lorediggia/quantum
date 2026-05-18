use ratatui_image::{picker::Picker, protocol::StatefulProtocol};
use std::fs;
use crate::theme::{AppPaths, ThemeFolder, load_themes, apply_theme};

pub struct App {
    pub paths: AppPaths,
    pub themes: Vec<ThemeFolder>,
    pub selected_theme: usize,
    pub selected_image: usize,
    pub image_state: Option<StatefulProtocol>,
    pub message: String,
    pub picker: Picker,
    pub ui_hidden: bool,
}

impl App {
    pub fn new() -> Self {
        let paths = AppPaths::new();
        let ui_hidden = paths.ui_state_path.exists();
        let themes = load_themes(&paths.holograph_dir);
        let picker = Picker::from_query_stdio().unwrap_or_else(|_| Picker::halfblocks());

        let mut app = App {
            paths,
            themes,
            selected_theme: 0,
            selected_image: 0,
            image_state: None,
            message: Self::default_message(),
            picker,
            ui_hidden,
        };
        app.load_image();
        app
    }

    pub fn default_message() -> String {
        " ↑/↓ Themes • ←/→ Images • Enter Apply • Q Exit ".to_string()
    }

    pub fn load_image(&mut self) {
        if let Some(theme) = self.themes.get(self.selected_theme) {
            if let Some(image_path) = theme.images.get(self.selected_image) {
                if let Ok(dyn_img) = image::open(image_path) {
                    let hq_image = dyn_img.thumbnail(400, 400);
                    self.image_state = Some(self.picker.new_resize_protocol(hq_image));
                }
            }
        }
    }

    pub fn navigate_theme(&mut self, forward: bool) {
        if self.themes.is_empty() { return; }
        if forward {
            self.selected_theme = (self.selected_theme + 1) % self.themes.len();
        } else {
            self.selected_theme = self.selected_theme.checked_sub(1).unwrap_or(self.themes.len() - 1);
        }
        self.selected_image = 0;
        self.reset_state();
    }

    pub fn navigate_image(&mut self, forward: bool) {
        if let Some(theme) = self.themes.get(self.selected_theme) {
            if theme.images.is_empty() { return; }
            if forward {
                self.selected_image = (self.selected_image + 1) % theme.images.len();
            } else {
                self.selected_image = self.selected_image.checked_sub(1).unwrap_or(theme.images.len() - 1);
            }
            self.reset_state();
        }
    }

    fn reset_state(&mut self) {
        self.load_image();
        self.message = Self::default_message();
    }

    pub fn toggle_ui(&mut self) {
        self.ui_hidden = !self.ui_hidden;
        if self.ui_hidden {
            let _ = fs::write(&self.paths.ui_state_path, "");
        } else {
            let _ = fs::remove_file(&self.paths.ui_state_path);
        }
    }

    pub fn do_apply_theme(&mut self) {
        match apply_theme(&self.themes, self.selected_theme, &self.paths) {
            Ok(msg) => self.message = msg,
            Err(msg) => self.message = msg,
        }
    }
}
