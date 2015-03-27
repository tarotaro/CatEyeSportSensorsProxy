//
//  CSSHRMSensor.h
//  CatEyeSportSensorsProxy
//
//  Created by 中村太郎 on 2015/03/27.
//  Copyright (c) 2015年 中村太郎. All rights reserved.
//

#import "YMSCBPeripheral.h"

@class CSSHRMService;

@interface CSSHRMSensor : YMSCBPeripheral
@property (nonatomic, readonly) CSSHRMService *hrmmeter;
@end
