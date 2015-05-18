//
//  SettingViewController.m
//  bilibili
//
//  Created by 孙龙霄 on 5/18/15.
//  Copyright (c) 2015 dream. All rights reserved.
//

#import "SettingViewController.h"

@interface SettingViewController ()

@end

@implementation SettingViewController{
    NSUserDefaults *settings;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
    
    settings = [NSUserDefaults standardUserDefaults];
    [self.disableCmtInBottom setState:[settings integerForKey:@"disableCmtInBottom"]];
    
    float trans = [settings floatForKey:@"transparency"];
    if(!trans){
        trans = 0.8;
        
        [settings setFloat:0.8 forKey:@"transparency"];
        [settings synchronize];
        
    }
    [self.transparency setFloatValue:trans];
    [self.progressShow setStringValue:[NSString stringWithFormat:@"%0.2f%%",trans]];
    
    
    NSString *quality = [settings objectForKey:@"quality"];
    if([quality length] != 2){
        quality = @"原画";
        [settings setObject:quality forKey:@"quality"];
        [settings synchronize];
    }
    [self.quality setStringValue:quality];
    
    NSString *IP = [settings objectForKey:@"xff"];
    if([IP length] > 4){
        [self.fakeIP setStringValue:[settings objectForKey:@"xff"]];
    }
    
    float fontsize = [settings floatForKey:@"fontsize"];
    if(!fontsize){
        fontsize = 25.1;
        [settings setFloat:fontsize forKey:@"fontsize"];
    }
    [self.assFont setStringValue:[NSString stringWithFormat:@"%0.2f",fontsize]];

    
    
    
}
- (IBAction)disableCmtInBottom:(NSButton *)sender {
    
    [settings setInteger:[self.disableCmtInBottom state] forKey:@"disableCmtInBottom"];
    [settings synchronize];
    
}


- (IBAction)changeQuality:(NSComboBox *)sender {
    
    
    [settings setObject:[self.quality stringValue] forKey:@"quality"];
    [settings synchronize];
    
}


- (IBAction)changeFakeIP:(NSComboBox *)sender {
    NSString *rand = [NSString stringWithFormat:@"%ld", (long)(1 + arc4random_uniform(254))];
    NSString *str = [[self.fakeIP stringValue] stringByReplacingOccurrencesOfString:@"[RANDOM]" withString:rand];
    [settings setObject:str forKey:@"xff"];
    [settings synchronize];
    DLog(@"IP Changed to: %@",str);

}



- (IBAction)changeAssFont:(NSTextField *)sender {
    
    [settings setFloat:[self.assFont floatValue] forKey:@"fontsize"];
    [settings synchronize];

    
}



- (IBAction)changeTransparency:(NSSlider *)sender {
    
    [self.progressShow setStringValue:[NSString stringWithFormat:@"%0.2f%%",[self.transparency floatValue]]];

    
    [settings setFloat:[self.transparency floatValue] forKey:@"transparency"];
    [settings synchronize];

}


@end
