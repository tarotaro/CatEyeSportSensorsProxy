# CatEyeSportSensorsProxy
Cat Eye Censor Sport Controller

## About this app 
This app is able to read Cat eye cycle sonsor value


## To Build
This app is used cocoapods so run next command in source code directory before xcode building
>pod install

## For other maker sensor
This app is able to support easy for other maker sensor
Next line chaned for other maker

* CSSCCentralManager.m:22

  This code is filter search for sensor.

  `NSArray *nameList = @[@"CATEYE_CSC", @"CATEYE_HRM"];`

* CSSCCentralManager.m:72

  This code is recognise Cadence and Speed sensor.

  `if([pname isEqualToString:@"CATEYE_CSC"]){`

* CSSCCentralManager.m:79

  This code is recognise Heart beat sensor.

  `}else if([pname isEqualToString:@"CATEYE_HRM"]){`

