//
//  SecondViewController.h
//  LiveRecorded
//
//  Created by iOS on 2018/6/4.
//  Copyright © 2018年 weiman. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "AACEncoder.h"
#import "H264Encoder.h"

@interface SecondViewController : UIViewController<AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate, H264EncoderDelegate>



@end
