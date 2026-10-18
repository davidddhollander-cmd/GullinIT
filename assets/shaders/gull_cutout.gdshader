shader_type canvas_item;
// Suppress faint extraction fringes without altering the source sheet.
void fragment() {
    if (texture(TEXTURE, UV).a < 0.7) {
        discard;
    }
}
