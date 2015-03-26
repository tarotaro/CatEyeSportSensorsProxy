//
//  CSSCSCService.h
//  CatEyeSportSensorsProxy
//
//  Created by 中村太郎 on 2015/03/27.
//  Copyright (c) 2015年 中村太郎. All rights reserved.
//

#import "CSSBaseService.h"

@interface CSSCSCService : CSSBaseService
@property (nonatomic, strong, readonly) NSDictionary *sensorValues;
@property (nonatomic, strong, readonly) NSNumber *keyValue;
@end
