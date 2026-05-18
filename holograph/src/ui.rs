use ratatui::{
    layout::{Alignment, Constraint, Direction, Layout},
    style::{Color, Modifier, Style},
    text::{Line, Span},
    widgets::{Block, Borders, Paragraph},
    Frame,
};
use ratatui_image::{Resize, StatefulImage};
use crate::app::App;

pub fn draw(f: &mut Frame, app: &mut App) {
    let constraints = if app.ui_hidden {
        vec![Constraint::Min(0), Constraint::Length(12), Constraint::Min(0)]
    } else {
        vec![
            Constraint::Min(0),
            Constraint::Length(12),
            Constraint::Length(1),
            Constraint::Length(1),
            Constraint::Length(1),
            Constraint::Length(1),
            Constraint::Min(0),
        ]
    };

    let vertical_layout = Layout::default()
        .direction(Direction::Vertical)
        .constraints(constraints)
        .split(f.area());

    let horizontal_center = Layout::default()
        .direction(Direction::Horizontal)
        .constraints([Constraint::Min(0), Constraint::Length(26), Constraint::Min(0)])
        .split(vertical_layout[1]);

    let image_area = horizontal_center[1];
    let inner_area = if app.ui_hidden {
        image_area
    } else {
        let image_block = Block::default()
            .borders(Borders::ALL)
            .border_style(Style::default().fg(Color::DarkGray));
        let inner = image_block.inner(image_area);
        f.render_widget(image_block, image_area);
        inner
    };

    if let Some(img) = &mut app.image_state {
        let image_widget = StatefulImage::new().resize(Resize::Fit(None));
        f.render_stateful_widget(image_widget, inner_area, img);
    }

    if !app.ui_hidden && !app.themes.is_empty() {
        let theme = &app.themes[app.selected_theme];

        let theme_name = Paragraph::new(Span::styled(
            format!(" Theme: {} ", theme.name),
            Style::default().fg(Color::White).add_modifier(Modifier::BOLD),
        ))
        .alignment(Alignment::Center);
        f.render_widget(theme_name, vertical_layout[2]);

        let img_carousel = Paragraph::new(Line::from(vec![
            Span::styled("‹ ", Style::default().fg(Color::Cyan)),
            Span::styled(format!("Image {} of {}", app.selected_image + 1, theme.images.len()), Style::default().fg(Color::DarkGray)),
            Span::styled(" ›", Style::default().fg(Color::Cyan)),
        ]))
        .alignment(Alignment::Center);
        f.render_widget(img_carousel, vertical_layout[3]);

        let status_color = if app.message.contains("Error") { Color::Red }
        else if app.message.contains("applied") || app.message.contains("set") { Color::Green }
        else { Color::DarkGray };
        let status = Paragraph::new(app.message.as_str())
            .alignment(Alignment::Center)
            .style(Style::default().fg(status_color));
        f.render_widget(status, vertical_layout[5]);
    }
}
