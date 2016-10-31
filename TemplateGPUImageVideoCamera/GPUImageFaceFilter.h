
#import <GPUImage/GPUImage.h>

@interface GPUImageFaceFilter : GPUImageFilter
{
  GLint faceRectListUniform;
  GLint faceRectListSizeUniform;
  GLint orientationUniform;
}

-(void)setFaceRectList:(NSArray*)faceList;
-(void)setFaceRectList:(NSArray*)faceList orientation:(UIInterfaceOrientation)orientation;
@end
