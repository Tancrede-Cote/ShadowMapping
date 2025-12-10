#version 450 core            // minimal GL version support expected from the GPU

struct LightSource {
  vec3 position;
  vec3 color;
  float intensity;
  int isActive;
};

in vec4 fragPosLightSpace;

int numberOfLights = 3;
uniform LightSource lightSources[3];
// TODO: shadow maps

struct Material {
  vec3 albedo;
  sampler2D normalMap;
  sampler2D texture;
};

uniform sampler2D shadowMaps[3];
uniform float shadows[3];

uniform Material material;

uniform vec3 camPos;

in vec3 fPositionModel;
in vec3 fPosition;
in vec3 fNormal;
in vec2 fTexCoord;

out vec4 colorOut; // shader output: the color response attached to this fragment

float pi = 3.1415927;

uniform int isNormalMap;
uniform int useShadow;

float ShadowCalculation(vec4 fragPosLightSpace, sampler2D shadowMap)
{
    // perform perspective divide
    vec3 projCoords = fragPosLightSpace.xyz / fragPosLightSpace.w;
    // transform to [0,1] range
    projCoords = projCoords * 0.5 + 0.5;
    // get closest depth value from light's perspective (using [0,1] range fragPosLight as coords)
    float closestDepth = texture(shadowMap, projCoords.xy).r; 
    // get depth of current fragment from light's perspective
    float currentDepth = projCoords.z;
    // check whether current frag pos is in shadow
    float shadow = currentDepth > closestDepth  ? 0.5 : 0.0;

    return shadow;
} 

// TODO: shadows
void main() {
  vec3 n=normalize(fNormal);
  if (isNormalMap>0){
    n=vec3(1);
    n = normalize(fNormal+texture(material.normalMap, fTexCoord).rgb);
  }
  vec3 wo = normalize(camPos - fPosition); // unit vector pointing to the camera

  vec3 radiance = vec3(0, 0, 0);
  for(int i=0; i<numberOfLights; ++i) {
    LightSource a_light = lightSources[i];
    if(a_light.isActive == 1) { // consider active lights only
      vec3 wi = normalize(a_light.position - fPosition); // unit vector pointing to the light
      vec3 Li = a_light.color*a_light.intensity;
      vec3 albedo = material.albedo;
      if (isNormalMap>0){
        albedo = texture(material.texture,fTexCoord).xyz;
      }
      if (useShadow>0){
        radiance += Li*albedo*max(dot(n, wi), 0)*(1.0-ShadowCalculation(fragPosLightSpace, shadowMaps[i]));
      } else {
        radiance += Li*albedo*max(dot(n, wi), 0);
      }
    }
  }
  // colorOut = vec4(radiance*(1.0-shadow), 1.0);
  colorOut = vec4(radiance, 1.0);
}
