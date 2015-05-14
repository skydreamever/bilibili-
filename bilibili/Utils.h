//
//  Utils.h
//  bilibili
//
//  Created by 孙龙霄 on 5/13/15.
//  Copyright (c) 2015 dream. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface Utils : NSObject

+ (void)showError:(NSError *)error;

+ (CALayer *)layerFromRGB:(CGFloat)red :(CGFloat)green :(CGFloat)blue :(CGFloat)alpha;
+ (NSString *)getDevInfo:(NSString *)key;

+ (NSString *) md5:(NSString *) input;

//CG_EXTERN CGColorRef CGColorCreateGenericRGB(CGFloat red, CGFloat green,

@end
