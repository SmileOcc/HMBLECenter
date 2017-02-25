//
//  AppDelegate.h
//  HMBLECenter
//
//  Created by FaceStar on 15-3-1.
//  Copyright (c) 2015年 occ. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate> {
    UILabel     *messageLab;
    UIButton    *connectBtn;
    UIButton    *cancelBtn;
    UIButton    *sendButton;
    UIImageView *testImgView;
    
    NSString    *imgName;
}

@property (strong, nonatomic) UIWindow *window;


@end

