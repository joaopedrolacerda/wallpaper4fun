#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>
using namespace metal;

// Cada função recebe a posição do pixel, o tamanho da tela e o tempo,
// e devolve a cor daquele pixel. Para criar um shader novo, adicione uma
// função aqui com a mesma assinatura e um case com o mesmo nome em ShaderStyle.

[[stitchable]] half4 aurora(float2 position, half4 color, float2 size, float time) {
    float2 uv = position / size;
    float3 col = mix(float3(0.06, 0.08, 0.18), float3(0.01, 0.01, 0.04), uv.y);

    for (int i = 0; i < 4; i++) {
        float fi = float(i);
        float band = 0.30 + 0.09 * fi
                   + 0.07 * sin(uv.x * 2.5 + time * 0.35 + fi * 1.7)
                   + 0.03 * sin(uv.x * 6.0 - time * 0.55 + fi * 2.3);
        float d = uv.y - band;
        // brilho que sobe acima da faixa e cai rápido abaixo dela
        float glow = d < 0.0 ? exp(d * 9.0) : exp(-d * 60.0);
        glow *= 0.55 + 0.45 * sin(uv.x * 9.0 + time * 0.8 + fi * 2.0);
        float3 tint = 0.5 + 0.5 * cos(float3(0.0, 2.0, 4.0) + 3.4 + fi * 0.9 + time * 0.07);
        col += glow * tint * 0.35;
    }
    return half4(half3(saturate(col)), 1.0h);
}

[[stitchable]] half4 waves(float2 position, half4 color, float2 size, float time) {
    float2 uv = position / size;
    float3 col = mix(float3(0.98, 0.62, 0.42), float3(0.45, 0.22, 0.48), uv.y);

    for (int i = 0; i < 6; i++) {
        float fi = float(i);
        float h = 0.42 + fi * 0.095
                + 0.025 * sin(uv.x * (3.0 + fi) + time * (0.45 + fi * 0.12) + fi * 2.1)
                + 0.010 * sin(uv.x * (11.0 + fi * 2.0) - time * 0.9);
        float edge = 1.5 / size.y;
        float m = smoothstep(h, h + edge, uv.y);
        float3 layer = mix(float3(0.30, 0.20, 0.45), float3(0.04, 0.05, 0.16), fi / 5.0);
        col = mix(col, layer, m);
    }
    return half4(half3(col), 1.0h);
}

[[stitchable]] half4 plasma(float2 position, half4 color, float2 size, float time) {
    float2 uv = position / size.y;
    float2 center = float2(size.x / size.y * 0.5, 0.5);
    float t = time * 0.6;

    float v = sin(uv.x * 5.0 + t)
            + sin((uv.y * 5.0 + t) * 0.8)
            + sin((uv.x + uv.y) * 4.0 + t * 1.3)
            + sin(length(uv - center) * 9.0 - t * 1.7);

    float3 col = 0.5 + 0.5 * cos(float3(0.0, 2.1, 4.2) + v * 1.1 + t * 0.4);
    return half4(half3(col * 0.85), 1.0h);
}
