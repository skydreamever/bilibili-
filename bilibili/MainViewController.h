//
//  ViewController.h
//  bilibili
//
//  Created by 孙龙霄 on 5/13/15.
//  Copyright (c) 2015 dream. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>

@interface MainViewController : NSViewController


@property (weak) IBOutlet WebView *webView;

@property (nonatomic,copy) NSString *webScript;

@property (nonatomic,copy) NSString *webUI;

@property (nonatomic,copy) NSString *webCss;

@end
