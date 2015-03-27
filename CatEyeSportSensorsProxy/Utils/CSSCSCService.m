//
//  CSSCSCService.m
//  CatEyeSportSensorsProxy
//
//  Created by 中村太郎 on 2015/03/27.
//  Copyright (c) 2015年 中村太郎. All rights reserved.
//

#import "CSSCSCService.h"
#import "YMSCBCharacteristic.h"

@interface CSSCSCService ()

@property (nonatomic, strong) NSNumber *keyValue;

@end

@implementation CSSCSCService


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
        [self addCharacteristic:@"data" withAddress:0];
    }
    return self;
}

- (void)notifyCharacteristicHandler:(YMSCBCharacteristic *)yc error:(NSError *)error {
    if (error) {
        return;
    }
    
    if ([yc.name isEqualToString:@"data"]) {
        NSData *data = yc.cbCharacteristic.value;
        
        char val[data.length];
        [data getBytes:&val length:data.length];
        
        
        int16_t value = val[0];
        
        __weak CSSCSCService *this = self;
        _YMS_PERFORM_ON_MAIN_THREAD(^{
            [self willChangeValueForKey:@"sensorValues"];
            this.keyValue = [NSNumber numberWithInt:value];
            [self didChangeValueForKey:@"sensorValues"];
        });
    }
}

- (NSDictionary *)sensorValues{
    if(self.keyValue == nil) return nil;
    return @{ @"keyValue": self.keyValue };
}
@end
