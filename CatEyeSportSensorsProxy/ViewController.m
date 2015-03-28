//
//  ViewController.m
//  CatEyeSportSensorsProxy
//
//  Created by 中村太郎 on 2015/03/27.
//  Copyright (c) 2015年 中村太郎. All rights reserved.
//

#import "ViewController.h"
#import "CSSCentralManager.h"
#import "CSSHRMSensor.h"
#import "CSSHRMService.h"
#import "CSSCSCSensor.h"
#import "CSSCSCService.h"

@interface ViewController ()
@property (strong, nonatomic) IBOutlet UILabel *speedMeter;
@property (strong, nonatomic) IBOutlet UILabel *rotationMeter;
@property (strong, nonatomic) IBOutlet UILabel *heartMeter;
@property (strong, nonatomic) IBOutlet UIButton *scanButton;
@property (nonatomic) NSInteger peripheralCount;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    CSSCentralManager *centralManager = [CSSCentralManager initSharedServiceWithDelegate:self];
    [self.scanButton addTarget:self action:@selector(scanButtonDown:) forControlEvents:UIControlEventTouchUpInside];
    
    [centralManager addObserver:self
                     forKeyPath:@"isScanning"
                        options:NSKeyValueObservingOptionNew
                        context:NULL];
    self.peripheralCount = 0;
    
    NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:1.0/60 target:self selector:@selector(meterUpdate:) userInfo:nil repeats:YES];
    
    [timer fire];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


-(void)scanButtonDown:(id)sender{
    self.peripheralCount = 0;
    CSSCentralManager *centralManager = [CSSCentralManager sharedService];
    
    if (centralManager.isScanning == NO) {
        [centralManager startScan];
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    }
    else {
        [centralManager stopScan];
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    }
}

- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
    
    switch (central.state) {
        case CBCentralManagerStatePoweredOn:
            break;
        case CBCentralManagerStatePoweredOff:
            break;
            
        case CBCentralManagerStateUnsupported: {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Dang."
                                                            message:@"Unfortunately this device can not talk to Bluetooth Smart (Low Energy) Devices"
                                                           delegate:nil
                                                  cancelButtonTitle:@"Dismiss"
                                                  otherButtonTitles:nil];
            
            [alert show];
            break;
        }
            
            
        default:
            break;
    }
    
}

-(void)meterUpdate:(NSTimer *)timer{
    CSSCentralManager *centralManager = [CSSCentralManager sharedService];

    for(int i = 0;i<self.peripheralCount;i++){
        YMSCBPeripheral *per= [centralManager peripheralAtIndex:i];
        if([per isKindOfClass:CSSHRMSensor.class]){
            CSSHRMSensor *sen = (CSSHRMSensor *)per;
            if(sen.hrmmeter.sensorValues != nil ){
                self.heartMeter.text = [NSString stringWithFormat:@"%@ BPM",sen.hrmmeter.sensorValues[@"BPM"]];
            }
        }else if([per isKindOfClass:CSSCSCSensor.class]){
            CSSCSCSensor *sen = (CSSCSCSensor *)per;
            if(sen.cscmeter.sensorValues != nil){
                self.rotationMeter.text = [NSString stringWithFormat:@"%@ RPM",sen.cscmeter.sensorValues[@"keyCadence"]];
                self.speedMeter.text = [NSString stringWithFormat:@"%.1f km/h",[sen.cscmeter.sensorValues[@"keySpeed"] floatValue]];
            }
        }
    }

}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context{
    
    CSSCentralManager *centralManager = [CSSCentralManager sharedService];
    
    if (object == centralManager) {
        if ([keyPath isEqualToString:@"isScanning"]) {
            if (centralManager.isScanning) {
                [self.scanButton setTitle:@"Stop Scanning" forState:UIControlStateNormal];
            } else {
                [self.scanButton setTitle:@"Start Scan" forState:UIControlStateNormal];
            }
        }
    }
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error{
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral{
    self.peripheralCount++;
}

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI {
    
}

- (void)centralManager:(CBCentralManager *)central didRetrievePeripherals:(NSArray *)peripherals {
}

- (void)centralManager:(CBCentralManager *)central didRetrieveConnectedPeripherals:(NSArray *)peripherals {
    
}

@end
