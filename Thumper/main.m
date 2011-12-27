//
//  main.m
//  Thumper
//
//  Created by Daniel Westendorf on 4/2/11.
//  Copyright 2011 Scott USA. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import <MacRuby/MacRuby.h>
#import "ThumperRemoteListener.h"
#import "FBScrollingTextView.h"

int main(int argc, char *argv[])
{
    return macruby_main("rb_main.rb", argc, argv);
}
