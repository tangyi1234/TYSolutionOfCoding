//
//  TYGetCameraView.m
//  TYSolutionOfCoding
//
//  Created by 汤义 on 2017/9/15.
//  Copyright © 2017年 汤义. All rights reserved.
//

#import "TYGetCameraView.h"
#import "TYCamera.h"
@interface TYGetCameraView()
@property (nonatomic, strong, readwrite) TYCamera *camera;
@property (nonatomic, weak) UIImageView *encodeImage;   //编码返回数据
@end
@implementation TYGetCameraView
- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor redColor];
        [self initCamera];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(postImage:) name:@"postImage" object:nil];
    }
    return self;
}

- (void)initCamera {
    self.camera = [[TYCamera alloc] initCameraStream:self];
    
    UIImageView *encodeImage = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 200, 200)];
    [self addSubview:_encodeImage = encodeImage];
}

- (void)postImage:(NSNotification *)notification{
    
    NSLog(@"接受到通知，解码图片");
    
    // 如果是传多个数据，那么需要哪个数据，就对应取出对应的数据即可
    NSLog(@"这是图片数据:%@",notification.userInfo[@"image"]);
    dispatch_async(dispatch_get_main_queue(), ^{
        
        _encodeImage.image = (UIImage *)notification.userInfo[@"image"];
        
    });
    
    
    //    UILabel *label = (UILabel *)[self.view viewWithTag:100];
    //
    //    label.text = notification.userInfo[@"userName"];
}
/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
