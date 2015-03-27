//
//  CSSHRMService.m
//  CatEyeSportSensorsProxy
//
//  Created by 中村太郎 on 2015/03/27.
//  Copyright (c) 2015年 中村太郎. All rights reserved.
//

#import "CSSHRMService.h"
#import "YMSCBCharacteristic.h"

@interface CSSHRMService ()

@property (nonatomic, strong) NSNumber *keyValue;

@end

@implementation CSSHRMService
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
        self.uuid = [CBUUID UUIDWithString:@"180D"];
        YMSCBCharacteristic *yc;
        
        yc = [[YMSCBCharacteristic alloc] initWithName:@"rate"
                                                parent:self.parent
                                                  uuid:[CBUUID UUIDWithString:@"2A37"]
                                                offset:0];
        
        self.characteristicDict[@"rate"] = yc;
    }
    return self;
}

- (void)notifyCharacteristicHandler:(YMSCBCharacteristic *)yc error:(NSError *)error {
    if (error) {
        return;
    }
    
    if ([yc.name isEqualToString:@"rate"]) {
        NSData *data = yc.cbCharacteristic.value;
        const uint8_t *reportData = [data bytes];
        uint16_t bpm = 0;
        
        if ((reportData[0] & 0x01) == 0) {
            // uint8 bpm
            bpm = reportData[1];
        } else {
            // uint16 bpm
            bpm = CFSwapInt16LittleToHost(*(uint16_t *)(&reportData[1]));
        }
        
        NSLog(@"%d",bpm);
        __weak CSSHRMService *this = self;
        _YMS_PERFORM_ON_MAIN_THREAD(^{
            [self willChangeValueForKey:@"sensorValues"];
            this.keyValue = [NSNumber numberWithInt:bpm];
            [self didChangeValueForKey:@"sensorValues"];
        });
    }
}

- (NSDictionary *)sensorValues{
    if(self.keyValue == nil) return nil;
    return @{ @"BPM": self.keyValue };
}
@end
