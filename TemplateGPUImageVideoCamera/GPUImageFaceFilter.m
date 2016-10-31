
#import "GPUImageFaceFilter.h"

/*
 ********************************************
 継承先で使う時はこんな感じの変数を用意したシェーダにすること
 *********************************************
 
 NSString *const kGPUImageFaceFragmentShaderString = SHADER_STRING
 (
 precision highp float;
 precision lowp int;
 
 uniform sampler2D inputImageTexture;
 
 varying vec2 textureCoordinate;
 
 //64(人) * 4(x,y,width,height) = 256
 uniform float faceRectList[256];
 uniform int faceRectListSize;
 
 //便宜上用意されたメイン関数
 void main()
 {
 vec3 color = texture2D( inputImageTexture, textureCoordinate ).rgb;
 gl_FragColor = vec4(color, 1.0);
 }
 );
 */


@implementation GPUImageFaceFilter


//64(人) * 4(x,y,width,height) = 256 uniform側と同じ数
static const int MAX_FACE_RECT_LIST_SIZE = 256;
static float _faceRectList[MAX_FACE_RECT_LIST_SIZE];


-(id)initWithFragmentShaderFromString:(NSString *)fragmentShaderString{
  
  if (!(self = [super initWithFragmentShaderFromString:fragmentShaderString])){
    return nil;
  }
  
  faceRectListUniform = [filterProgram uniformIndex:@"faceRectList"];
  faceRectListSizeUniform = [filterProgram uniformIndex:@"faceRectListSize"];
  orientationUniform = [filterProgram uniformIndex:@"orientation"];
  
  return self;
}

-(void)setFaceRectList:(NSArray*)faceList{
  [self setFaceRectList:faceList orientation:UIInterfaceOrientationPortrait];
}

-(void)setFaceRectList:(NSArray*)faceList orientation:(UIInterfaceOrientation)orientation{
  
  [self setInteger:(GLsizei)orientation forUniform:orientationUniform program:filterProgram];
  
  GLsizei size = (GLsizei)([faceList count] * 4);
  
  if (size > MAX_FACE_RECT_LIST_SIZE ) {
    size = MAX_FACE_RECT_LIST_SIZE;
  }
  
  int fcListIndex = 0;
  for (NSValue *f in faceList) {
    
    CGRect bounds = [f CGRectValue];
    
    _faceRectList[fcListIndex] = bounds.origin.x;
    
    _faceRectList[fcListIndex + 1] = bounds.origin.y;
    
    _faceRectList[fcListIndex + 2] = bounds.size.width;
    
    _faceRectList[fcListIndex + 3] = bounds.size.height;
    
    fcListIndex += 4;
    
    if(fcListIndex >= 256){
      break;
    }
  }
  [self setInteger:size forUniform:faceRectListSizeUniform program:filterProgram];
  [self setFloatArray:_faceRectList length:size forUniform:faceRectListUniform program:filterProgram];
}

@end

