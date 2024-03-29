//
//  CSSCSCSensor.m
//  CatEyeSportSensorsProxy
//
//  Created by 中村太郎 on 2015/03/27.
//  Copyright (c) 2015年 中村太郎. All rights reserved.
//

#import "CSSCSCSensor.h"
#import "CSSBaseService.h"
#import "YMSCBCharacteristic.h"
#import "YMSCBDescriptor.h"
#import "CSSCentralManager.h"
#import "CSSCSCService.h"

@implementation CSSCSCSensor
- (instancetype)initWithPeripheral:(CBPeripheral *)peripheral
                           central:(YMSCBCentralManager *)owner
                            baseHi:(int64_t)hi
                            baseLo:(int64_t)lo {
    
    self = [super initWithPeripheral:peripheral central:owner baseHi:hi baseLo:lo];
    
    if (self) {
        CSSCSCService *csc = [[CSSCSCService alloc] initWithName:@"CSC" parent:self baseHi:hi baseLo:lo serviceOffset:0];
        
        self.serviceDict = @{@"CSC":csc};
        
    }
    return self;
    
}

- (void)connect {
    // Watchdog aware method
    [self resetWatchdog];
    
    [self connectWithOptions:nil withBlock:^(YMSCBPeripheral *yp, NSError *error) {
        if (error) {
            return;
        }
        
        // Example where only a subset of services is to be discovered.
        //[yp discoverServices:[yp servicesSubset:@[@"temperature", @"simplekeys", @"devinfo"]] withBlock:^(NSArray *yservices, NSError *error) {
        
        [yp discoverServices:[yp services] withBlock:^(NSArray *yservices, NSError *error) {
            if (error) {
                return;
            }
            
            for (YMSCBService *service in yservices) {
                
                __weak CSSBaseService *thisService = (CSSBaseService *)service;
                if([service isKindOfClass:CSSCSCService.class]){
                    CSSCSCService *ser = (CSSCSCService *)service;
                    [ser valiableInitialize];
                }
                [service discoverCharacteristics:[service characteristics] withBlock:^(NSDictionary *chDict, NSError *error) {
                    for (NSString *key in chDict) {
                        YMSCBCharacteristic *ct = chDict[key];
                        //NSLog(@"%@ %@ %@", ct, ct.cbCharacteristic, ct.uuid);
                        [ct setNotifyValue:YES withBlock:nil];
                        
                        [ct discoverDescriptorsWithBlock:^(NSArray *ydescriptors, NSError *error) {
                            if (error) {
                                return;
                            }
                            for (YMSCBDescriptor *yd in ydescriptors) {
                                NSLog(@"Descriptor: %@ %@ %@", thisService.name, yd.UUID, yd.cbDescriptor);
                            }
                        }];
                    }
                }];
            }
        }];
    }];
}

- ( CSSCSCService *)cscmeter {
    return self.serviceDict[@"CSC"];
}
@end
