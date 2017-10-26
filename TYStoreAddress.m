//
//  TYStoreAddress.m
//  TYCaptureSession
//
//  Created by 汤义 on 2017/9/7.
//  Copyright © 2017年 汤义. All rights reserved.
//

#import "TYStoreAddress.h"

@implementation TYStoreAddress
// 当前系统时间
- (NSString* )nowTime2String
{
    NSString *date = nil;
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"YYYY-MM-dd hh:mm:ss";
    date = [formatter stringFromDate:[NSDate date]];
    
    return date;
}

- (NSString *)savedFileName
{
    return [[self nowTime2String] stringByAppendingString:@".h264"];
}

- (NSString *)savedFilePath
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask,YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    
    NSString *fileName = [self savedFileName];
    
    NSString *writablePath = [documentsDirectory stringByAppendingPathComponent:fileName];
    return writablePath;
}

- (char*)nsstring2char {
    NSString *path = [self savedFilePath];
    NSUInteger len = [path length];
    char *filepath = (char*)malloc(sizeof(char) * (len + 1));
    
    [path getCString:filepath maxLength:len + 1 encoding:[NSString defaultCStringEncoding]];
    
    return filepath;
}
@end
