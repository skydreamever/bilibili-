//
//  ViewController.m
//  bilibili
//
//  Created by 孙龙霄 on 5/13/15.
//  Copyright (c) 2015 dream. All rights reserved.
//

#import "MainViewController.h"
#import "Utils.h"

@implementation MainViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.view.window setBackgroundColor:NSColor.whiteColor];
    self.view.layer.backgroundColor = CGColorCreateGenericRGB(255, 255, 255, 1.0f);
    [self.view.window makeKeyWindow];
    NSRect rect = [[NSScreen mainScreen] visibleFrame];
    [self.view setFrame:rect];
    
    
    [self setupWebView];
    
    // Do any additional setup after loading the view.
}



- (void)setupWebView{
    [_webView setFrameLoadDelegate:self];
    [_webView setUIDelegate:self];
    [_webView setResourceLoadDelegate:self];
    
    
    
    
    self.webView.mainFrameURL = @"http://www.bilibili.com/";
    
    DLog(@"Start Open Bilibili");
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(AVNumberUpdated:) name:@"AVNumberUpdate" object:nil];
    
    NSString *path = [[NSBundle mainBundle] pathForResource:@"inject" ofType:@"js"];
    
    NSError *err;
    
    _webScript = [[NSString alloc] initWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&err];
    
    if(err){
        [Utils showError:err];
    }

}

- (void)webView:(WebView *)webView didClearWindowObject:(WebScriptObject *)windowObject forFrame:(WebFrame *)frame{
    
    [windowObject setValue:self forKeyPath:@"window.external"];

}


- (void)webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)frame{
    
    [_webView stringByEvaluatingJavaScriptFromString:_webScript];

    
}




+ (NSString *)webScriptNameForSelector:(SEL)selector{
    if(selector == @selector(checkForUpdates))
        return @"checkForUpdates";
    if(selector == @selector(playVideoByCID:))
        return @"playVideoByCID";
    if(selector == @selector(downloadVideoByCID:))
        return @"downloadVideoByCID";
    return nil;
}

+ (BOOL)isSelectorExcludedFromWebScript:(SEL)selector{
    //是否让这些方法在javascript中执行，除了下面的都可以
    
    if(selector == @selector(checkForUpdates))
        return NO;
    if(selector == @selector(playVideoByCID:))
        return NO;
    if(selector == @selector(downloadVideoByCID:))
        return NO;
    
    return YES;
}

- (void)checkForUpdates{
    DLog(@"检查新版本升级")
}

- (void)playVideoByCID:(NSString *)cid{
    DLog(@"开始准备进行视频播放")
}

- (void)downloadVideoByCID:(NSString *)cide{
    
}


- (WebView *)webView:(WebView *)sender createWebViewWithRequest:(NSURLRequest *)request{
    return _webView;
}


- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.
}

- (void)AVNumberUpdated:(NSNotification *)notification {
    
    DLog(@"这里有点问题啊");
    
    NSString *url = [notification object];
    if ([[url substringToIndex:6] isEqual: @"http//"]) {
        
        url = [url substringFromIndex:6];
        
    }
    self.webView.mainFrameURL = [NSString stringWithFormat:@"http://%@", url];
}


@end