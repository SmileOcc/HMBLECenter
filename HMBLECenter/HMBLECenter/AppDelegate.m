//
//  AppDelegate.m
//  HMBLECenter
//
//  Created by FaceStar on 15-3-1.
//  Copyright (c) 2015年 occ. All rights reserved.
//

#import "AppDelegate.h"
#import "HMBLECenterHandle.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    //蓝牙初始
    [HMBLECenterHandle sharedHMBLECenterHandle];
    
    [self createView];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(upAction:) name:@"up_Notification" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(centerAction:) name:@"center_Notification" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(downAction:) name:@"down_Notification" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(connectSuccessAction:) name:@"didConnect_Notification" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(disConnectAction:) name:@"didDisconnect_Notification" object:nil];
    return YES;
}

- (void)createView {

    messageLab = [[UILabel alloc] initWithFrame:CGRectMake(0, 20, _window.frame.size.width, 40)];
    messageLab.text = @"蓝牙连接中....";
    messageLab.textColor = [UIColor redColor];
    _window.hidden = NO;
    [_window addSubview:messageLab];
    //这里window当应该为活动后，会自己设置成为no
    
#warning 这里要加一些判断，在连接的过程或以连接成功的不能点
    connectBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [connectBtn setTitle:@"连接" forState:UIControlStateNormal];
    connectBtn.frame = CGRectMake(0, 110, _window.frame.size.width, 40);
    connectBtn.backgroundColor = [UIColor redColor];
    [connectBtn addTarget:self action:@selector(actionReConnect:) forControlEvents:UIControlEventTouchUpInside];
    [_window addSubview:connectBtn];
    
    
    cancelBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [cancelBtn setTitle:@"取消" forState:UIControlStateNormal];
    cancelBtn.frame = CGRectMake(0, 60, _window.frame.size.width, 40);
    cancelBtn.backgroundColor = [UIColor redColor];
    [cancelBtn addTarget:self action:@selector(actionCancel:) forControlEvents:UIControlEventTouchUpInside];
    [_window addSubview:cancelBtn];
    
    sendButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [sendButton setTitle:@"发送" forState:UIControlStateNormal];
    sendButton.frame = CGRectMake(0, 200, _window.frame.size.width, 40);
    sendButton.backgroundColor = [UIColor redColor];
    [sendButton addTarget:self action:@selector(actionSend:) forControlEvents:UIControlEventTouchUpInside];
    [_window addSubview:sendButton];
    
    testImgView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"2.jpg"]];
    testImgView.frame = CGRectMake((_window.bounds.size.width - 100) / 2.0, 260, 100, 100);
    [_window addSubview:testImgView];
    
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    
    /*
    messageLab = [[UILabel alloc] initWithFrame:CGRectMake(0, 20, _window.frame.size.width, 40)];
    messageLab.text = @"蓝牙连接中....";
    //_window.hidden = NO;
    [_window addSubview:messageLab];
    //这里window当应该为活动后，会自己设置成为no
    
    connectBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    connectBtn.frame = CGRectMake(0, 60, _window.frame.size.width, 40);
    connectBtn.backgroundColor = [UIColor redColor];
    [connectBtn addTarget:self action:@selector(actionReConnect:) forControlEvents:UIControlEventTouchUpInside];
    [_window addSubview:connectBtn];
     */
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

#pragma mark - Notification
-(void)upAction:(NSNotification *)notify {
    NSLog(@"%@",notify.userInfo);
    NSDictionary *dic = notify.userInfo;
    if (dic) {
        NSString *str = [dic objectForKey:@"up"];
        messageLab.text = [NSString stringWithFormat:@"收到数据上 %@ ",str];
    }
}
-(void)centerAction:(NSNotification *)notify {
    NSLog(@"%@",notify.userInfo);
    NSDictionary *dic = notify.userInfo;
    if (dic) {
        NSString *str = [dic objectForKey:@"center"];
        messageLab.text = [NSString stringWithFormat:@"收到数据中 %@ ",str];
    }
}
-(void)downAction:(NSNotification *)notify {
    NSLog(@"%@",notify.userInfo);
    NSDictionary *dic = notify.userInfo;
    if (dic) {
        NSString *str = [dic objectForKey:@"down"];
        messageLab.text = [NSString stringWithFormat:@"收到数据下 %@ ",str];
    }
}

//连接成功处理
-(void)connectSuccessAction:(NSNotification *)notify {
   messageLab.text = @"蓝牙连接成功";
    
    //测试
    connectBtn.hidden = YES;
    cancelBtn.hidden = YES;
}
//连接失败处理
-(void)disConnectAction:(NSNotification *)notify {
    messageLab.text = @"蓝牙连接失败";
    connectBtn.hidden = NO;
}

//重新连接
-(void)actionReConnect:(UIButton *)btn {
    messageLab.text = @"蓝牙正在重新连接....";
    
    //测试的话，重新连接要先取消连接
#warning 可以先取消 或者加个判断已连接 return
//    [[HMBLECenterHandle sharedHMBLECenterHandle] cancelConnect];
    [[HMBLECenterHandle sharedHMBLECenterHandle] scan];
}

//取消连接
-(void)actionCancel:(UIButton *)btn {
    [[HMBLECenterHandle sharedHMBLECenterHandle] cancelConnect];
}

//发送
- (void)actionSend:(UIButton *)btn {
    NSInteger BLE_SEND_MAX_LEN = 512;
    imgName = [imgName isEqualToString:@"2.jpg"] ? @"3.jpg" : @"2.jpg";
    testImgView.image = [UIImage imageNamed:imgName];
    
    NSData *msgData = UIImageJPEGRepresentation([UIImage imageNamed:imgName], 1.0);

    for (int i = 0; i < [msgData length]; i += BLE_SEND_MAX_LEN) {
        // 预加 最大包长度，如果依然小于总数据长度，可以取最大包数据大小
        if ((i + BLE_SEND_MAX_LEN) < [msgData length]) {
            NSString *rangeStr = [NSString stringWithFormat:@"%i,%li", i, (long)BLE_SEND_MAX_LEN];
            NSData *subData = [msgData subdataWithRange:NSRangeFromString(rangeStr)];
            
            [[HMBLECenterHandle sharedHMBLECenterHandle] wrietPeripheral:nil
                                                          characteristic:nil
                                                                   value:subData];
            //根据接收模块的处理能力做相应延时
            usleep(20 * 1000);
        }
        else {
            NSString *rangeStr = [NSString stringWithFormat:@"%i,%i", i, (int)([msgData length] - i)];
            NSData *subData = [msgData subdataWithRange:NSRangeFromString(rangeStr)];
            [[HMBLECenterHandle sharedHMBLECenterHandle] wrietPeripheral:nil
                                                          characteristic:nil
                                                                   value:subData];

            usleep(20 * 1000);
            
            //发送结束标识
            NSData *exoData = [@"exo" dataUsingEncoding:NSUTF8StringEncoding];
            [[HMBLECenterHandle sharedHMBLECenterHandle] wrietPeripheral:nil
                                                          characteristic:nil
                                                                   value:exoData];

        }
    }
    
}

@end
