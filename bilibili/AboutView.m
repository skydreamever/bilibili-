//
//  AboutView.m
//  bilibili
//
//  Created by 孙龙霄 on 5/13/15.
//  Copyright (c) 2015 dream. All rights reserved.
//

#import "AboutView.h"

@interface NSAttributedString (Hyperlink)
+(id)hyperlinkFromString:(NSString*)inString withURL:(NSURL*)aURL;
@end

@implementation NSAttributedString (Hyperlink)
+(id)hyperlinkFromString:(NSString*)inString withURL:(NSURL*)aURL
{
    NSMutableAttributedString* attrString = [[NSMutableAttributedString alloc] initWithString: inString];
    NSRange range = NSMakeRange(0, [attrString length]);
    
    [attrString beginEditing];
    [attrString addAttribute:NSLinkAttributeName value:[aURL absoluteString] range:range];
    
    // make the text appear in blue
    [attrString addAttribute:NSForegroundColorAttributeName value:[NSColor blueColor] range:range];
    
    // next make the text appear with an underline
    [attrString addAttribute:
     NSUnderlineStyleAttributeName value:[NSNumber numberWithInt:NSUnderlineStyleSingle] range:range];
    
    [attrString endEditing];
    
    return attrString;
}
@end

@interface AboutView ()

@end

@implementation AboutView

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
}

- (void)loadView{
    
    [super loadView];
    [self.aboutbilibili setAllowsEditingTextAttributes:YES];
    [self.aboutbilibili setSelectable:YES];
    
    NSMutableAttributedString *attrString = [[NSMutableAttributedString alloc] init];
    [attrString appendAttributedString:[[NSAttributedString alloc] initWithString:@"本客户端仿照"]];
    
    [attrString appendAttributedString:[NSAttributedString hyperlinkFromString:@"https://github.com/typcn/bilibili-mac-client" withURL:[NSURL URLWithString:@"https://github.com/typcn/bilibili-mac-client"]]];
    
    [attrString appendAttributedString:[[NSAttributedString alloc] initWithString:@"完成，作者对这个客户端仅学习使用，如果侵权就与我联系。\n项目地址："]];
    
    [attrString appendAttributedString:[NSAttributedString hyperlinkFromString:@"https://github.com/skydreamever/bilibili-.git" withURL:[NSURL URLWithString:@"https://github.com/skydreamever/bilibili-.git"]]];
    [attrString appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n使用框架："]];
    
    
    
    [self.aboutbilibili setAttributedStringValue:attrString];
}

@end
