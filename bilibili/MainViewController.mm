//
//  ViewController.m
//  bilibili
//
//  Created by 孙龙霄 on 5/13/15.
//  Copyright (c) 2015 dream. All rights reserved.
//

#import "MainViewController.h"
#import "Utils.h"
#import "aria2.h"

NSString *vUrl;
NSString *vCID;
NSMutableArray *downloaderObjects;
BOOL playStatus = false;


@implementation MainViewController{
    aria2::Session* session;
    aria2::SessionConfig config;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.view.window setBackgroundColor:NSColor.whiteColor];
    self.view.layer.backgroundColor = CGColorCreateGenericRGB(255, 255, 255, 1.0f);
    [self.view.window makeKeyWindow];
    NSRect rect = [[NSScreen mainScreen] visibleFrame];
    [self.view setFrame:rect];
    
    NSArray *TaskList = [[NSUserDefaults standardUserDefaults] arrayForKey:@"DownloadTaskList"];
    downloaderObjects = [TaskList copy];

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

int downloadEventCallback(aria2::Session* session, aria2::DownloadEvent event,
                          aria2::A2Gid gid, void* userData){
    switch(event) {
        case aria2::EVENT_ON_DOWNLOAD_COMPLETE:{
            
            break;
        }
        case aria2::EVENT_ON_DOWNLOAD_ERROR:{
            NSUserNotification *notification = [[NSUserNotification alloc] init];
            notification.title = @"Bilibili Client";
            notification.informativeText = @"下载失败";
            notification.soundName = NSUserNotificationDefaultSoundName;
            [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notification];
            break;
        }
        default:
            return 0;
    }
    return 0;
}


- (void)downloadVideoByCID:(NSString *)cid{
 
    
    
    NSAlert *alert = [[NSAlert alloc] init];
    [alert setMessageText:@"注意：下载功能仅供测试，可能有各种 BUG，支持分段视频，默认保存在 Movies 文件夹。\n点击 文件->下载管理 来查看任务"];
    [alert runModal];
    
    if(!downloaderObjects){
        downloaderObjects = [[NSMutableArray alloc] init];
    }
    NSArray *filename = [_webView.mainFrameTitle componentsSeparatedByString:@"-"];
    config.downloadEventCallback = downloadEventCallback;
    session = aria2::sessionNew(aria2::KeyVals(), config);
    NSString *path = [NSString stringWithFormat:@"%@%@%@/",NSHomeDirectory(),@"/Movies/Bilibili/",[filename objectAtIndex:0]];
    aria2::changeGlobalOption(session, {{ "dir", [path cStringUsingEncoding:NSUTF8StringEncoding] }});
    aria2::changeGlobalOption(session, {{ "user-agent", "Mozilla/5.0 (Windows NT 6.1; WOW64; rv:6.0.2) Gecko/20100101 Firefox/6.0.2 Fengfan/1.0" }});
    aria2::KeyVals options;
    

    NSData * videoAddressJSONData = [Utils videoJSONData:@"http://interface.bilibili.com/playurl?appkey=%@&otype=json&cid=%@&quality=%d&sign=%@" cid:cid quality:4];
    
    NSError *jsonError;
    NSMutableDictionary *videoResult = [NSJSONSerialization JSONObjectWithData:videoAddressJSONData options:NSJSONWritingPrettyPrinted error:&jsonError];
    
    NSArray *dUrls = [videoResult objectForKey:@"durl"];
    
    if([dUrls count] == 0){
        return;
    }
    
    [[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:NULL];
    
    NSString *commentUrl = [NSString stringWithFormat:@"http://comment.bilibili.com/%@.xml",cid];
    
    NSURL  *url = [NSURL URLWithString:commentUrl];
    NSData *data = [NSData dataWithContentsOfURL:url];
    [data writeToFile:[NSString stringWithFormat:@"%@%@.xml",path,cid] atomically:YES];
    
    if([[[[videoResult objectForKey:@"durl"] valueForKey:@"url"] className] isEqualToString:@"__NSCFString"]){
        NSString *tmp = [[videoResult objectForKey:@"durl"] valueForKey:@"url"];
        std::vector<std::string> uris = {[tmp cStringUsingEncoding:NSUTF8StringEncoding]};
        aria2::addUri(session, nullptr, uris, options);
        
    }else{
        for (NSDictionary *match in dUrls) {
            NSString *tmp = [match valueForKey:@"url"];
            std::vector<std::string> uris = {[tmp cStringUsingEncoding:NSUTF8StringEncoding]};
            aria2::addUri(session, nullptr, uris, options);
        }
    }
    
    NSDictionary *taskData = @{
                               @"name":[filename objectAtIndex:0],
                               @"status":@"正在准备",
                               };
    int index = (int)[downloaderObjects count];
    [downloaderObjects insertObject:taskData atIndex:index];
    
    dispatch_async( dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSUserNotification *notification = [[NSUserNotification alloc] init];
        notification.title = @"Bilibili Client";
        notification.informativeText = @"下载已开始，通过 文件->下载管理 来查看进度";
        notification.soundName = NSUserNotificationDefaultSoundName;
        [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notification];
        
        for(;;) {
            int rv = aria2::run(session, aria2::RUN_ONCE);
            if(rv != 1) {
                break;
            }
            aria2::GlobalStat gstat = aria2::getGlobalStat(session);
            int allLength = 0;
            int currentLength = 0;
            std::vector<aria2::A2Gid> gids = aria2::getActiveDownload(session);
            for(const auto& gid : gids) {
                aria2::DownloadHandle* dh = aria2::getDownloadHandle(session, gid);
                if(dh) {
                    allLength = allLength + (int)dh->getTotalLength();
                    currentLength = currentLength + (int)dh->getCompletedLength();
                    aria2::deleteDownloadHandle(dh);
                }
            }
            [downloaderObjects removeObjectAtIndex:index];
            NSDictionary *taskData = @{
                                       @"name":[filename objectAtIndex:0],
                                       @"status":[NSString stringWithFormat:@"剩余分段:%d 下载速度:%dKB/s 大小:%d/%dMB",gstat.numActive,gstat.downloadSpeed/1024,currentLength/1024/1024,allLength/1024/1024],
                                       };
            [downloaderObjects insertObject:taskData atIndex:index];
        }
        int rv = aria2::sessionFinal(session);
        NSLog(@"Download success! STATUS: %d",rv);
        
        if(rv == 0){
            NSUserNotification *notification = [[NSUserNotification alloc] init];
            notification.title = @"Bilibili Client";
            notification.informativeText = @"视频与弹幕下载完成";
            notification.soundName = NSUserNotificationDefaultSoundName;
            [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notification];
        }
        
        [downloaderObjects removeObjectAtIndex:index];
        NSDictionary *taskData = @{
                                   @"name":[filename objectAtIndex:0],
                                   @"status":@"下载已完成",
                                   };
        [downloaderObjects insertObject:taskData atIndex:index];
    });

    
    
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
