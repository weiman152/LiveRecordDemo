//
//  AACEncoder.h
//  LiveRecorded
//
//  Created by iOS on 2018/6/4.
//  Copyright © 2018年 weiman. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioToolbox.h>

@interface AACEncoder : NSObject

@property(nonatomic) dispatch_queue_t encoderQueue;
@property(nonatomic) dispatch_queue_t callbackQueue;

- (void) encodeSampleBuffer:(CMSampleBufferRef)sampleBuffer completionBlock:(void (^)(NSData *encodedData, NSError* error))completionBlock;


@end
