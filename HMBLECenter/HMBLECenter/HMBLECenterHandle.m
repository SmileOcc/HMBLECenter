//
//  HMBLECenterHandle.m
//  HMBLECenter
//
//  Created by FaceStar on 15-3-1.
//  Copyright (c) 2015年 occ. All rights reserved.
//

#import "HMBLECenterHandle.h"

#define TRANSFER_SERVICE_UUID  @"0FB51F75-C9D5-45DC-BA61-065BD4A5E3E8"

//特征
#define TRANSFER_CHARACTERISTIC_Up_UUID @"B678C8E2-9B1A-4952-A320-EF6D42F0831A"
#define TRANSFER_CHARACTERISTIC_Center_UUID @"3146C446-1565-452A-8A3A-0093E653DCA7"
#define TRANSFER_CHARACTERISTIC_Down_UUID @"0430E936-1610-4EB0-9D97-D37F4EF56B39"

#define TRANSFER_CHARACTERISTIC_Image_UUID @"303DFE10-2C5D-4249-93A9-9B494F174E2F"


@implementation HMBLECenterHandle

+(HMBLECenterHandle *)sharedHMBLECenterHandle {
    static HMBLECenterHandle *sharedCenter = nil;
    static dispatch_once_t onecToken;
    dispatch_once(&onecToken,^{
        sharedCenter = [[self alloc] init];
        [sharedCenter initObject];
    });
    return  sharedCenter;
}

-(void)initObject {
    _centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];//nil表示在主线程中执行。
    _isConnect = NO;
}


// 1
-(void)centralManagerDidUpdateState:(CBCentralManager *)central{
    
    NSString *statStr = [NSString stringWithFormat:@"设备状态： %li",(long)central.state];
    
    if (central.state == CBCentralManagerStateUnsupported) {
        NSLog(@"该设备不支持");
        statStr = [statStr stringByAppendingString:@"该设备不支持"];
    }

    if (central.state != CBCentralManagerStatePoweredOn) {
        NSLog(@"蓝牙未打开,请在设置中打开蓝牙");
        return;
    }
    [self scan];
}




// 2 当扫描到4.0的设备后，系统会通过回调函数告诉我们设备的信息，然后我们就可以连接相应的设备
-(void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI {
    
    NSLog(@"%@",[NSString stringWithFormat:@"已发现 peripheral: %@ rssi: %@, UUID(identifier): %@ advertisementData: %@ ", peripheral, RSSI, peripheral.identifier, advertisementData]);
    
    int rssi = abs([peripheral.RSSI intValue]);
    float ci = (rssi - 49) / (10 * 4);
    NSString *length = [NSString stringWithFormat:@"发现BLT4.0热点:%@, *****  距离:%.1f 米",peripheral,pow(10,ci)];
    NSLog(@"距离：%@",length);
    
    if (_discoveredPeripheral != peripheral) {
        _discoveredPeripheral = peripheral;
        
        [_centralManager connectPeripheral:peripheral options:nil];
    }
}

-(void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error{
    NSLog(@"连接失败 ： %@，  %@",peripheral,error.localizedDescription);
    _isConnect = NO;
    
    if (_discoveredPeripheral) {
        _discoveredPeripheral.delegate = nil;
        _discoveredPeripheral = nil;
    }
}



// 3 当连接成功后，系统会通过回调函数告诉我们，然后我们就在这个回调里去扫描设备下所有的服务和特征
-(void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
    
    NSLog(@"%@",[NSString stringWithFormat:@"成功连接 peripheral: %@ with UUID(identifier): %@  \n",peripheral,peripheral.identifier]);
    [self stop];
    NSLog(@"已连接：停止扫描");
    
    _isConnect = YES;
    
    peripheral.delegate = self;
    
    //指定服务
    [peripheral discoverServices:[[NSArray alloc] initWithObjects:[CBUUID UUIDWithString:TRANSFER_SERVICE_UUID], nil]];
    //[peripheral discoverServices:nil];

    [[NSNotificationCenter defaultCenter] postNotificationName:@"didConnect_Notification" object:self userInfo:nil];
}

//掉线时调用
-(void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error{
    NSLog(@"外设已经断开");
    //discoveredPeripheral = nil;
    //[self scan];
    _isConnect = NO;
    
    if (_discoveredPeripheral) {
        _discoveredPeripheral.delegate = nil;
        _discoveredPeripheral = nil;
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:@"didDisconnect_Notification" object:self userInfo:nil];
}

-(void)peripheralDidUpdateRSSI:(CBPeripheral *)peripheral error:(NSError *)error {
    
    int rssi = abs([peripheral.RSSI intValue]);
    float ci = (rssi - 49) / (10 * 4.);
    NSString *length = [NSString stringWithFormat:@"发现BLT4.0热点:%@,\n距离:%.1f m",peripheral,pow(10,ci)];
    NSLog(@"距离：%@",length);
    
}





// 4 已发现服务
-(void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error{
    if (error != nil) {
        NSLog(@"error discovering service: %@",error.localizedDescription);
        return;
    }
    
    NSLog(@"服务： %@",peripheral.services);
    
    //处理我们需要的特征
    for (int i=0; i<peripheral.services.count; i++) {
        CBService *service = peripheral.services[i];
        NSLog(@"%@",[NSString stringWithFormat:@"%d :服务 UUID: %@(%@) 名字：%@  \n",i,service.UUID.data,service.UUID,peripheral.name]);
        
        //指定需要查找的特征（对应外设中订阅特征）
        [peripheral discoverCharacteristics:[[NSArray alloc] initWithObjects:[CBUUID UUIDWithString:TRANSFER_CHARACTERISTIC_Up_UUID],[CBUUID UUIDWithString:TRANSFER_CHARACTERISTIC_Center_UUID],[CBUUID UUIDWithString:TRANSFER_CHARACTERISTIC_Down_UUID],[CBUUID UUIDWithString:TRANSFER_CHARACTERISTIC_Image_UUID], nil] forService:service];
        //[peripheral discoverCharacteristics:nil forService:service];
    }
}


// 5 已搜索到Characteristics
-(void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error {
    if (error != nil) {
        NSLog(@"发现特征错误:  %@",error.localizedDescription);
        return;
    }
    
    
    NSLog(@"特征： %@",service.characteristics);
    
    //属于那个服务
    //根据不同的特征执行不同的命令
    if ([service.UUID isEqual:[CBUUID UUIDWithString:TRANSFER_SERVICE_UUID]]) {
        
        for (int i=0; i<service.characteristics.count; i++) {
            CBCharacteristic *characteristic = service.characteristics[i];
            
            
            NSLog(@"特征 UUID:   %@ (%@)  pro:%lu",characteristic.UUID.data,characteristic.UUID,(unsigned long)characteristic.properties);

            
            //上
            if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:TRANSFER_CHARACTERISTIC_Up_UUID]]) {
                //用于测试写数据到外设
                //保存写的特征
                _upCharacteristic = characteristic;
                
                //监听设备
                [peripheral setNotifyValue:YES forCharacteristic:characteristic];
            }
            
            //中
            if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:TRANSFER_CHARACTERISTIC_Center_UUID]]) {
                _centerCharacteristic = characteristic;

                [peripheral setNotifyValue:YES forCharacteristic:characteristic];
            }
            
            //下
            if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:TRANSFER_CHARACTERISTIC_Down_UUID]]) {
                _downCharacteristic = characteristic;
                
                [peripheral setNotifyValue:YES forCharacteristic:characteristic];
            }
            
            if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:TRANSFER_CHARACTERISTIC_Image_UUID]]) {
                _imageCharacteristic = characteristic;
                
                [peripheral setNotifyValue:YES forCharacteristic:characteristic];
            }
            
            
            // 连接成功，开始配对 - 发送第一次校验的数据
//            self.writeCharacteristic = characteristic;
//            [self willPairToPeripheral:peripheral];
        }
    }
    
    //其他服务.....
}




///获取外设发来的数据，不论是read和notify,获取数据都是从这个方法中读取。
-(void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    if (error != nil) {
        NSLog(@"发现特征错误:  %@",error.localizedDescription);
        return;
    }
    
    NSString *stringFromData = [[NSString alloc] initWithData:characteristic.value encoding:NSUTF8StringEncoding];
    NSLog(@"收到数据：%@",stringFromData);
    
    //测试
    if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:TRANSFER_CHARACTERISTIC_Up_UUID]]) {
        if (characteristic.value) {
            
            NSDictionary *dic = [[NSDictionary alloc] initWithObjectsAndKeys:stringFromData,@"up", nil];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"up_Notification"
                                                                object:self
                                                              userInfo:dic];
        }
    }
    else if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:TRANSFER_CHARACTERISTIC_Center_UUID]]) {
        if (characteristic.value) {
            NSDictionary *dic = [[NSDictionary alloc] initWithObjectsAndKeys:stringFromData,@"center", nil];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"center_Notification"
                                                                object:self
                                                              userInfo:dic];
        }
    }
    else if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:TRANSFER_CHARACTERISTIC_Down_UUID]]) {
        if (characteristic.value) {
            NSDictionary *dic = [[NSDictionary alloc] initWithObjectsAndKeys:stringFromData,@"down", nil];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"down_Notification"
                                                                object:self
                                                              userInfo:dic];
        }
    }
}


//中心读取外设实时数据
//这个方法一般不怎么用
-(void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error{
    
    //测试
    if (error != nil) {
        NSLog(@"特征通知状态变化错误:  %@",error.localizedDescription);
        
    } else {
        
        // Notification has started
        if (characteristic.isNotifying) {
            NSLog(@"特征通知已经开始：%@",characteristic);
            [peripheral readValueForCharacteristic:characteristic];
        } else {// Notification has stopped
            NSLog(@"特征通知已经停止： %@",characteristic);
            [_centralManager cancelPeripheralConnection:peripheral];
        }
    }
    
}



//通过制定的128的UUID，扫描外设备
-(void)scan{
    
//    [_centralManager scanForPeripheralsWithServices:[[NSArray alloc] initWithObjects:[CBUUID UUIDWithString:TRANSFER_SERVICE_UUID], nil]
//                                               options:[[NSDictionary alloc] initWithObjectsAndKeys:@true,CBCentralManagerScanOptionAllowDuplicatesKey, nil]];
    
    //扫描所有的  这个参数应该也是可以指定特定的peripheral的UUID,那么理论上这个central只会discover这个特定的设备
    NSArray *uuidArray = [NSArray arrayWithObjects:[CBUUID UUIDWithString:TRANSFER_SERVICE_UUID],nil];
    NSDictionary *optionsDic = [[NSDictionary alloc] initWithObjectsAndKeys:[NSNumber numberWithBool:NO],CBCentralManagerScanOptionAllowDuplicatesKey, nil];
    [_centralManager scanForPeripheralsWithServices:uuidArray options:optionsDic];
    
    NSLog(@"scanning started");
    
}
-(void)stop{
    [_centralManager stopScan];
    NSLog(@"Scanning stoped");
}


-(void)cancelConnect {
    //主动断开设备
    [_centralManager cancelPeripheralConnection:_discoveredPeripheral];

}



///已连接上设备,开始进行配对
- (void)willPairToPeripheral:(CBPeripheral *)peripheral{
    //发送第一次校验的数据
    NSLog(@"--- 发送第一次校验的数据 ---");
    NSData *firstAuthData = [@"520_start" dataUsingEncoding:NSUTF8StringEncoding];
    [[HMBLECenterHandle sharedHMBLECenterHandle] sendCommandData:firstAuthData];
}

/// 写入数据方法
- (void)sendCommandData:(NSData *)data {
    if(self.writeCharacteristic.properties & CBCharacteristicPropertyWrite || self.writeCharacteristic.properties & CBCharacteristicPropertyWriteWithoutResponse) {
        
        //（触发外设：当接收到中央端写的请求时会调用didReceiveWriteRequest）
        [self.discoveredPeripheral writeValue:data forCharacteristic:self.writeCharacteristic type:CBCharacteristicWriteWithResponse];
        NSLog(@"----写入命令---->:cmd：%@\n\n", data);
    } else {
        NSLog(@"该字段不可写！");
    }
}

- (void)wrietPeripheral:(CBPeripheral *)peripheral characteristic:(CBCharacteristic *)characteristic value:(NSData *)data {
    
    if(_imageCharacteristic.properties & CBCharacteristicPropertyWrite || _imageCharacteristic.properties & CBCharacteristicPropertyWriteWithoutResponse) {
        
        //（触发外设：当接收到中央端写的请求时会调用didReceiveWriteRequest）
        [self.discoveredPeripheral writeValue:data forCharacteristic:_imageCharacteristic type:CBCharacteristicWriteWithResponse];
        NSLog(@"----写入命令---->:cmd：%@\n\n", data);
    } else {
        NSLog(@"该字段不可写！");
    }
}


/// 写入数据后的回调方法
- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    if (error) {
        NSLog(@"写入失败: %@",[error localizedDescription]);
        return;
    }
    
    //（触发外设：当接收到中央端读的请求时会调用didReceiveReadRequest）
    //[peripheral readValueForCharacteristic:characteristic];
}








-(CBService *)getServiceFromUUID:(CBUUID *)UUID p:(CBPeripheral *)p
{
    
    for (CBService* s in p.services)
    {
        if ([s.UUID isEqual:UUID]) return s;
    }
    return nil; //Service not found on this peripheral
}

-(CBCharacteristic *) getCharacteristicFromUUID:(CBUUID *)UUID service:(CBService*)service {
    
    for (CBCharacteristic* c in service.characteristics)
    {
        if ([c.UUID isEqual:UUID]) return c;
    }
    return nil; //Characteristic not found on this service
}
@end
