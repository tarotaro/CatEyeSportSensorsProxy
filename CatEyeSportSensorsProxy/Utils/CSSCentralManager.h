//
//  CSSCentralManager.h
//  CatEyeSportSensorsProxy
//
//  Created by 中村太郎 on 2015/03/27.
//  Copyright (c) 2015年 中村太郎. All rights reserved.
//

#import "YMSCBCentralManager.h"

@protocol CSSCentralManagerDelegate <NSObject>
-(void)peripheralValueChange:(NSString *)valueType number:(NSNumber *)number;
@end

@interface CSSCentralManager : YMSCBCentralManager
+ (CSSCentralManager *)initSharedServiceWithDelegate:(id)delegate;
+ (CSSCentralManager *)sharedService;
- (void)valueChange:(NSString *)valueType number:(NSNumber *)number;
@property (nonatomic, weak) id<CSSCentralManagerDelegate> peripheralDelegate;

@end
