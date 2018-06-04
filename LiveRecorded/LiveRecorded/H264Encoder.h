//
//  H264Encoder.h
//  LiveRecorded
//
//  Created by iOS on 2018/6/4.
//  Copyright © 2018年 weiman. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <VideoToolbox/VideoToolbox.h>

@protocol H264EncoderDelegate<NSObject>

- (void)gotSpsPps:(NSData*)sps pps:(NSData*)pps;
- (void)gotEncodedData:(NSData*)data isKeyFrame:(BOOL)isKeyFrame;

@end

@interface H264Encoder : NSObject

@property(copy, nonatomic) NSString * error;
@property(weak, nonatomic)id<H264EncoderDelegate>delegate;

-(void) initWithConfiguration;
-(void) start:(int)width height:(int)height;
-(void) initEncode: (int)width height:(int)height;
-(void) encode: (CMSampleBufferRef)sampleBuffer;
-(void) end;

@end
