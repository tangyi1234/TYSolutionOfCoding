//
//  TYViewController.m
//  TYSolutionOfCoding
//
//  Created by 汤义 on 2017/9/15.
//  Copyright © 2017年 汤义. All rights reserved.
//

#import "TYViewController.h"
#import "TYGetCameraView.h"
@interface TYViewController ()

@end

@implementation TYViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self initVideoView];
}

- (void)initVideoView {
    TYGetCameraView *cameraView = [[TYGetCameraView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    [self.view addSubview:cameraView];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
