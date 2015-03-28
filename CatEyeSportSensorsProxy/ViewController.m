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
#import <CFNetwork/CFNetwork.h>
#import <sys/socket.h>
#import <netinet/in.h>
#import <arpa/inet.h>
#import <ifaddrs.h>

@interface ViewController ()
@property (strong, nonatomic) IBOutlet UILabel *speedMeter;
@property (strong, nonatomic) IBOutlet UILabel *rotationMeter;
@property (strong, nonatomic) IBOutlet UILabel *heartMeter;
@property (strong, nonatomic) IBOutlet UILabel *ipAddress;
@property (strong, nonatomic) IBOutlet UIButton *scanButton;
@property (nonatomic) NSInteger peripheralCount;

@property (nonatomic,retain) NSInputStream * inputStream;
@property (nonatomic,retain) NSOutputStream * outputStream;
@property (nonatomic, retain) NSString *recvStr;
@property (nonatomic) bool ConectFlag;

@property (nonatomic) float speedMeterValue;
@property (nonatomic) int rotationMeterValue;
@property (nonatomic) int heartMeterValue;

@end

CFSocketContext ctx;
CFSocketRef     socketRef;

static void myHandleConnect(CFSocketRef socket, CFSocketCallBackType type, CFDataRef address, const void *data, void *pInfo);

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
    
    self.speedMeterValue = 0;
    self.rotationMeterValue = 0;
    self.heartMeterValue = 0;
    [timer fire];
    [self networkInitilize];
    self.ipAddress.text = [self getIPAddress];
    
}

-(void)networkInitilize{
    ctx.version = 0;
    ctx.info = (__bridge void*)self;
    ctx.retain = nil;
    ctx.release = nil;
    ctx.copyDescription = nil;
    
    CFSocketRef myipv4cfsock = CFSocketCreate(
                                              kCFAllocatorDefault,
                                              PF_INET,
                                              SOCK_STREAM,
                                              IPPROTO_TCP,
                                              kCFSocketAcceptCallBack,
                                              (CFSocketCallBack)myHandleConnect, &ctx);
    
    struct sockaddr_in sin;
    memset(&sin, 0, sizeof(sin));
    sin.sin_len = sizeof(sin);
    sin.sin_family = AF_INET; /* アドレスファミリ */
    sin.sin_port = htons(10000); /* または具体的なポート番号 */
    sin.sin_addr.s_addr= INADDR_ANY;
    CFDataRef sincfd = CFDataCreate(
                                    kCFAllocatorDefault,
                                    (UInt8 *)&sin,
                                    sizeof(sin));
    CFSocketSetAddress(myipv4cfsock, sincfd);
    CFRelease(sincfd);
    
    
    CFRunLoopSourceRef socketsource = CFSocketCreateRunLoopSource(
                                                                  kCFAllocatorDefault,
                                                                  myipv4cfsock,
                                                                  0);
    CFRunLoopAddSource(
                       CFRunLoopGetCurrent(),
                       socketsource,
                       kCFRunLoopDefaultMode);
}

- (NSString *)getIPAddress {
    NSString *address = @"";
    struct ifaddrs *interfaces = NULL;
    struct ifaddrs *temp_addr = NULL;
    int success = 0;
    success = getifaddrs(&interfaces);
    if (success == 0) {
        temp_addr = interfaces;
        while(temp_addr != NULL) {
            if(temp_addr->ifa_addr->sa_family == AF_INET) {
                if([[NSString stringWithUTF8String:temp_addr->ifa_name] isEqualToString:@"en0"]) {
                    address = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_addr)->sin_addr)];
                }
            }
            temp_addr = temp_addr->ifa_next;
        }
    }
    freeifaddrs(interfaces);
    return address;
}

static void myHandleConnect(CFSocketRef socket, CFSocketCallBackType type, CFDataRef address, const void *data, void *pInfo){
    NSLog(@"MyhandleConnect");
    
    ViewController *selfClass = (__bridge ViewController*) pInfo;
    
    NSLog(@"type:::%lu",type);
    
    if (CFSocketIsValid(socket) == FALSE) {
        NSLog(@"connection false");
        selfClass.RecvStr = @"Socket Disconnect!!";
        CFSocketInvalidate(socket);
        CFRelease(socket);
        selfClass.ConectFlag = FALSE;
        return;
    }
    
    if (type == kCFSocketAcceptCallBack) {
        NSLog(@"Socket accepted");
        CFSocketNativeHandle handle = *(CFSocketNativeHandle*)data;
        NSLog(@"accepted. (s = %p, handle=%d)", socket, handle);
        CFReadStreamRef readStream = NULL;
        CFWriteStreamRef writeStream = NULL;
        
        CFStreamCreatePairWithSocket(kCFAllocatorDefault, handle, &readStream, &writeStream);
        
        CFReadStreamSetProperty(readStream, kCFStreamPropertyShouldCloseNativeSocket, kCFBooleanTrue);
        CFWriteStreamSetProperty(writeStream, kCFStreamPropertyShouldCloseNativeSocket, kCFBooleanTrue);
        
        selfClass.inputStream = (__bridge NSInputStream *)readStream;
        selfClass.outputStream = (__bridge NSOutputStream *)writeStream;
        
        CFRelease(readStream);
        CFRelease(writeStream);
        
        selfClass.inputStream.delegate = selfClass;
        [selfClass.inputStream setProperty:(id)kCFBooleanTrue
                                    forKey:(NSString *)kCFStreamPropertyShouldCloseNativeSocket];
        [selfClass.inputStream scheduleInRunLoop:[NSRunLoop currentRunLoop]
                                         forMode:NSRunLoopCommonModes];
        [selfClass.inputStream open];
        [selfClass.outputStream open];
    }
    
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

- (void)stream:(NSStream *)theStream handleEvent:(NSStreamEvent)streamEvent{
    [self.inputStream setDelegate:self];
    NSLog(@"stream event %lu", streamEvent); //this doesn't post in the log when stream opened...
    NSMutableData *ddata;
    NSInteger sendType = -1;
    switch (streamEvent) {
        case NSStreamEventOpenCompleted:
            NSLog(@"Stream opened");
            break;
        case NSStreamEventHasBytesAvailable:{
            NSLog(@"has bytes available!");
            //if (theStream == inputStream) {
            NSLog(@"input Stream!!");
            ddata = [[NSMutableData alloc] init];

            uint8_t buffer[1024];
            int len;
            len = [(NSInputStream *)theStream read:buffer maxLength:1024];
            
            NSLog(@"len:%d",len);
            if(len) {
                [ddata appendBytes:(const void *)buffer length:len];
                sendType = 0;
                [ddata getBytes:(void *)&sendType length:sizeof(NSInteger)];
                int bytesRead = 0;
                bytesRead += len;
            } else {
                NSLog(@"No data.");
            }
            break;
        }
        case NSStreamEventErrorOccurred:
            NSLog(@"Can not connect to the host!");
            break;
        case NSStreamEventEndEncountered:
            [theStream close];
            [theStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
            theStream = nil;
            break;
        default:
            NSLog(@"Unknown event");
    }

    int value;
    float valuef;
    NSLog(@"sendType %d",sendType);
    uint8_t buffer[1024];
    memset(buffer,0,1024);
    switch(sendType){
        case 0:
            value = self.heartMeterValue;
            sprintf(buffer,"%d",value);
            [self.outputStream write:(const uint8_t *)buffer maxLength:1024];
            break;
        case 1:
            value = self.rotationMeterValue;
            sprintf(buffer,"%d",value);
            [self.outputStream write:(const uint8_t *)&buffer maxLength:1024];
            break;
        case 2:
            valuef = self.speedMeterValue;
            sprintf(buffer,"%f",valuef);
            [self.outputStream write:(const uint8_t *)&buffer maxLength:1024];
            break;
        default:
            break;
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
                self.heartMeterValue = [sen.hrmmeter.sensorValues[@"BPM"] integerValue];
            }
        }else if([per isKindOfClass:CSSCSCSensor.class]){
            CSSCSCSensor *sen = (CSSCSCSensor *)per;
            if(sen.cscmeter.sensorValues != nil){
                self.rotationMeter.text = [NSString stringWithFormat:@"%@ RPM",sen.cscmeter.sensorValues[@"keyCadence"]];
                self.speedMeter.text = [NSString stringWithFormat:@"%.1f km/h",[sen.cscmeter.sensorValues[@"keySpeed"] floatValue]];
                self.rotationMeterValue = [sen.cscmeter.sensorValues[@"keyCadence"] integerValue];
                self.speedMeterValue = [sen.cscmeter.sensorValues[@"keySpeed"] floatValue];
                
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
