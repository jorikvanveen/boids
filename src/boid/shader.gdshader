shader_type canvas_item;

void fragment() {
    vec4 defaultcolor = texture(TEXTURE, UV);
    vec4 colortomix = vec4(1, 1, 1, 0.5)
    COLOR = mix(defaultcolor.rgb, colortomix.rgb, 0.1)
}