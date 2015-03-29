//
//  ViewController.h
//  CatEyeSportSensorsProxy
//
//  Created by 中村太郎 on 2015/03/27.
//  Copyright (c) 2015年 中村太郎. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CSSCentralManager.h"
#import <CoreLocation/CoreLocation.h>

@interface ViewController : UIViewController <CBCentralManagerDelegate,CBPeripheralDelegate,NSStreamDelegate,CLLocationManagerDelegate>


@end

