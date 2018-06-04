//
//  SecondViewController.m
//  LiveRecorded
//
//  Created by iOS on 2018/6/4.
//  Copyright © 2018年 weiman. All rights reserved.
//

#import "SecondViewController.h"

#define CAPTURE_FRAMES_PER_SECOND 20
#define SAMPLE_RATE  44100
#define VideoWidth 480
#define VideoHeight 640

@interface SecondViewController ()
{
    UIButton *startBtn;
    bool startCalled;
    
    H264Encoder *h264Encoder;
    AACEncoder *aacEncoder;
    
    AVCaptureSession *captureSession;
    
    dispatch_queue_t _audioQueue;
    
    AVCaptureConnection *_audioConnection;
    AVCaptureConnection *_videoConnection;
    
    NSMutableData *data;
    NSString *h264File;
    NSFileHandle *fileHandle;
}

@property(nonatomic,strong)AVCaptureVideoPreviewLayer * showLayer;

@end

@implementation SecondViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    startCalled = true;
    data = [[NSMutableData alloc] init];
    captureSession = [[AVCaptureSession alloc] init];
    
    [self initStartBtn];
    
}

- (IBAction)backAction:(UIButton *)sender {
    
    [self dismissViewControllerAnimated:true completion:nil];
}

-(void) initStartBtn {
    startBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 100, 30)];
    startBtn.center = self.view.center;
    [startBtn addTarget:self action:@selector(startBtnClicked) forControlEvents:UIControlEventTouchUpInside];
    [startBtn setTitle:@"开始" forState:UIControlStateNormal];
    [startBtn setTitleColor:UIColor.blackColor forState:UIControlStateNormal];
    [self.view addSubview:startBtn];
}

- (void) startBtnClicked {
    if (startCalled) {
        [self startCamera];
        startCalled = false;
        [startBtn setTitle:@"结束" forState:UIControlStateNormal];
    } else {
        [startBtn setTitle:@"开始" forState:UIControlStateNormal];
        startCalled = true;
        [self stopCarmera];
    }
}

- (void)startCamera {
    [self setupAudioCapture];
    [self setupVideoCaprure];
    [captureSession commitConfiguration];
    [captureSession startRunning];
}

- (void) stopCarmera {
    [h264Encoder end];
    [captureSession stopRunning];
    
    [fileHandle closeFile];
    fileHandle = NULL;
    
    // 获取程序Documents目录路径
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    
    NSMutableString *path = [[NSMutableString alloc] initWithString:documentsDirectory];
    [path appendString:@"/AACFile"];
    
    [data writeToFile:path atomically:true];
}

- (void) setupAudioCapture {
    
    aacEncoder = [[AACEncoder alloc] init];
    /*
     * Create audio connection
     */
    AVCaptureDevice * audioDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
    NSError *error = nil;
    AVCaptureDeviceInput * audioDeviceInput = [[AVCaptureDeviceInput alloc] initWithDevice:audioDevice error:&error];
    if (error) {
        NSLog(@"Error getting audio input device: %@",error.description);
    }
    if ([captureSession canAddInput:audioDeviceInput]) {
        [captureSession addInput:audioDeviceInput];
    }
    
    _audioQueue = dispatch_queue_create("Audio Capture Queue", DISPATCH_QUEUE_SERIAL);
    AVCaptureAudioDataOutput *audioOutput = [[AVCaptureAudioDataOutput alloc] init];
    [audioOutput setSampleBufferDelegate:self queue:_audioQueue];
    if ([captureSession canAddOutput:audioOutput]) {
        [captureSession addOutput:audioOutput];
    }
    
    _audioConnection = [audioOutput connectionWithMediaType:AVMediaTypeAudio];
    
}

#pragma mark - 设置视频 capture
- (void) setupVideoCaprure {
    
    h264Encoder = [H264Encoder alloc];
    [h264Encoder initWithConfiguration];
    
    NSError * deviceError;
    
    AVCaptureDevice *cameraDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    AVCaptureDeviceInput *inputDevice = [AVCaptureDeviceInput deviceInputWithDevice:cameraDevice error:&deviceError];
    
    AVCaptureVideoDataOutput *outputDevice = [[AVCaptureVideoDataOutput alloc] init];
    NSString *key = (NSString *)kCVPixelBufferPixelFormatTypeKey;
    NSNumber* val = [NSNumber
                     numberWithUnsignedInt:kCVPixelFormatType_420YpCbCr8BiPlanarFullRange];
    NSDictionary* videoSettings =
    [NSDictionary dictionaryWithObject:val forKey:key];
    
    NSError *error;
    [cameraDevice lockForConfiguration:&error];
    if (error == nil) {
        if (cameraDevice.activeFormat.videoSupportedFrameRateRanges){
            
            [cameraDevice setActiveVideoMinFrameDuration:CMTimeMake(1, CAPTURE_FRAMES_PER_SECOND)];
            [cameraDevice setActiveVideoMaxFrameDuration:CMTimeMake(1, CAPTURE_FRAMES_PER_SECOND)];
        }
    } else {
        // handle error2
        NSLog(@"error ");
    }
    [cameraDevice unlockForConfiguration];
    
    outputDevice.videoSettings = videoSettings;
    [outputDevice setSampleBufferDelegate:self queue:dispatch_get_main_queue()];
    
    if ([captureSession canAddInput:inputDevice]) {
        [captureSession addInput:inputDevice];
    }
    if ([captureSession canAddOutput:outputDevice]) {
        [captureSession addOutput:outputDevice];
    }
    
    [captureSession beginConfiguration];
    
    [captureSession setSessionPreset:[NSString stringWithString:AVCaptureSessionPreset640x480]];
    _videoConnection = [outputDevice connectionWithMediaType:AVMediaTypeVideo];
    //Set landscape (if required)
    if ([_videoConnection isVideoOrientationSupported])
    {
        AVCaptureVideoOrientation orientation = AVCaptureVideoOrientationLandscapeRight;        //<<<<<SET VIDEO ORIENTATION IF LANDSCAPE
        [_videoConnection setVideoOrientation:orientation];
    }
    
    // make preview layer and add so that camera's view is displayed on screen
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    
    h264File = [documentsDirectory stringByAppendingPathComponent:@"test.h264"];
    [fileManager removeItemAtPath:h264File error:nil];
    [fileManager createFileAtPath:h264File contents:nil attributes:nil];
    
    // Open the file using POSIX as this is anyway a test application
    //fd = open([h264File UTF8String], O_RDWR);
    fileHandle = [NSFileHandle fileHandleForWritingAtPath:h264File];
    
    [h264Encoder initEncode:VideoWidth height:VideoHeight];
    h264Encoder.delegate = self;
    
    self.showLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:captureSession];
    self.showLayer.frame = self.view.bounds;
    [self.view.layer insertSublayer:self.showLayer atIndex:0];
    
}

- (AVCaptureDevice *)cameraWithPosition:(AVCaptureDevicePosition)position
{
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for ( AVCaptureDevice *device in devices )
        if ( device.position == position )
            return device;
    return nil;
}

#pragma mark
#pragma mark - sampleBuffer 数据
-(void) captureOutput:(AVCaptureOutput*)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection*)connection

{
    CMTime pts = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
    double dPTS = (double)(pts.value) / pts.timescale;
    
    //    NSLog(@"DPTS is %f",dPTS);
    
    if (connection == _videoConnection) {
        // 视频编码, 视频编码后的回调数据Data在下面代理中
        NSLog(@"------------视频编码--------------");
        [h264Encoder encode:sampleBuffer];
    } else if (connection == _audioConnection) {
        // 音频编码
        [aacEncoder encodeSampleBuffer:sampleBuffer completionBlock:^(NSData *encodedData, NSError *error) {
            if (encodedData) {
                NSLog(@"------------音频编码--------------");
                NSLog(@"Audio data (%lu): %@", (unsigned long)encodedData.length, encodedData.description);
                [self->data appendData:encodedData];
            } else {
                NSLog(@"Error encoding AAC: %@", error);
            }
        }];
        
    }
    
}

#pragma mark
#pragma mark - 视频 sps 和 pps
- (void)gotSpsPps:(NSData*)sps pps:(NSData*)pps
{
    
    const char bytes[] = "\x00\x00\x00\x01";
    size_t length = (sizeof bytes) - 1; //string literals have implicit trailing '\0'
    NSData *ByteHeader = [NSData dataWithBytes:bytes length:length];
    [fileHandle writeData:ByteHeader];
    [fileHandle writeData:sps];
    [fileHandle writeData:ByteHeader];
    [fileHandle writeData:pps];
    
}

#pragma mark
#pragma mark - 视频数据回调
// 我们拿到编码后的data数据，就可以考虑下一步传输给服务器了。
- (void)gotEncodedData:(NSData*)data isKeyFrame:(BOOL)isKeyFrame
{
    NSLog(@"Video data (%lu): %@", (unsigned long)data.length, data.description);
    
    if (fileHandle != NULL)
    {
        const char bytes[] = "\x00\x00\x00\x01";
        size_t length = (sizeof bytes) - 1; //string literals have implicit trailing '\0'
        NSData *ByteHeader = [NSData dataWithBytes:bytes length:length];
        
        [fileHandle writeData:ByteHeader];
        [fileHandle writeData:data];
        
    }
}

@end
