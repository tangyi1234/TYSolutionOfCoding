//
//  TYStartCodec.h
//  TYSolutionOfCoding
//
//  Created by 汤义 on 2017/9/25.
//  Copyright © 2017年 汤义. All rights reserved.
//
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <CoreMedia/CoreMedia.h>
@interface TYStartCodec : NSObject
-(instancetype)initScreenSize:(CGSize)size;
- (void)videoCodingBuf:(CMSampleBufferRef)bufferRef;
@end
