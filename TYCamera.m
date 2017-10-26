//
//  TYCamera.m
//  TYSolutionOfCoding
//
//  Created by 汤义 on 2017/9/15.
//  Copyright © 2017年 汤义. All rights reserved.
//

#import "TYCamera.h"
#import <AVFoundation/AVFoundation.h>
#import "TYStartCodec.h"
@interface TYCamera()<AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate>
@property (nonatomic, weak) TYGetCameraView *cameraView;
@property (nonatomic, strong) AVCaptureSession *session;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *preLayer;
@property (nonatomic, strong) dispatch_queue_t queue;
@property (nonatomic, strong) dispatch_queue_t audioQueue;
@property (nonatomic, strong) AVCaptureAudioDataOutput* audioDataOutput;
@property (nonatomic, strong) AVCaptureVideoDataOutput* videoDataOutput;
@property (nonatomic, strong) TYStartCodec *codec;
@end
@implementation TYCamera
- (instancetype)initCameraStream:(TYGetCameraView*)view {
    self = [super init];
    if (self) {
        _cameraView = view;
        [self initGetCamera];
    }
    return self;
}

- (void)initGetCamera {
    [self examplesCamera];
    [self instantiationPreLayer];
    [self initCodingObject];
    [self.session startRunning];
}

- (void)initCodingObject {
   self.codec = [[TYStartCodec alloc] initScreenSize:[self getVideoSize:_session.sessionPreset]];
    NSLog(@"%@",_codec);
}

- (AVCaptureSession *)session {
    if (!_session) {
        _session = [[AVCaptureSession alloc] init];
        _session.sessionPreset = AVCaptureSessionPreset1920x1080;
    }
    return _session;
}

- (dispatch_queue_t)queue {
    // Configure your output.
    if (!_queue) {
        _queue = dispatch_queue_create("myQueue", NULL);
    }
    return _queue;
}

- (void)examplesCamera {
    NSError *error = nil;
    AVCaptureDevice *device;
    NSArray *captureArray = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *devices in captureArray) {
        if ([devices position] == AVCaptureDevicePositionBack) {
            device = devices;
        }
    }
    //创建输入
    AVCaptureDeviceInput *deviceInput = [[AVCaptureDeviceInput alloc] initWithDevice:device error:&error];
    if ([self.session canAddInput:deviceInput]) {
        [self.session addInput:deviceInput];
    }
    //创建输出
    _videoDataOutput = [[AVCaptureVideoDataOutput alloc] init];
    [_videoDataOutput setSampleBufferDelegate:self queue:self.queue];
    //设置输出样式和格式
    _videoDataOutput.videoSettings = [[NSDictionary alloc] initWithObjectsAndKeys:[NSNumber numberWithUnsignedInt:kCVPixelFormatType_420YpCbCr8BiPlanarFullRange],kCVPixelBufferPixelFormatTypeKey, nil];
    _videoDataOutput.alwaysDiscardsLateVideoFrames = YES;
    if ([self.session canAddOutput:_videoDataOutput]) {
        [self.session addOutput:_videoDataOutput];
    }
    _videoDataOutput.minFrameDuration = CMTimeMake(1, 15);
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    if (connection == [_videoDataOutput connectionWithMediaType:AVMediaTypeVideo]) {//要是video
        [_codec videoCodingBuf:sampleBuffer];
    }
}

- (void)instantiationPreLayer {
    
    _preLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.session];
    //preLayer = [AVCaptureVideoPreviewLayer layerWithSession:session];
    _preLayer.frame = [UIScreen mainScreen].bounds;
    _preLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    [_cameraView.layer addSublayer:_preLayer];
    
}

- (CGSize)getVideoSize:(NSString *)sessionPreset {
    CGSize size = CGSizeZero;
    if ([sessionPreset isEqualToString:AVCaptureSessionPresetMedium]) {
        size = CGSizeMake(480, 360);
    } else if ([sessionPreset isEqualToString:AVCaptureSessionPreset1920x1080]) {
        size = CGSizeMake(1920, 1080);
    } else if ([sessionPreset isEqualToString:AVCaptureSessionPreset1280x720]) {
        size = CGSizeMake(1280, 720);
    } else if ([sessionPreset isEqualToString:AVCaptureSessionPreset640x480]) {
        size = CGSizeMake(640, 480);
    }
    
    return size;
}
@end
