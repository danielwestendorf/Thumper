//
//  FBScrollingTextView.h
//  FBScrollingTextView
//
//  Created by Fábio Bernardo on 2/6/11.
//

#import <Foundation/Foundation.h>


@interface FBScrollingTextView : NSView {	
	NSString *string;
	CGFloat scrollingSpeed;
	NSFont *font;
@private
	CGFloat refreshRate;
	NSTimer *tickTockStartScrolling;
	NSTimer *tickTockScroll;
	NSPoint cursor;
}
@property (readwrite, retain, nonatomic) NSFont *font;
@property (readwrite) CGFloat scrollingSpeed;
@property (readwrite, retain, nonatomic) NSString *string;
@end