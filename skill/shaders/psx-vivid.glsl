// Ajuste de cor para PS1: mais saturação, um pouco de contraste e brilho.
#pragma parameter VIVID_SAT "Saturacao" 1.25 0.5 2.0 0.05
#pragma parameter VIVID_CON "Contraste" 1.06 0.5 1.5 0.02
#pragma parameter VIVID_GAMMA "Gama (menor = mais claro)" 0.95 0.6 1.4 0.01

#if defined(VERTEX)
#if __VERSION__ >= 130
#define COMPAT_VARYING out
#define COMPAT_ATTRIBUTE in
#else
#define COMPAT_VARYING varying
#define COMPAT_ATTRIBUTE attribute
#endif
COMPAT_ATTRIBUTE vec4 VertexCoord;
COMPAT_ATTRIBUTE vec4 TexCoord;
COMPAT_VARYING vec2 vTex;
uniform mat4 MVPMatrix;
void main()
{
    gl_Position = MVPMatrix * VertexCoord;
    vTex = TexCoord.xy;
}

#elif defined(FRAGMENT)
#ifdef GL_ES
#ifdef GL_FRAGMENT_PRECISION_HIGH
precision highp float;
#else
precision mediump float;
#endif
#define COMPAT_PRECISION mediump
#else
#define COMPAT_PRECISION
#endif
#if __VERSION__ >= 130
#define COMPAT_VARYING in
#define COMPAT_TEXTURE texture
out vec4 FragColor;
#else
#define COMPAT_VARYING varying
#define FragColor gl_FragColor
#define COMPAT_TEXTURE texture2D
#endif
uniform sampler2D Texture;
COMPAT_VARYING vec2 vTex;
#ifdef PARAMETER_UNIFORM
uniform COMPAT_PRECISION float VIVID_SAT;
uniform COMPAT_PRECISION float VIVID_CON;
uniform COMPAT_PRECISION float VIVID_GAMMA;
#else
#define VIVID_SAT 1.25
#define VIVID_CON 1.06
#define VIVID_GAMMA 0.95
#endif
void main()
{
    vec3 c = COMPAT_TEXTURE(Texture, vTex).rgb;
    float l = dot(c, vec3(0.2126, 0.7152, 0.0722));
    c = mix(vec3(l), c, VIVID_SAT);
    c = (c - 0.5) * VIVID_CON + 0.5;
    c = clamp(c, 0.0, 1.0);
    c = pow(c, vec3(VIVID_GAMMA));
    FragColor = vec4(c, 1.0);
}
#endif
