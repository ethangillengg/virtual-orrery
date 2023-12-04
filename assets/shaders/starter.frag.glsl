#version 450

#define PI 3.1415926535897932384626433832795
// save some space in the push constants by hard-coding this
#define MAX_TEXTURES 4

#define TEXTURE_SKYBOX 0
#define TEXTURE_SUN 1
#define TEXTURE_EARTH 2
#define TEXTURE_MOON 3

#define AXIAL_PERIOD_SUN_MOON 27.0
#define AXIAL_PERIOD_EARTH 1.0

#define ORBITAL_PERIOD_MOON 27.0
#define ORBITAL_PERIOD_EARTH (12.0 * ORBITAL_PERIOD_MOON)
// (https://nssdc.gsfc.nasa.gov/planetary/factsheet/moonfact.html)
// (https://nssdc.gsfc.nasa.gov/planetary/factsheet/sunfact.html)

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

const vec3 bg_color = vec3(0.00, 0.00, 0.5);
float largestT = 999999999;  // For depth testing

struct Celestial {
  vec3 pos;           // center position of celestial body
  float radius;       // radius of celestial body
  int texIndex;       // [0-3]
  bool noLighting;    // true if we don't want to apply lighting to this object
  float axialPeriod;  // 0 for no axial rotation
  float axialTiltDeg; // 0 for no axial tilt
};

void drawCelestial(Celestial celestial);
void castShadow(Celestial celestial, Celestial shadowCaster);
vec3 orbitAbout(Celestial orbited, float orbitalPeriod, float orbitalRadius,
                float orbitalInclinationDeg);

vec3 lightColor = normalize(vec3(1.0f, 1.0f, 1.0f));
vec3 lightPos = vec3(0.0, 0.0, 0.0);
vec3 ambient = 0.01 * lightColor;

void main() {
  color = vec4(bg_color, 1.0);

  Celestial skybox = {
      vec3(0),         //
      largestT * 0.99, // So that it does not get cut off
      TEXTURE_SKYBOX,  //
      true,            // no lighting
      0.0,             // no axial rotation
      0.0,             // no axial tilt
  };
  drawCelestial(skybox);

  Celestial sun = {
      vec3(0),               //
      0.3,                   //
      TEXTURE_SUN,           //
      true,                  // no lighting
      AXIAL_PERIOD_SUN_MOON, //
      0.0,                   // no axial tilt

  };
  drawCelestial(sun);

  Celestial earth = {
      orbitAbout(sun, ORBITAL_PERIOD_EARTH, 1.5, 0.0), // orbit of Earth -> Sun
      0.2,                                             //
      TEXTURE_EARTH,                                   //
      false,                                           //
      AXIAL_PERIOD_EARTH,                              //
      -23.44,                                          // in degrees
  };
  drawCelestial(earth);

  Celestial moon = {
      orbitAbout(earth, ORBITAL_PERIOD_MOON, 0.5,
                 -5.14),     // orbit of Moon -> Earth
      earth.radius * 0.2727, // roughly
      TEXTURE_MOON,          //
      false,                 //
      AXIAL_PERIOD_SUN_MOON, //
      6.68,                  // in degrees
  };
  drawCelestial(moon);

  castShadow(earth, moon);
  castShadow(moon, earth);
}

vec3 orbitAbout(Celestial orbited, float orbitalPeriod, float orbitalRadius,
                float orbitalInclinationDeg) {
  // accounts for current orbital position based on time
  // sin and cos order to ensure it is counter-clockwise rotation
  vec3 orbitingCenter = orbitalRadius * vec3(sin(pc.time / orbitalPeriod), 0.0,
                                             cos(pc.time / orbitalPeriod));

  // Sin(o/h) to get y-offset
  float axialYOffset = orbitalRadius * sin(radians(orbitalInclinationDeg));

  // Modulate from -1 to 1 based on time since the orbit is diagonal
  axialYOffset *= sin(pc.time / orbitalPeriod);
  orbitingCenter.y += axialYOffset;

  // since we are orbiting about the orbited body,
  // we need to account for its position
  orbitingCenter += orbited.pos;
  return orbitingCenter;
}

void drawCelestial(Celestial celestial) {
  // intersect against sphere of radius 1 centered at the origin
  vec3 dir = normalize(d);

  float prod = 2.0 * dot(dir, (p - celestial.pos));
  float normp = length(p - celestial.pos);
  float c = (normp * normp) - (celestial.radius * celestial.radius);
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
      vec3 normal = normalize(ipoint - celestial.pos);

      // ipoint is on the surface that is being lit
      vec3 lightDir = normalize(lightPos - ipoint);
      vec3 diffuse = 1.9 * max(dot(normal, lightDir), 0.0f) * lightColor;
      vec3 reflectDir = reflect(lightDir, normal);
      float spec = pow(max(dot(dir, reflectDir), 0.0), 64);
      vec3 specular = 0.9 * spec * lightColor;

      // determine texture coordinates in spherical coordinates
      normal.z = -normal.z;
      normal = normal.xzy;
      // Axial tilt applied in spherical coordinates
      normal = vec3(normal.x,
                    normal.y * cos(radians(celestial.axialTiltDeg)) -
                        normal.z * sin(radians(celestial.axialTiltDeg)),
                    normal.y * sin(radians(celestial.axialTiltDeg)) +
                        normal.z * cos(radians(celestial.axialTiltDeg)));

      float phi = acos(normal.z);
      float theta;
      if (abs(normal.x) < 0.001) {
        theta = sign(normal.y) * PI * 0.5;
      } else {
        theta = atan(normal.y, normal.x);
      }

      // Axial rotations
      // only apply if > 0
      if (celestial.axialPeriod > 0.0) {
        theta -= pc.time / celestial.axialPeriod;
        // Offset so that moon is facing the earth
        if (celestial.texIndex == TEXTURE_MOON) {
          theta += 0.5 * PI;
        }
      }

      // normalize coordinates for texture sampling.
      // Top-left of texture is (0,0) in Vulkan, so we can stick to spherical
      // coordinates
      vec4 texColor = texture(textures[celestial.texIndex],
                              vec2(1.0 + 0.5 * theta / PI, phi / PI));
      color = texColor;

      if (celestial.noLighting) {
        color = texColor;
      } else {
        color = vec4(ambient + diffuse + specular, 1.0) * texColor;
      }
    }
  }
}

// the fact that I did not have time to refactor this will forever be my greatest regret in this class ;-;
void castShadow(Celestial celestial, Celestial shadowCaster) {
  // intersect against sphere of radius 1 centered at the origin
  vec3 dir = normalize(d);

  float prod = 2.0 * dot(dir, (p - celestial.pos));
  float normp = length(p - celestial.pos);
  float c = (normp * normp) - (celestial.radius * celestial.radius);
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
      vec3 normal = normalize(ipoint - celestial.pos);

      // ipoint is on the surface that is being lit

      vec3 dir = normalize(ipoint - lightPos);
      //
      float prod = 2.0 * dot(dir, (lightPos - shadowCaster.pos));
      float normp = length(lightPos - shadowCaster.pos);
      float c = (normp * normp) - (shadowCaster.radius * shadowCaster.radius);
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

          vec3 shadowIPoint = (lightPos + (t * dir));
          vec3 shadowDir = normalize(shadowIPoint - ipoint);

          float shadowIntensity = 0.2 * dot(shadowDir, normal);

          if (shadowIntensity > 0) {
            color *= shadowIntensity;
          }
        }
      }
    }
  }
}
