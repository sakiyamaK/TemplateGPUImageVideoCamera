#import "ViewController.h"
#import <GPUImage/GPUImage.h>

#define CAMERA_W 720.0
#define CAMERA_H 1280.0

@interface ViewController ()<
GPUImageVideoCameraDelegate,
AVCaptureMetadataOutputObjectsDelegate>
@property (nonatomic, assign) BOOL running;
@property (nonatomic, assign) BOOL saving;
@property (nonatomic, weak) GPUImageView *previewView;
@property (nonatomic, strong) GPUImageVideoCamera *videoCamera;
@property (nonatomic, strong) GPUImageMovieWriter *movieWriter;
@property (nonatomic, strong) AVCaptureMetadataOutput *metadataOutput;
@property (nonatomic, strong) NSArray *metadataList;
@end

@implementation ViewController

- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
}

- (void)viewDidLoad {
  [super viewDidLoad];
  
  //画面のレイアウトを設定
  [self setupLayout];

  //カメラを設定 引数で解像度とフロントかバックか指定する
  [self setupCameraWithSessionPreset:AVCaptureSessionPresetHigh
                        withPosition:AVCaptureDevicePositionFront];
  
  //メタデータを設定 引数で種類を指定する
  [self setupMetadataOutputWithObjectTypes:@[AVMetadataObjectTypeFace]];
  
  //フィルタを設定
  [self setupFilter];
  
  //カメラを起動
  [self startVideo];
}

-(void)setupLayout{
  CGFloat w = MIN(self.view.frame.size.width, self.view.frame.size.height);
  CGFloat h = w / self.sessionPresetSize.width * self.sessionPresetSize.height;
  
  GPUImageView *previewView = [[GPUImageView alloc] initWithFrame:(CGRect){0, 0, w, h}];
  previewView.userInteractionEnabled = NO;
  previewView.fillMode = kGPUImageFillModePreserveAspectRatioAndFill;
  previewView.center = self.view.center;
  [self.view addSubview:previewView];
  _previewView = previewView;
}

-(void)setupCameraWithSessionPreset:(NSString*)sessionPreset withPosition:(AVCaptureDevicePosition)position{
  
  GPUImageVideoCamera *videoCamera = [[GPUImageVideoCamera alloc] initWithSessionPreset:sessionPreset cameraPosition:position];
  //  videoCamera.outputImageOrientation = UIInterfaceOrientationPortrait;
  //  videoCamera.horizontallyMirrorFrontFacingCamera = YES;
  //  videoCamera.horizontallyMirrorRearFacingCamera = NO;
  videoCamera.delegate = self;
  self.videoCamera = videoCamera;
  [videoCamera addTarget:self.previewView];
  
  AVCaptureSession *session = videoCamera.captureSession;
  
  // カメラの向きとかを設定する
  //videoCamera.outputImageOrientationで向きを指定すると
  //- (void)willOutputSampleBuffer:(CMSampleBufferRef)sampleBufferで正しい向きがとれない
  [session beginConfiguration];
  
  AVCaptureConnection *videoConnection = nil;
  for(AVCaptureVideoDataOutput *dataOutput in session.outputs){
    for ( AVCaptureConnection *connection in [dataOutput connections] ){
      for ( AVCaptureInputPort *port in [connection inputPorts] ){
        if ( [[port mediaType] isEqual:AVMediaTypeVideo] ){
          videoConnection = connection;
        }
      }
    }
  }
  
  if([videoConnection isVideoOrientationSupported]){
    videoConnection.videoOrientation = AVCaptureVideoOrientationPortrait;
    videoConnection.videoMirrored = (position == AVCaptureDevicePositionFront);
  }
  
  [session commitConfiguration];
}

- (void)setupFilter{
  
  /*何かしらフィルタ*/
  GPUImageFilter *imageFilter = [GPUImageFilter new];
  
  [imageFilter removeAllTargets];
  [self.videoCamera removeAllTargets];
  
  [self.videoCamera addTarget:imageFilter];
  if (self.previewView) {
    [imageFilter addTarget:self.previewView];
  }
}


-(void)setupMetadataOutputWithObjectTypes:(NSArray*)objectTypes{
  AVCaptureMetadataOutput *metadataOutput = [AVCaptureMetadataOutput new];
  dispatch_queue_t metadataQueue = dispatch_queue_create("metadataQueue", nil);
  [metadataOutput setMetadataObjectsDelegate:self queue:metadataQueue];
  [self.videoCamera.captureSession addOutput:metadataOutput];
  metadataOutput.metadataObjectTypes = objectTypes;
  _metadataOutput = metadataOutput;
}


-(void)startVideo{
  if(!self.videoCamera.captureSession.isRunning){
    [self.videoCamera startCameraCapture];
  }
}

-(void)stopVideo{
  if(self.videoCamera.captureSession.isRunning){
    [self.videoCamera stopCameraCapture];
  }
}

-(CGSize)sessionPresetSize{
  if(_videoCamera){
    NSString *sessionPreset = _videoCamera.captureSession.sessionPreset;
    if([sessionPreset isEqualToString:AVCaptureSessionPreset3840x2160]){
      return (CGSize){3840, 2160};
    }
    else if([sessionPreset isEqualToString:AVCaptureSessionPreset1280x720]){
      return (CGSize){1280, 720};
    }
    else if([sessionPreset isEqualToString:AVCaptureSessionPreset1920x1080]){
      return (CGSize){920, 1080};
    }
    else if([sessionPreset isEqualToString:AVCaptureSessionPreset352x288]){
      return (CGSize){352, 288};
    }
    else if([sessionPreset isEqualToString:AVCaptureSessionPreset640x480]){
      return (CGSize){640, 480};
    }
    else if([sessionPreset isEqualToString:AVCaptureSessionPresetiFrame960x540]){
      return (CGSize){960, 540};
    }
  }
  return (CGSize){CAMERA_W, CAMERA_H};
}

//delegateメソッド,各フレームにおける処理
- (void)willOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer {
  
  _running = YES;
  
  CMTime time = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
  
  /*生の画像を取得*/
  CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
  CFDictionaryRef attachments = CMCopyDictionaryOfAttachments(kCFAllocatorDefault, sampleBuffer, kCMAttachmentMode_ShouldPropagate);
  CIImage* convertedImage = [[CIImage alloc] initWithCVPixelBuffer:pixelBuffer options:(__bridge NSDictionary *)attachments];
  CFRelease(attachments);
  
   NSArray *features = nil;
  @synchronized (self) {
    /*生の画像とmetadataから色々処理*/
  }
  
  _running = NO;
}



#pragma mark - AVCaptureMetadataOutputObjectsDelegate

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection{
  @synchronized (self) {
    _metadataList = metadataObjects;
  }
}


@end
