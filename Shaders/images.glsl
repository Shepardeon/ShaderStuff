#iChannel0 "file://../cat.jpg"
#iChannel1 "file://../nintendo.png"

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
  vec2 uv = fragCoord / iResolution.xy;

  vec4 col = texture2D(iChannel0, uv);
  vec4 logo = texture2D(iChannel1, uv);

  fragColor = col * logo;
}