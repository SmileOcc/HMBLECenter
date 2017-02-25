//
//  HMBLECenterHandle.h
//  HMBLECenter
//
//  Created by FaceStar on 15-3-1.
//  Copyright (c) 2015年 occ. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>

@interface HMBLECenterHandle : NSObject<CBCentralManagerDelegate,CBPeripheralDelegate>{
    
    CBCharacteristic *_upCharacteristic;
    CBCharacteristic *_centerCharacteristic;
    CBCharacteristic *_downCharacteristic;
    CBCharacteristic *_imageCharacteristic;


}

+(HMBLECenterHandle *)sharedHMBLECenterHandle;

@property (nonatomic,strong)CBCentralManager *centralManager;
@property (nonatomic,strong)CBPeripheral     *discoveredPeripheral;

@property (nonatomic,strong)CBCharacteristic *writeCharacteristic;
@property (nonatomic,assign)BOOL isConnect;

-(void)scan;
-(void)stop;
-(void)cancelConnect;

/// 写入数据方法
- (void)sendCommandData:(NSData *)data;
- (void)wrietPeripheral:(CBPeripheral *)peripheral characteristic:(CBCharacteristic *)characteristic value:(NSData *)data;
@end
