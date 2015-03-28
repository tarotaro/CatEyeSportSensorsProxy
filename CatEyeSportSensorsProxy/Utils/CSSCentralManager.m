//
//  CSSCentralManager.m
//  CatEyeSportSensorsProxy
//
//  Created by 中村太郎 on 2015/03/27.
//  Copyright (c) 2015年 中村太郎. All rights reserved.
//

#import "CSSCentralManager.h"
#import "CSSHRMSensor.h"
#import "CSSCSCSensor.h"
#import "YMSCBStoredPeripherals.h"

static CSSCentralManager *sharedCentralManager;

@implementation CSSCentralManager

+ (CSSCentralManager *)initSharedServiceWithDelegate:(id)delegate {
    if (sharedCentralManager == nil) {
        dispatch_queue_t queue = dispatch_queue_create("com.freeworks.cateyesportsproxy", 0);
        
        NSArray *nameList = @[@"CATEYE_CSC", @"CATEYE_HRM"];
        sharedCentralManager = [[super allocWithZone:NULL] initWithKnownPeripheralNames:nameList
                                                                                  queue:queue
                                                                   useStoredPeripherals:YES
                                                                             delegate:delegate];
        sharedCentralManager.peripheralDelegate = delegate;
    }
    return sharedCentralManager;
    
}


+ (CSSCentralManager *)sharedService {
    if (sharedCentralManager == nil) {
        NSLog(@"ERROR: must call initSharedServiceWithDelegate: first.");
    }
    return sharedCentralManager;
}

-(void)startScan{
    
    NSDictionary *options = @{ CBCentralManagerScanOptionAllowDuplicatesKey: @NO };
    
    
    __weak CSSCentralManager *this = self;
    [self scanForPeripheralsWithServices:nil
                                 options:options
                               withBlock:^(CBPeripheral *peripheral, NSDictionary *advertisementData, NSNumber *RSSI, NSError *error) {
                                   if (error) {
                                       NSLog(@"Something bad happened with scanForPeripheralWithServices:options:withBlock:");
                                       return;
                                   }
                                   
                                   NSLog(@"DISCOVERED: %@, %@, %@ db", peripheral, peripheral.name, RSSI);
                                   [this foundPeripheral:peripheral];
                               }];
    


}

-(void)handleFoundPeripheral:(CBPeripheral *)peripheral{
}

-(void)foundPeripheral:(CBPeripheral *)peripheral{
    YMSCBPeripheral *yp = [self findPeripheral:peripheral];
    
    if (yp == nil) {
        for (NSString *pname in self.knownPeripheralNames) {
            if ([pname isEqualToString:peripheral.name]) {
                if([pname isEqualToString:@"CATEYE_CSC"]){
                    CSSCSCSensor *sensor = [[CSSCSCSensor alloc] initWithPeripheral:peripheral
                                                                           central:self
                                                                            baseHi:0xF000000004514000
                                                                            baseLo:0xB000000000000000];
                    [sensor connect];
                    [self addPeripheral:sensor];
                }else if([pname isEqualToString:@"CATEYE_HRM"]){
                    CSSHRMSensor *sensor = [[CSSHRMSensor alloc] initWithPeripheral:peripheral
                                                                            central:self
                                                                             baseHi:0xF000000004514000
                                                                             baseLo:0xB000000000000000];
                    [sensor connect];
                    [self addPeripheral:sensor];
                }
                break;
            }
        }
    }
}

- (void)valueChange:(NSString *)valueType number:(NSNumber *)number{
    [self.peripheralDelegate peripheralValueChange:valueType number:number];
}

- (void)managerPoweredOnHandler {
    // TODO: Determine if peripheral retrieval works on stock Macs with BLE support.
    /*
     Using iMac with Cirago BLE USB adapter, retreival with return a CBPeripheral instance without properties
     correctly populated such as name. This behavior is not exhibited when running on iOS.
     */
    
    if (self.useStoredPeripherals) {
#if TARGET_OS_IPHONE
        NSArray *identifiers = [YMSCBStoredPeripherals genIdentifiers];
        [self retrievePeripheralsWithIdentifiers:identifiers];
#endif
    }
}

@end
