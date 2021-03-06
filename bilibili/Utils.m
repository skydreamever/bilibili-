//
//  Utils.m
//  bilibili
//
//  Created by 孙龙霄 on 5/13/15.
//  Copyright (c) 2015 dream. All rights reserved.
//
#import <CommonCrypto/CommonDigest.h>
#import "Utils.h"

@implementation Utils



+ (void)showError:(NSError *)error
{
    NSError *err;
    NSAlert *alert = [[NSAlert alloc] init];
    [alert setMessageText:@"程序出现一些问题，请将错误反馈给开发者，错误文件位置/tmp/bilibili.txt"];
    [alert runModal];
    
    NSFileManager *fileManager = [[NSFileManager alloc]init];
    NSString *filePath = @"/tmp/bilibili.txt";
    
    if (![fileManager fileExistsAtPath:filePath]){
        [fileManager createFileAtPath:filePath contents:nil attributes:nil];
    }
    
    NSString *oldError = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:&err];
    
    NSMutableString *newError = [[NSMutableString alloc] init];
    [newError appendString:oldError];
    [newError appendString:@"\n\n"];
    [newError appendString:[NSString stringWithFormat:@"domain:%@\n",[error domain]]];
    [newError appendString:[NSString stringWithFormat:@"code:%ld\n",(long)[error code]]];
    
    NSArray* detailedErrors = [[error userInfo] objectForKey:NSDetailedErrorsKey];
    
    if(detailedErrors != nil && [detailedErrors count] > 0) {
        for(NSError* detailedError in detailedErrors) {
            [newError appendString:[NSString stringWithFormat:@"DetailedError: %@\n",[detailedError userInfo]]];
        }
        
    }else {
        [newError appendString:[NSString stringWithFormat:@"DetailedError: %@\n",[error userInfo]]];
    }
    
    [newError writeToFile:filePath atomically:YES encoding:NSUTF8StringEncoding error:&err];
    
}


+ (CALayer *)layerFromRGB:(CGFloat)red :(CGFloat)green :(CGFloat)blue :(CGFloat)alpha{

    CALayer *viewLayer = [CALayer layer];
    [viewLayer setBackgroundColor:CGColorCreateGenericRGB(red, green, blue, alpha)]; //RGB plus

    
    return viewLayer;
}

+ (NSString *)getDevInfo:(NSString *)key{
    
    NSString *plistPath = [[NSBundle mainBundle] pathForResource:@"developer" ofType:@"plist"];
    NSDictionary *data = [[NSDictionary alloc] initWithContentsOfFile:plistPath];
    return data[key];
    
}

+ (NSString *) md5:(NSString *) input
{
    const char *cStr = [input UTF8String];
    unsigned char digest[16];
    CC_MD5( cStr, (CC_LONG)strlen(cStr), digest ); // This is the md5 call
    
    NSMutableString *output = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    
    for(int i = 0; i < CC_MD5_DIGEST_LENGTH; i++)
        [output appendFormat:@"%02x", digest[i]];
    
    return  output;
    
}

+ (NSData *)videoJSONData:(NSString *)baseAPIUrl cid:(NSString *)cid quality:(int)quality{
    
    
    NSString *param = [NSString stringWithFormat:@"appkey=%@&otype=json&cid=%@&quality=%d%@",[Utils getDevInfo:@"appkey"],cid,quality,[Utils getDevInfo:@"appsec"]];
    
    NSString *sign = [Utils md5:[param stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    
    // Get Playback URL
    
    NSURL* URL = [NSURL URLWithString:[NSString stringWithFormat:baseAPIUrl,[Utils getDevInfo:@"appkey"],cid,quality,sign]];
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
    return [NSURLConnection sendSynchronousRequest:request
                                                          returningResponse:&response
                                                                      error:&error];
}


@end
