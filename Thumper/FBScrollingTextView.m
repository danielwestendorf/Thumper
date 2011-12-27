//
//  FBScrollingTextView.m
//  FBScrollingTextView
//
//  Created by Fábio Bernardo on 2/6/11.
//

#import "FBScrollingTextView.h"

#define kFBScrollingTextViewSpacing 0.25

#define kFBScrollingTextViewDefaultScrollingSpeed 3
#define kFBScrollingTextViewStartScrollingDelay 0.6

@implementation FBScrollingTextView
@synthesize scrollingSpeed;
@synthesize string;
@synthesize font;

- (void)scrollText {	
	cursor.x-=1;
	[self setNeedsDisplay:YES];
}

- (void)startScrolling {
	if (!tickTockScroll) {		
		tickTockScroll = [NSTimer scheduledTimerWithTimeInterval:refreshRate/scrollingSpeed target:self selector:@selector(scrollText) userInfo:nil repeats:YES];
	}
	[tickTockStartScrolling release];
	tickTockStartScrolling = nil;
}


- (CGFloat)stringWidth {
	if (!string) return 0;
	NSSize stringSize = [string sizeWithAttributes:[NSDictionary dictionaryWithObjectsAndKeys:font,NSFontAttributeName,nil]];
	return stringSize.width;
}


- (id)initWithFrame:(CGRect)frame {
    
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code.			
		scrollingSpeed = kFBScrollingTextViewDefaultScrollingSpeed;
		refreshRate = 0.05;	
		cursor = NSMakePoint(0, 0);
		self.font = [NSFont systemFontOfSize:[NSFont systemFontSize]];
    }
    return self;
}


- (void)setString:(NSString *)_string {
	if (tickTockScroll) {
		[tickTockScroll invalidate];
		[tickTockScroll release];
		tickTockScroll = nil;
	}
	if (tickTockStartScrolling) {
		[tickTockStartScrolling invalidate];
		[tickTockStartScrolling release];
		tickTockStartScrolling = nil;
	}
    
	cursor = NSMakePoint(0, 3);
	[string release];
	string = [_string retain];
	CGRect thisFrame = [super frame];
	if ([self stringWidth] > thisFrame.size.width) {
		if (!tickTockStartScrolling) {
			tickTockStartScrolling = [NSTimer scheduledTimerWithTimeInterval:kFBScrollingTextViewStartScrollingDelay target:self selector:@selector(startScrolling) userInfo:nil repeats:NO];
		}		
	} 
	[self setNeedsDisplay:YES];
    
}

- (void)drawRect:(CGRect)rect {
	[super drawRect:rect];
    // Drawing code.
	CGFloat sWidth = round([self stringWidth]);	
	CGFloat rWidth = round(rect.size.width);
	CGFloat spacing = round(rWidth*kFBScrollingTextViewSpacing);
    
	if ((cursor.x*-1) == sWidth) {		
		CGFloat diff = spacing - (sWidth+cursor.x);
		cursor.x = rWidth-diff;		
	}
    
	NSDictionary *attrs = [NSDictionary dictionaryWithObjectsAndKeys:font, NSFontAttributeName,nil];
	[string drawAtPoint:cursor withAttributes:attrs];
    
	CGFloat diff = spacing - (sWidth+cursor.x);	
	if (diff >= 0) {
		NSPoint point = NSMakePoint(rWidth-diff, cursor.y);
		[string drawAtPoint:point withAttributes:attrs];
	}
}


- (void)dealloc {
	[tickTockScroll invalidate];
	[tickTockScroll release];
	tickTockScroll = nil;
	[tickTockStartScrolling invalidate];
	[tickTockStartScrolling release];
	tickTockStartScrolling = nil;
	self.string = nil;
	self.font = nil;	
    [super dealloc];
}


@end