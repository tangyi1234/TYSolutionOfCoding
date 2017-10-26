//
//  AppDelegate.h
//  TYSolutionOfCoding
//
//  Created by 汤义 on 2017/9/13.
//  Copyright © 2017年 汤义. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (readonly, strong) NSPersistentContainer *persistentContainer;

- (void)saveContext;


@end

