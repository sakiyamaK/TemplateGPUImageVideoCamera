
#import "GPUImageGrayFaceFilter.h"

NSString *const kGPUImageGrayFaceFragmentShaderString = SHADER_STRING
(
 precision highp float;
 precision lowp int;
 
 uniform sampler2D inputImageTexture;
 
 varying vec2 textureCoordinate;
 
 //64(人) * 4(x,y,width,height) = 256
 uniform float faceRectList[256];
 uniform int faceRectListSize;
 
 void main()
 {
   vec3 color = texture2D( inputImageTexture, textureCoordinate ).rgb;
   //顔の領域ならgrayにする
   int isInside = 0;
   for(int i = 0 ; i < faceRectListSize; i += 4){
     float x = faceRectList[i];
     float y = faceRectList[i + 1];
     float w = faceRectList[i + 2];
     float h = faceRectList[i + 3];
     if(textureCoordinate.x > x && textureCoordinate.x < x + w &&
        textureCoordinate.y > y && textureCoordinate.y < y + h){
       isInside = 1;
       break;
     }
     if(isInside == 1){
       break;
     }
   }
   
   if(isInside == 1){
     float gray = (color.r + color.g + color.b)/3.0;
     color = vec3(gray, gray, gray);
   }
   
   gl_FragColor = vec4(color, 1.0);
 }
 );


@implementation GPUImageGrayFaceFilter

-(id)init{
  if (!(self = [super initWithFragmentShaderFromString:kGPUImageGrayFaceFragmentShaderString])){
    return nil;
  }
  return self;
}

@end

