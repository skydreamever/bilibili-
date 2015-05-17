//
//  PlayLocalViewController.m
//  bilibili
//
//  Created by 孙龙霄 on 5/17/15.
//  Copyright (c) 2015 dream. All rights reserved.
//

#import "PlayLocalViewController.h"

extern NSString *vUrl;
extern NSString *vCID;
NSString *cmFile;



@interface PlayLocalViewController ()

@end

@implementation PlayLocalViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    vCID = @"LOCALVIDEO";
    
    // Do view setup here.
}
- (IBAction)selectVideo:(NSButton *)sender {
    
    NSOpenPanel* openDlg = [NSOpenPanel openPanel];
    [openDlg setCanChooseFiles:YES];
    [openDlg setAllowsMultipleSelection:NO];
    [openDlg setCanChooseDirectories:NO];
    [openDlg setPrompt:@"选择视频"];
    
    if ( [openDlg runModal] == NSModalResponseOK )
    {
        NSString* filepath = [openDlg URL].path;
        
        vUrl = filepath;
        NSArray *arr = [filepath componentsSeparatedByString:@"/"];
        [self.video setStringValue:[arr lastObject]];
    }
    
    
}


- (IBAction)selectASS:(id)sender {
    
    NSOpenPanel* openDlg = [NSOpenPanel openPanel];
    [openDlg setCanChooseFiles:YES];
    [openDlg setAllowsMultipleSelection:NO];
    [openDlg setCanChooseDirectories:NO];
    [openDlg setPrompt:@"选择弹幕"];
    
    if ( [openDlg runModal] == NSModalResponseOK )
    {
        NSString* filepath = [NSString stringWithFormat:@"%@",[openDlg URL]];
        cmFile = filepath;
        NSArray *arr = [filepath componentsSeparatedByString:@"/"];
        [self.ass setStringValue:[arr lastObject]];
    }
    
    
}


@end
