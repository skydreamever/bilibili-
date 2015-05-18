//
//  SettingViewController.h
//  bilibili
//
//  Created by 孙龙霄 on 5/18/15.
//  Copyright (c) 2015 dream. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface SettingViewController : NSViewController
@property (weak) IBOutlet NSButton *disableCmtInBottom;
@property (weak) IBOutlet NSComboBox *quality;

@property (weak) IBOutlet NSComboBox *fakeIP;

@property (weak) IBOutlet NSTextField *assFont;

@property (weak) IBOutlet NSSlider *transparency;

@property (weak) IBOutlet NSTextField *progressShow;

@end
