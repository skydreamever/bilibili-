//
//  MediaViewController.h
//  bilibili
//
//  Created by 孙龙霄 on 5/14/15.
//  Copyright (c) 2015 dream. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface MediaViewController: NSViewController
@property (weak) IBOutlet NSImageView *loadingImage;
@property (weak) IBOutlet NSTextField *statusShow;

@end
