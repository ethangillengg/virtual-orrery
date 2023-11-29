#version 450

#define PI 3.1415926535897932384626433832795
// save some space in the push constants by hard-coding this
#define MAX_TEXTURES 4

#define TEXTURE_STARS 0
#define TEXTURE_SUN 1
#define TEXTURE_EARTH 2
#define TEXTURE_MOON 3

// #define MODEL_RADIUS_SCALE 99999
// #define MODEL_DISTANCE_SCALE 999999
// volumetric mean radii in Km as specified in:
// (https://nssdc.gsfc.nasa.gov/planetary/factsheet/moonfact.html)
// (https://nssdc.gsfc.nasa.gov/planetary/factsheet/sunfact.html)
// #define RADIUS_SUN 695700.0 / 10 / MODEL_RADIUS_SCALE
// #define RADIUS_EARTH 6378.1 / MODEL_RADIUS_SCALE
// #define RADIUS_MOON 1738.1 / MODEL_RADIUS_SCALE
//
// #define DISTANCE_EARTH 14960000 / MODEL_DISTANCE_SCALE
// #define DISTANCE_MOON (378000 / MODEL_DISTANCE_SCALE) + DISTANCE_EARTH

layout(location = 0) out vec4 color;

// interpolated position and direction of ray in world space
layout(location = 0) in vec3 p;
layout(location = 1) in vec3 d;

// push constants block
layout(push_constant) uniform constants {
  mat4 invView; // camera-to-world
  vec4 proj;    // (near, far, aspect, fov)
  float time;
}
pc;

layout(binding = 0) uniform sampler2D textures[MAX_TEXTURES];

// Material properties
vec3 bg_color = vec3(0.00, 0.00, 0.5);
// For depth testing
float largestT = 999999999;

void drawSphere(vec3 centerPos, float radius, int texIndex) {
  // intersect against sphere of radius 1 centered at the origin
  vec3 dir = normalize(d);

  float prod = dot(2.0 * dir, (p - centerPos));
  float normp = length(p - centerPos);
  float c = (normp * normp) - (radius * radius);
  float discriminant = (prod * prod) - (4.0 * c);
  if (discriminant >= 0.0) {
    // determine intersection point
    float t1 = 0.5 * (-prod - sqrt(discriminant));
    float t2 = 0.5 * (-prod + sqrt(discriminant));
    float tmin, tmax;
    float t;
    if (t1 < t2) {
      tmin = t1;
      tmax = t2;
    } else {
      tmin = t2;
      tmax = t1;
    }
    if (tmax > 0.0) {
      t = (tmin > 0) ? tmin : tmax;

      // Don't draw if the fragment is behind something else
      if (t > largestT) {
        return;
      } else {
        largestT = t;
      }

      vec3 ipoint = (p + (t * dir));
      vec3 normal = normalize(ipoint - centerPos);

      // determine texture coordinates in spherical coordinates

      // First rotate about x through 90 degrees so that y is up.
      normal.z = -normal.z;
      normal = normal.xzy;

      float phi = acos(normal.z);
      float theta;
      if (abs(normal.x) < 0.001) {
        theta = sign(normal.y) * PI * 0.5;
      } else {
        theta = atan(normal.y, normal.x);
      }
      // normalize coordinates for texture sampling.
      // Top-left of texture is (0,0) in Vulkan, so we can stick to spherical
      // coordinates
      color =
          texture(textures[texIndex], vec2(1.0 + 0.5 * theta / PI, phi / PI));
    }
  }
}

void main() {

  color = vec4(bg_color, 1.0);

  // So that it does not get cut off
  drawSphere(vec3(0), largestT * 0.99, TEXTURE_STARS);
  drawSphere(vec3(0), 0.25, TEXTURE_SUN);
  drawSphere(vec3(0.7, -0.3, 0.6), 0.2, TEXTURE_EARTH);
  drawSphere(vec3(0.95, -0.4, 0.9), 0.08, TEXTURE_MOON);
}
