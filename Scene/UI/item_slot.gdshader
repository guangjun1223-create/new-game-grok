shader_type canvas_item;

uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform vec4 cooldown_color : source_color = vec4(0.0, 0.0, 0.0, 0.6);

void fragment() {
    float radius = 0.5;
    vec2 uv = UV - vec2(0.5);
    float angle = atan(uv.y, uv.x) + PI;
    float p_angle = progress * 2.0 * PI;

    if (length(uv) < radius && angle > p_angle) {
        COLOR = cooldown_color;
    } else {
        COLOR = vec4(0.0);
    }
}