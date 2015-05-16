//
//  MediaViewController.m
//  bilibili
//
//  Created by 孙龙霄 on 5/14/15.
//  Copyright (c) 2015 dream. All rights reserved.
//

#import "MediaViewController.h"
#import "MediaInfoDLL.h"
#import "Utils.h"
#import "danmaku2ass.h"
#import "client.h"
#import "ISSoundAdditions.h"

extern NSString *vUrl;
extern NSString *vCID;
extern BOOL playStatus;
NSString *vAID;
NSString *vPID;
NSString *firstVideo;
NSString *res;



mpv_handle *mpv;

BOOL isCancelled;


static inline void check_error(int status)
{
    if (status < 0) {
        DLog(@"mpv API error: %s", mpv_error_string(status));
        exit(1);
    }
}

@interface MediaViewController ()
{
    int picture_num;
    dispatch_queue_t queue;
    NSWindow *w;
    NSView *playerView;


}
@end

@implementation MediaViewController

static void wakeup(void *context) {
    if(context){
        MediaViewController *a = (__bridge MediaViewController *) context;
        if(a){
            [a readEvents];
        }
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.view setWantsLayer:YES];
    [self.view setLayer:[Utils layerFromRGB:1.0 :1.0 :1.0 :1.0]];
    
    
    isCancelled = NO;
//    
//    [[[NSApplication sharedApplication] keyWindow] orderBack:nil];
//    [[[NSApplication sharedApplication] keyWindow] resignKeyWindow];
//    [self.view.window makeKeyWindow];
//    [self.view.window makeMainWindow];
    
    NSRect rect = [[NSScreen mainScreen] visibleFrame];
    NSNumber *viewHeight = [NSNumber numberWithFloat:rect.size.height];
    NSNumber *viewWidth = [NSNumber numberWithFloat:rect.size.width];
    res = [NSString stringWithFormat:@"%dx%d",[viewWidth intValue],[viewHeight intValue]];
    [self.view setFrame:rect];
    
    
    [self initContent];
    
    playerView = [self view];
    
    [_statusShow setStringValue:@"正在准备播放..."];
    [_statusShow setStringValue:[NSString stringWithFormat:@"%@\n外部电源接触...没有异常",_statusShow.stringValue]];
    
    [_statusShow setStringValue:[NSString stringWithFormat:@"%@\n思考形态以中文为基准，进行思维连接...",_statusShow.stringValue]];
    DLog(@"开始解析视频的地址")
    //下面的内容我直接拷贝了

    [self parseURL];
    
    
}






- (void)parseURL{
    
    NSString *baseAPIUrl;

    if([vCID isEqualToString:@"LOCALVIDEO"]){
//        if([vUrl length] > 5){
//            NSDictionary *VideoInfoJson = [self getVideoInfo:vUrl];
//            NSNumber *width = [VideoInfoJson objectForKey:@"width"];
//            NSNumber *height = [VideoInfoJson objectForKey:@"height"];
//            NSString *commentFile = @"/NotFound";
//            if([cmFile length] > 5){
//                commentFile = [self getComments:width :height];
//            }
//            [self PlayVideo:commentFile :res];
//            return;
//        }else{
//            [self.view.window performClose:self];
//        }
//        return;
    }else if([vUrl containsString:@"live.bilibili"]){
        baseAPIUrl = @"http://live.bilibili.com/api/playurl?appkey=%@&otype=json&cid=%@&quality=%d&sign=%@";
        vAID = @"LIVE";
        vPID = @"LIVE";
    }else{
    
        baseAPIUrl = @"http://interface.bilibili.com/playurl?appkey=%@&otype=json&cid=%@&quality=%d&sign=%@";

        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"http:/*[^/]+/video/av(\\d+)(/|/index.html|/index_(\\d+).html)?(\\?|#|$)" options:NSRegularExpressionCaseInsensitive error:nil];
        
        NSTextCheckingResult *match = [regex firstMatchInString:vUrl options:0 range:NSMakeRange(0, [vUrl length])];
        
        NSRange aidRange = [match rangeAtIndex:1];
        
        if(aidRange.length > 0){
            vAID = [vUrl substringWithRange:aidRange];
            NSRange pidRange = [match rangeAtIndex:3];
            if(pidRange.length > 0 ){
                vPID = [vUrl substringWithRange:pidRange];
            }
        }else{
            vAID = @"0";
        }
        
        if(![vPID length]){
            vPID = @"1";
        }
    }
    
    // Get Sign
    int quality = [self getSettings:@"quality"];
    
    
    
    NSString *param = [NSString stringWithFormat:@"appkey=%@&otype=json&cid=%@&quality=%d%@",[Utils getDevInfo:@"appkey"],vCID,quality,[Utils getDevInfo:@"appsec"]];
    
    NSString *sign = [Utils md5:[param stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    
    // Get Playback URL
    
    NSURL* URL = [NSURL URLWithString:[NSString stringWithFormat:baseAPIUrl,[Utils getDevInfo:@"appkey"],vCID,quality,sign]];
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:URL];
    request.HTTPMethod = @"GET";
    request.timeoutInterval = 5;
    
    NSUserDefaults *settingsController = [NSUserDefaults standardUserDefaults];
    NSString *xff = [settingsController objectForKey:@"xff"];
    if([xff length] > 4){
        [request setValue:xff forHTTPHeaderField:@"X-Forwarded-For"];
        [request setValue:xff forHTTPHeaderField:@"Client-IP"];
    }
    
    [request addValue:@"Mozilla/5.0 (Windows NT 6.1; WOW64; rv:6.0.2) Gecko/20100101 Firefox/6.0.2 Fengfan/1.0" forHTTPHeaderField:@"User-Agent"];
    
    NSURLResponse * response = nil;
    NSError * error = nil;
    NSData * videoAddressJSONData = [NSURLConnection sendSynchronousRequest:request
                                                          returningResponse:&response
                                                                      error:&error];
    NSError *jsonError;
    NSMutableDictionary *videoResult = [NSJSONSerialization JSONObjectWithData:videoAddressJSONData options:NSJSONWritingPrettyPrinted error:&jsonError];
    
    NSArray *dUrls = [videoResult objectForKey:@"durl"];

    if([dUrls count] == 0){
        [_statusShow setStringValue:[NSString stringWithFormat:@"%@失败",_statusShow.stringValue]];
        return;
    }

    NSArray *BackupUrls;
    
    if([[[[videoResult objectForKey:@"durl"] valueForKey:@"url"] className] isEqualToString:@"__NSCFString"]){
        vUrl = [[videoResult objectForKey:@"durl"] valueForKey:@"url"];
        firstVideo = vUrl;
    }else{
        for (NSDictionary *match in dUrls) {
            if([dUrls count] == 1){
                vUrl = [match valueForKey:@"url"];
                firstVideo = vUrl;
                
                NSArray *burl = [match valueForKey:@"backup_url"];
                if([burl count] > 0){
                    BackupUrls = burl;
                }
            }else{
                NSString *tmp = [match valueForKey:@"url"];
                if(!firstVideo){
                    firstVideo = tmp;
                    vUrl = [NSString stringWithFormat:@"%@%@%lu%@%@%@", @"edl://", @"%",(unsigned long)[tmp length], @"%" , tmp ,@";"];
                }else{
                    vUrl = [NSString stringWithFormat:@"%@%@%lu%@%@%@",   vUrl   , @"%",(unsigned long)[tmp length], @"%" , tmp ,@";"];
                }
                
            }
        }
    }
    
    if(isCancelled){
        NSLog(@"Unloading");
        return;
    }
//
//    // ffprobe

    queue = dispatch_queue_create("mpv", DISPATCH_QUEUE_SERIAL);

    
    
    
    if([vUrl containsString:@"live_"]){
        dispatch_async(queue, ^{
            [self showLiveComment];
            [_statusShow setStringValue:[NSString stringWithFormat:@"%@连接没有异常",_statusShow.stringValue]];
            [self PlayVideo:@"" :res];

        });
        return;

    }
    

    
    dispatch_async(queue, ^{
        int usingBackup = 0;

        GetInfo:NSDictionary *VideoInfoJson = [self getVideoInfo:firstVideo];
        

        if (isCancelled) {
            return;
        }
        
        if([VideoInfoJson count] == 0){
            if(!BackupUrls){
                [_statusShow setStringValue:[NSString stringWithFormat:@"%@失败",_statusShow.stringValue]];
            }else{
                usingBackup++;
                NSString *backupVideoUrl = [BackupUrls objectAtIndex:usingBackup];
                if([backupVideoUrl length] > 0){
                    
                    firstVideo = backupVideoUrl;

                    vUrl = backupVideoUrl;
                    NSLog(@"Timeout! Change to backup url: %@",vUrl);
                    goto GetInfo;
                }else{
                    [_statusShow setStringValue:[NSString stringWithFormat:@"%@失败",_statusShow.stringValue]];
                }
            }
        }
        
        if(!jsonError){
            // Get Comment
            


                NSNumber *width = [VideoInfoJson objectForKey:@"width"];
                NSNumber *height = [VideoInfoJson objectForKey:@"height"];
                DLog(@"开始获取并解析弹幕");
                [_statusShow setStringValue:[NSString stringWithFormat:@"%@连接没有异常",_statusShow.stringValue]];

                if (isCancelled) {
                    return;
                }
                

                NSString *commentFile = [self getComments:width :height];
                [self PlayVideo:commentFile :res];




            
            //        [self PlayVideo:commentFile :res];
        }else{
            [_statusShow setStringValue:[NSString stringWithFormat:@"%@失败",_statusShow.stringValue]];
            return;
        }

        
    });
    

    

    if(isCancelled){
        NSLog(@"Unloading");
        return;
    }



}


- (NSDictionary *) getVideoInfo:(NSString *)url{
    
    MediaInfoDLL::MediaInfo MI;
    MI.Open([url cStringUsingEncoding:NSUTF8StringEncoding]);
    MI.Option(__T("Inform"), __T("Video;%Width%"));
    NSString *width = [NSString stringWithCString:MI.Inform().c_str() encoding:NSUTF8StringEncoding];
    MI.Option(__T("Inform"), __T("Video;%Height%"));
    NSString *height = [NSString stringWithCString:MI.Inform().c_str() encoding:NSUTF8StringEncoding];
    NSDictionary *info = @{
                           @"width": width,
                           @"height": height,
                           };
    return info;
}


- (float) getSettings:(NSString *) key
{
    NSUserDefaults *settingsController = [NSUserDefaults standardUserDefaults];
    if([key isEqualToString:@"quality"]){
        
        NSString *quality = [settingsController objectForKey:@"quality"];
        if([quality isEqualToString:@"高清"]){
            return 3;
        }else if ([quality isEqualToString:@"标清"]){
            return 2;
        }else if([quality isEqualToString:@"低清"]){
            return 1;
        }else{
            return 4;
        }
    }else if ([key isEqualToString:@"transparency"]){
        float result = [settingsController floatForKey:key];
        if(!result){
            return 0.8;
        }else{
            return result;
        }
    }else{
        float result = [settingsController floatForKey:key];
        if(!result){
            return 0;
        }else{
            return result;
        }
    }
}

- (void)initContent{
   
    picture_num = 0;
    [NSTimer scheduledTimerWithTimeInterval:0.1 target:self  selector:@selector(anim) userInfo:nil repeats:YES];

    [_statusShow setAllowsEditingTextAttributes:NO];
    [_statusShow setSelectable:NO];
    _statusShow.textColor = [NSColor grayColor];
    


    
    
}

- (NSString *) getComments:(NSNumber *)width :(NSNumber *)height {
    
    
    
    DLog(@"start");
    
    NSString *resolution = [NSString stringWithFormat:@"%@x%@",width,height];
    DLog(@"Video resolution: %@",resolution);

    
    BOOL LC = [vCID isEqualToString:@"LOCALVIDEO"];

    NSString *stringURL = [NSString stringWithFormat:@"http://comment.bilibili.com/%@.xml",vCID];
//    if(LC){
//        stringURL = cmFile;
//    }

    DLog(@"Getting Comments from %@",stringURL);
    
    NSURL  *url = [NSURL URLWithString:stringURL];
    NSData *urlData = [NSData dataWithContentsOfURL:url];
    
    if (urlData or LC)
    {
        NSString  *filePath = [NSString stringWithFormat:@"%@/%@.xml", @"/tmp",vCID];
        
        if(LC){
            NSString *correctString = [[NSString alloc] initWithData:urlData encoding:NSUTF8StringEncoding];
            urlData = [correctString dataUsingEncoding:NSUTF8StringEncoding];
        }
        
        [urlData writeToFile:filePath atomically:YES];
        
        NSString *OutFile = [NSString stringWithFormat:@"%@/%@.cminfo.ass", @"/tmp",vCID];
        
        float mq = 6.75*[width doubleValue]/[height doubleValue]-4;
        if(mq < 3.0){
            mq = 3.0;
        }
        if(mq > 8.0){
            mq = 8.0;
        }
        
        danmaku2ass([filePath cStringUsingEncoding:NSUTF8StringEncoding],
                    [OutFile cStringUsingEncoding:NSUTF8StringEncoding],
                    [width intValue],[height intValue],
                    "STHeiti",(int)[height intValue]/25.1,
                    [[NSString stringWithFormat:@"%.2f",[self getSettings:@"transparency"]] floatValue],
                    mq,5);
        
        DLog(@"Comment converted to %@",OutFile);
        [_statusShow setStringValue:[NSString stringWithFormat:@"%@\n同步率为110%%",_statusShow.stringValue]];

//        [self applyRegexCommentFilter:OutFile];
        
        return OutFile;
        
    }else{
        return @"";
    }

}

-(void) showLiveComment{
    //既然弹幕没有办法在直播视频上显示，那我就新建一个能够显示弹幕的窗口了
    //还是跟以前想法一样，我3s中加载一次，主要是我网速不好，怕出问题
    
    [self performSegueWithIdentifier:@"showLiveComment" sender:self];

    
    
}


- (void)PlayVideo:(NSString*) commentFile :(NSString*)res{
//     Start Playing Video
    mpv = mpv_create();
    if (!mpv) {
        NSLog(@"Failed creating context");
        exit(1);
    }
    
    [_statusShow setStringValue:[NSString stringWithFormat:@"%@\n交互界面连接",_statusShow.stringValue]];
    
    int64_t wid = (intptr_t) self->playerView;
    check_error(mpv_set_option(mpv, "wid", MPV_FORMAT_INT64, &wid));
    
    // Maybe set some options here, like default key bindings.
    // NOTE: Interaction with the window seems to be broken for now.
    check_error(mpv_set_option_string(mpv, "input-default-bindings", "yes"));
    check_error(mpv_set_option_string(mpv, "input-vo-keyboard", "yes"));
    check_error(mpv_set_option_string(mpv, "input-media-keys", "yes"));
    check_error(mpv_set_option_string(mpv, "input-cursor", "yes"));
    
    check_error(mpv_set_option_string(mpv, "osc", "yes"));
    check_error(mpv_set_option_string(mpv, "autofit", [res cStringUsingEncoding:NSUTF8StringEncoding]));
    check_error(mpv_set_option_string(mpv, "script-opts", "osc-layout=bottombar,osc-seekbarstyle=bar"));
    
    check_error(mpv_set_option_string(mpv, "user-agent", [@"Mozilla/5.0 (Windows NT 6.1; WOW64; rv:6.0.2) Gecko/20100101 Firefox/6.0.2 Fengfan/1.0" cStringUsingEncoding:NSUTF8StringEncoding]));
    check_error(mpv_set_option_string(mpv, "framedrop", "vo"));
    check_error(mpv_set_option_string(mpv, "vf", "lavfi=\"fps=fps=60:round=down\""));
    
    if(![vUrl containsString:@"live_"]){
        check_error(mpv_set_option_string(mpv, "sub-ass", "yes"));
        check_error(mpv_set_option_string(mpv, "sub-file", [commentFile cStringUsingEncoding:NSUTF8StringEncoding]));
    }

    // request important errors
    check_error(mpv_request_log_messages(mpv, "warn"));
    
    check_error(mpv_initialize(mpv));
    
    // Register to be woken up whenever mpv generates new events.
    mpv_set_wakeup_callback(mpv, wakeup, (__bridge void *) self);
    
    // Load the indicated file
    
    const char *cmd[] = {"loadfile", [vUrl cStringUsingEncoding:NSUTF8StringEncoding], NULL};
    check_error(mpv_command(mpv, cmd));
}


-(NSSize)intrinsicContentSize
{

    
    NSRect frame = [_statusShow frame];
    
    CGFloat width = frame.size.width;
    
    // Make the frame very high, while keeping the width
    frame.size.height = CGFLOAT_MAX;
    
    // Calculate new height within the frame
    // with practically infinite height.
    CGFloat height = [_statusShow.cell cellSizeForBounds: frame].height;
    
    return NSMakeSize(width, height);
}


- (void)anim {
    picture_num = (++picture_num)%5;
    [_loadingImage setImage: [NSImage imageNamed:[NSString stringWithFormat:@"ani_loading_%d", picture_num+1]] ];
}



- (void) handleEvent:(mpv_event *)event
{
    switch (event->event_id) {
        case MPV_EVENT_SHUTDOWN: {
            mpv_detach_destroy(mpv);
            mpv = NULL;
            NSLog(@"Stopping player");
            break;
        }
            
        case MPV_EVENT_LOG_MESSAGE: {
            struct mpv_event_log_message *msg = (struct mpv_event_log_message *)event->data;
            NSLog(@"[%s] %s: %s", msg->prefix, msg->level, msg->text);
            break;
        }
            
        case MPV_EVENT_VIDEO_RECONFIG: {
            dispatch_async(dispatch_get_main_queue(), ^{
                NSArray *subviews = [self->playerView subviews];
                if ([subviews count] > 0) {
                    // mpv's events view
                    NSView *eview = [self->playerView subviews][0];
                    [self->w makeFirstResponder:eview];
                }
            });
            break;
        }
            
        case MPV_EVENT_START_FILE:{
            if([[[NSUserDefaults standardUserDefaults] objectForKey:@"FirstPlayed"] length] != 3){
                [[NSUserDefaults standardUserDefaults] setObject:@"yes" forKey:@"FirstPlayed"];
//                [self.textTip setStringValue:@"正在创建字体缓存"];
//                [self.subtip setStringValue:@"首次播放需要最多 2 分钟来建立缓存\n请不要关闭窗口"];
                [_statusShow setStringValue:[NSString stringWithFormat:@"%@\n安全装置解除\n移往播放口",_statusShow.stringValue]];

            }else{
                [_statusShow setStringValue:[NSString stringWithFormat:@"%@\n安全装置解除\n移往播放口",_statusShow.stringValue]];
            }
            break;
        }
            
        case MPV_EVENT_PLAYBACK_RESTART: {
            self.loadingImage.animates = false;
            break;
        }
            
        case MPV_EVENT_END_FILE:{
//            [self.textTip setStringValue:@"播放完成"];
            break;
        }
            
        default:
            NSLog(@"Player Event: %s", mpv_event_name(event->event_id));
    }
}

- (void) readEvents
{
    dispatch_async(queue, ^{
        while (mpv) {
            mpv_event *event = mpv_wait_event(mpv, 0);
            if(!event)
                break;
            if (event->event_id == MPV_EVENT_NONE)
                break;
            [self handleEvent:event];
        }
    });
}


@end


@interface PlayerWindow : NSWindow <NSWindowDelegate>

-(void)keyDown:(NSEvent*)event;

@end

@implementation PlayerWindow{
    
}

BOOL paused = NO;
BOOL hide = NO;
BOOL obServer = NO;
BOOL isFirstCall = YES;

- (NSArray *)customWindowsToEnterFullScreenForWindow:(NSWindow *)window{
    return nil;
}

- (void)window:(NSWindow *)window
startCustomAnimationToEnterFullScreenWithDuration:(NSTimeInterval)duration{
    
}

- (NSSize)windowWillResize:(NSWindow *)sender
                    toSize:(NSSize)frameSize{
    if(!obServer){
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowDidResize:) name:NSWindowDidResizeNotification object:self];
        obServer = YES;
    }else{
        if(mpv){
            if(strcmp(mpv_get_property_string(mpv,"pause"),"yes")){
                mpv_set_property_string(mpv,"pause","yes");
            }
        }
    }
    return frameSize;
}
- (void)windowDidResize:(NSNotification *)notification{
    [self performSelector:@selector(Continue) withObject:nil afterDelay:1.0];
}

- (void)Continue{
    if(mpv && !isFirstCall){
        if(strcmp(mpv_get_property_string(mpv,"pause"),"no")){
            mpv_set_property_string(mpv,"pause","no");
        }
    }else{
        isFirstCall = NO;
    }
}


-(void)keyDown:(NSEvent*)event
{
    if(!mpv){
        return;
    }
    switch( [event keyCode] ) {
        case 125:{
            [NSSound decreaseSystemVolumeBy:0.05];
            break;
        }
        case 126:{
            [NSSound increaseSystemVolumeBy:0.05];
            break;
        }
        case 124:{
            const char *args[] = {"seek", "5" ,NULL};
            mpv_command(mpv, args);
            break;
        }
        case 123:{
            const char *args[] = {"seek", "-5" ,NULL};
            mpv_command(mpv, args);
            break;
        }
        case 49:{
            if(strcmp(mpv_get_property_string(mpv,"pause"),"no")){
                mpv_set_property_string(mpv,"pause","no");
            }else{
                mpv_set_property_string(mpv,"pause","yes");
            }
            break;
        }
        case 36:{
//            [postCommentButton performClick:nil];
            break;
        }
        case 53:{ // Esc key to hide mouse
            if(hide == YES){
                hide = NO;
                [NSCursor unhide];
            }else{
                hide = YES;
                [NSCursor hide];
            }
            break;
        }
        case 7:{ // X key to loop
            mpv_set_option_string(mpv, "loop", "inf");
            break;
        }
        default:
            NSLog(@"Key pressed: %hu", [event keyCode]);
            break;
    }
}

- (void) mpv_stop
{
    if (mpv) {
        const char *args[] = {"stop", NULL};
        mpv_command(mpv, args);
    }
}

- (void) mpv_quit
{
    if (mpv) {
        const char *args[] = {"quit", NULL};
        mpv_command(mpv, args);
    }
}

- (BOOL)windowShouldClose:(id)sender{
    
    isCancelled = YES;
   
    if (mpv) {
//        mpv_set_wakeup_callback(mpv, NULL,NULL);
        
        [self mpv_stop];
        [self mpv_quit];
   
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"LiveCmtClose" object:nil];
    

    playStatus = false;
    return YES;
}

@end

