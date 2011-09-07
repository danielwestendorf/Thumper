//
//  ThumperRemoteListener.m
//  Thumper
//
//  Created by Daniel Westendorf on 8/8/11.
//  Copyright 2011 Daniel Westendorf. All rights reserved.
//

#import "ThumperRemoteListener.h"
#import "HIDRemote.h"

@implementation ThumperRemoteListener

- (id)init
{
    self = [super init];
    if (self) {
        [self listen];
    }
    
    return self;
}

- (void)listen
{
    [[HIDRemote sharedHIDRemote] setDelegate:self];
	
    if ([[HIDRemote sharedHIDRemote] startRemoteControl:kHIDRemoteModeExclusiveAuto])
    {
        // Start successful
        //NSLog(@"started");
    }
    else
    {
        // Start failed
        //NSLog(@"start failed");
    }
}

- (void)hidRemote:(HIDRemote *)hidRemote eventWithButton:(HIDRemoteButtonCode)buttonCode isPressed:(BOOL)isPressed fromHardwareWithAttributes:(NSMutableDictionary *)attributes
{
	//NSLog(@"%@: Button with code %d %@", hidRemote, buttonCode, (isPressed ? @"pressed" : @"released"));
    if (isPressed) {
        switch (buttonCode) {
            case 3:
                [[NSNotificationCenter defaultCenter] postNotificationName:@"ThumperPreviousTrack" object:nil];
                break;
            case 4:
                [[NSNotificationCenter defaultCenter] postNotificationName:@"ThumperNextTrack" object:nil];
                break;
            case 5:
                [[NSNotificationCenter defaultCenter] postNotificationName:@"ThumperPlayToggle" object:nil];
                break;
            case 1:
                [[NSNotificationCenter defaultCenter] postNotificationName:@"ThumperVolumeUp" object:nil];
                break;
            case 2:
                [[NSNotificationCenter defaultCenter] postNotificationName:@"ThumperVolumeDown" object:nil];
                break;
            case 6:
                [[NSNotificationCenter defaultCenter] postNotificationName:@"ThumperWindowFront" object:nil];
                break;
            default:
                break;
        }
    }
}

@end
