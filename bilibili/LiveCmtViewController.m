//
//  LiveCmtViewController.m
//  bilibili
//
//  Created by 孙龙霄 on 5/15/15.
//  Copyright (c) 2015 dream. All rights reserved.
//


#import "LiveCmtViewController.h"
#import "Utils.h"

extern NSString *vCID;

@interface LiveCmtViewController ()
{
    NSMutableArray *content;
}
@end

@implementation LiveCmtViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
    
    [self.view setWantsLayer:YES];
    [self.view setLayer:[Utils layerFromRGB:1.0 :1.0 :1.0 :1.0]];
    
    content = [[NSMutableArray alloc] init];
    
//    
//    [[[NSApplication sharedApplication] keyWindow] orderBack:nil];
//    [[[NSApplication sharedApplication] keyWindow] resignKeyWindow];
//    [self.view.window makeKeyWindow];
//    [self.view.window makeMainWindow];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [NSTimer scheduledTimerWithTimeInterval:3
                                         target:self
                                       selector:@selector(loadComment)
                                       userInfo:nil
                                        repeats:YES];
    });
    
    
}

- (void)loadComment{
    
    
    
    NSURL* URL = [NSURL URLWithString:@"http://live.bilibili.com/ajax/msg"];
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:URL];
    request.HTTPMethod = @"POST";
    request.timeoutInterval = 5;
    
    NSUserDefaults *settingsController = [NSUserDefaults standardUserDefaults];
    NSString *xff = [settingsController objectForKey:@"xff"];
    if([xff length] > 4){
        [request setValue:xff forHTTPHeaderField:@"X-Forwarded-For"];
        [request setValue:xff forHTTPHeaderField:@"Client-IP"];
    }
    
    [request addValue:@"Mozilla/5.0 (Windows NT 6.1; WOW64; rv:6.0.2) Gecko/20100101 Firefox/6.0.2 Fengfan/1.0" forHTTPHeaderField:@"User-Agent"];
    
    NSMutableData *postBody = [NSMutableData data];
    [postBody appendData:[[NSString stringWithFormat:@"roomid=%@",vCID] dataUsingEncoding:NSUTF8StringEncoding]];
    [request setHTTPBody:postBody];
    
    NSURLResponse * response = nil;
    NSError * error = nil;
    NSData * videoAddressJSONData = [NSURLConnection sendSynchronousRequest:request
                                                          returningResponse:&response
                                                                      error:&error];
    NSError *jsonError;
    NSMutableDictionary *videoResult = [NSJSONSerialization JSONObjectWithData:videoAddressJSONData options:NSJSONWritingPrettyPrinted error:&jsonError];
    
    NSArray *data = [[videoResult objectForKey:@"data"] objectForKey:@"room"];;
    
    if(data){
        
        for (NSDictionary *dic in data){
            
            if ([content containsObject:dic] ) {
                continue;
            }
           
            [content addObject:dic];
        }
    }
    
    [self.tableView reloadData];
    
    NSInteger numberOfRows = [self.tableView numberOfRows];
    
    if (numberOfRows > 0)
        [self.tableView scrollRowToVisible:numberOfRows - 1];
    
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView{
    return content.count;
}

- (id)tableView:(NSTableView *)aTableView
objectValueForTableColumn:(NSTableColumn *)aTableColumn
            row:(NSInteger)rowIndex{
    NSDictionary *object = [content objectAtIndex:rowIndex];
    if(!object){
        return @"ERROR";
    }
    
    if([[aTableColumn identifier] isEqualToString:@"nickname"]){
        return [object valueForKey:@"nickname"];
    }else if([[aTableColumn identifier] isEqualToString:@"timeline"]){
        return [object valueForKey:@"timeline"];
    }else{
        return [object valueForKey:@"text"];
    }
}




@end
