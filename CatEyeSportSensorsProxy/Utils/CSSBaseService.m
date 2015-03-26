//
//  CSSBaseService.m
//  CatEyeSportSensorsProxy
//
//  Created by 中村太郎 on 2015/03/27.
//  Copyright (c) 2015年 中村太郎. All rights reserved.
//

#import "CSSBaseService.h"
#import "YMSCBCharacteristic.h"
#import "YMSCBUtils.h"

@implementation CSSBaseService

- (instancetype)initWithName:(NSString *)oName
                      parent:(YMSCBPeripheral *)pObj
                      baseHi:(int64_t)hi
                      baseLo:(int64_t)lo
               serviceOffset:(int)serviceOffset {
    
    self = [super initWithName:oName
                        parent:pObj
                        baseHi:hi
                        baseLo:lo
                 serviceOffset:serviceOffset];
    
    
    if (self) {
        yms_u128_t pbase = self.base;
        
        if (![oName isEqualToString:@"simplekeys"]) {
            self.uuid = [YMSCBUtils createCBUUID:&pbase withIntBLEOffset:serviceOffset];
        }
    }
    return self;
}


- (void)addCharacteristic:(NSString *)cname withOffset:(int)addrOffset {
    YMSCBCharacteristic *yc;
    
    yms_u128_t pbase = self.base;
    
    CBUUID *uuid = [YMSCBUtils createCBUUID:&pbase withIntBLEOffset:addrOffset];
    
    yc = [[YMSCBCharacteristic alloc] initWithName:cname
                                            parent:self.parent
                                              uuid:uuid
                                            offset:addrOffset];
    
    self.characteristicDict[cname] = yc;
}


- (void)turnOff {
    __weak CSSBaseService *this = self;
    
    YMSCBCharacteristic *configCt = self.characteristicDict[@"config"];
    [configCt writeByte:0x0 withBlock:^(NSError *error) {
        if (error) {
            NSLog(@"ERROR: %@", error);
            return;
        }
        
        NSLog(@"TURNED OFF: %@", this.name);
    }];
    
    YMSCBCharacteristic *dataCt = self.characteristicDict[@"data"];
    [dataCt setNotifyValue:NO withBlock:^(NSError *error) {
        NSLog(@"Data notification for %@ off", this.name);
        
    }];
    
    
    _YMS_PERFORM_ON_MAIN_THREAD(^{
        this.isOn = NO;
    });
}

- (void)turnOn {
    __weak CSSBaseService *this = self;
    
    YMSCBCharacteristic *configCt = self.characteristicDict[@"config"];
    [configCt writeByte:0x1 withBlock:^(NSError *error) {
        if (error) {
            NSLog(@"ERROR: %@", error);
            return;
        }
        
        NSLog(@"TURNED ON: %@", this.name);
    }];
    
    YMSCBCharacteristic *dataCt = self.characteristicDict[@"data"];
    [dataCt setNotifyValue:YES withBlock:^(NSError *error) {
        NSLog(@"Data notification for %@ on", this.name);
    }];
    
    
    _YMS_PERFORM_ON_MAIN_THREAD(^{
        this.isOn = YES;
    });
}

- (NSDictionary *)sensorValues
{
    NSLog(@"WARNING: -[%@ sensorValues] has not been implemented.", NSStringFromClass([self class]));
    return nil;
}

@end
