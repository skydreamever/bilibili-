//
//  DownloadViewController.m
//  bilibili
//
//  Created by 孙龙霄 on 5/16/15.
//  Copyright (c) 2015 dream. All rights reserved.
//

#import "DownloadViewController.h"


extern NSMutableArray *downloaderObjects;


@interface DownloadViewController ()

@end

@implementation DownloadViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    [NSTimer scheduledTimerWithTimeInterval:3
                                     target:self
                                   selector:@selector(updateString)
                                   userInfo:nil
                                    repeats:YES];
}

-(void)updateString
{
    [self.tableView reloadData];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView{
    return downloaderObjects.count;
}

- (id)tableView:(NSTableView *)aTableView
objectValueForTableColumn:(NSTableColumn *)aTableColumn
            row:(NSInteger)rowIndex{
    NSDictionary *object = [downloaderObjects objectAtIndex:rowIndex];
    if(!object){
        return @"ERROR";
    }
    
    if([[aTableColumn identifier] isEqualToString:@"status"]){
        return [object valueForKey:@"status"];
    }else{
        return [object valueForKey:@"name"];
    }
}


@end
