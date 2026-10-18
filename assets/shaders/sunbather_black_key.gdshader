shader_type canvas_item;
uniform vec4 source_uv_rect = vec4(0.0, 0.0, 1.0, 1.0);
uniform bool mask_baked_towel = false;
// The supplied JPEG has a black backdrop. Keep the original pixels untouched.
void fragment() {
    vec4 pixel = texture(TEXTURE, UV);
    if (max(pixel.r, max(pixel.g, pixel.b)) < 0.14) { discard; }
    // Mask only a moved recline/rise frame. Atlas UVs cover the whole source
    // sheet, so convert them back to the selected frame before checking its
    // bottom towel band. Resting art at home stays exactly as supplied.
    vec2 local_uv = (UV - source_uv_rect.xy) / source_uv_rect.zw;
    if (mask_baked_towel && local_uv.y > 0.80) {
        // In these source poses only warm skin extends into the towel band.
        // Hue distinguishes orange hands/feet from red and yellow stripes,
        // including compressed, shaded pixels which brightness keys miss.
        float high = max(pixel.r, max(pixel.g, pixel.b));
        float low = min(pixel.r, min(pixel.g, pixel.b));
        float chroma = high - low;
        float warm_hue = (pixel.g - pixel.b) / max(chroma, 0.001);
        bool skin = pixel.r >= max(pixel.g, pixel.b) && chroma > 0.08
            && warm_hue > 0.10 && warm_hue < 0.64;
        if (!skin) { discard; }
    }
    COLOR = pixel;
}
