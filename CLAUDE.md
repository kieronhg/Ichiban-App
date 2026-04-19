## Claude Design Handoff — Flutter Implementation Guide

### How to handle incoming designs
When given a Claude Design handoff bundle, screenshot, or design specification:
- Treat it as a visual brief, not executable code. Do not attempt to use any HTML, CSS, or React components directly.
- Extract all design tokens (colours, typography, spacing, border radius, shadows) and map them to the existing Flutter theme file at `lib/core/theme/app_theme.dart`. Never hardcode values in widgets.
- If a token does not exist in the theme file yet, add it there first, then reference it in the widget.
- Implement each screen or component as a Flutter widget following the conventions in this file.

### Widget conventions
- All widgets should be `StatelessWidget` or `ConsumerWidget` (if using Riverpod) unless state is explicitly required
- Keep widgets small and single-purpose — split complex screens into sub-widgets
- Use `const` constructors wherever possible
- Use named parameters for all widget constructors

### Design token mapping
When Claude Design describes web concepts, translate them as follows:
- `padding` / `margin` → `EdgeInsets` in Flutter
- `border-radius` → `BorderRadius.circular()`
- `font-weight: 600` → `FontWeight.w600`
- `box-shadow` → `BoxDecoration` with `BoxShadow`
- `display: flex` / `flexbox` → `Row` or `Column` with appropriate `MainAxisAlignment`
- `grid` → `GridView` or `Wrap`
- `opacity` → `Opacity` widget or `.withOpacity()` on a colour

### After generating any UI code
Always run the following commands in order:
1. `flutter pub get`
2. `dart format .`
3. `flutter analyze`

Fix any analysis warnings before considering the task complete.

### Design system file location
The single source of truth for all visual tokens is:
`lib/core/theme/app_theme.dart`

Never introduce colours, font sizes, or spacing values anywhere else.
