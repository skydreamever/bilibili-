//
//  ViewController.m
//  bilibili
//
//  Created by 孙龙霄 on 5/13/15.
//  Copyright (c) 2015 dream. All rights reserved.
//

#import "MainViewController.h"
#import "Utils.h"

NSString *vUrl;
NSString *vCID;
BOOL playStatus = false;

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


- (IBAction)openURL:(NSTextField *)sender {
    
    NSString *str = [sender stringValue];
    
    if (![self isMatchURL:str]) {
        if ([[str substringToIndex:6] isEqual: @"http//"]){
            _webView.mainFrameURL = [NSString stringWithFormat:@"http://%@", str];
        }else{
            _webView.mainFrameURL = str;
        }
    }else if(![self isNum:str]){
        //实际上因为av号也有4位长度的，但是这里以直播为4为主，如果有问题再进行更新
        if ([str length] != 4){
            _webView.mainFrameURL = [NSString stringWithFormat:@"http://www.bilibili.com/video/av%@",str];
        }else{
            _webView.mainFrameURL = [NSString stringWithFormat:@"http://live.bilibili.com/%@",str];
        }
    }else{

        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:@"请输入正确的格式"];
        [alert runModal];
        
    }
    
}

- (BOOL)isNum:(NSString *)str{
    NSScanner* scan = [NSScanner scannerWithString:str];
    int val;

    [scan scanInt:&val] && [scan isAtEnd];
    return [scan scanInt:&val] && [scan isAtEnd];

}


- (BOOL)isMatchURL:(NSString *)url{
    
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"/*[^/]+/video/av(\\d+)(/|/index.html|/index_(\\d+).html)?(\\?|#|$)" options:NSRegularExpressionCaseInsensitive error:nil];
    
    NSTextCheckingResult *match = [regex firstMatchInString:url options:NSMatchingReportProgress range:NSMakeRange(0, [url length])];
    
    if(match == nil){
        
        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"/*[^/]+/(\\d+)(/|/index.html|/index_(\\d+).html)?(\\?|#|$)" options:NSRegularExpressionCaseInsensitive error:nil];
        
        NSTextCheckingResult *match = [regex firstMatchInString:url options:NSMatchingReportProgress range:NSMakeRange(0, [url length])];
        return match == nil;
        
    }else{
        return NO;
    }
    
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
    DLog(@"开始准备进行视频播放，我们已经获得了cid：%@",cid);
    
    if (playStatus) {
        return;
    }
    
    playStatus = true;
    
    vCID = cid;
    vUrl = _webView.mainFrameURL;
    [self performSegueWithIdentifier:@"gotoMediaPlayer" sender:self];
    
    
    
}

- (void)downloadVideoByCID:(NSString *)cide{
    
}


- (WebView *)webView:(WebView *)sender createWebViewWithRequest:(NSURLRequest *)request{
    return _webView;
}

- (NSURLRequest *)webView:(WebView *)sender
                 resource:(id)identifier
          willSendRequest:(NSURLRequest *)request
         redirectResponse:(NSURLResponse *)redirectResponse
           fromDataSource:(WebDataSource *)dataSource{
    //这个我就直接拿过来，然后直接用啦
    NSString *URL = [request.URL absoluteString];
    NSMutableURLRequest *re = [[NSMutableURLRequest alloc] init];
    re = (NSMutableURLRequest *) request.mutableCopy;
    if([URL containsString:@"google"]){
        // Google ad is blocked in some (china) area, maybe take 30 seconds to wait for timeout
        [re setURL:[NSURL URLWithString:@"http://static.hdslb.com/images/transparent.gif"]];
    }else if([URL containsString:@"qq.com"]){
        // QQ analytics may block more than 10 seconds in some area
        [re setURL:[NSURL URLWithString:@"http://static.hdslb.com/images/transparent.gif"]];
    }else if([URL containsString:@"cnzz.com"]){
        // CNZZ is very slow in other country
        [re setURL:[NSURL URLWithString:@"http://static.hdslb.com/images/transparent.gif"]];
    }else{
        //这是所谓的IP伪造
        NSUserDefaults *settingsController = [NSUserDefaults standardUserDefaults];
        NSString *xff = [settingsController objectForKey:@"xff"];
        if([xff length] > 4){
            [re setValue:xff forHTTPHeaderField:@"X-Forwarded-For"];
            [re setValue:xff forHTTPHeaderField:@"Client-IP"];
        }
    }
    return re;
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
