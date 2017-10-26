//
//  TYCamera.h
//  TYSolutionOfCoding
//
//  Created by 汤义 on 2017/9/15.
//  Copyright © 2017年 汤义. All rights reserved.
//

#import <Foundation/Foundation.h>
//#import <UIKit/UIKit.h>
#import "TYGetCameraView.h"
@interface TYCamera : NSObject
- (instancetype)initCameraStream:(TYGetCameraView*)view;
@end
