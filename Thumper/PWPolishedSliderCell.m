//
//  PWPolishedSliderCell.m
//  Play MiTunes
//
//  Created by Collin Henderson on 08/09/07.
//  Copyright 2007 Hendosoft. All rights reserved.
//

#import "PWPolishedSliderCell.h"

@implementation PWPolishedSliderCell

- (void)drawBarInside:(NSRect)cellFrame flipped:(BOOL)flipped
{
	NSImage *leftImage = [NSImage imageNamed:@"sliderleft.png"];
	NSImage *fillImage = [NSImage imageNamed:@"sliderfill.png"];
	NSImage *rightImage = [NSImage imageNamed:@"sliderright.png"];
				
	NSSize size = [leftImage size];
	float addX = size.width / 2.0;
	float y = NSMaxY(cellFrame) - (cellFrame.size.height-size.height)/2.0 ;
	float x = cellFrame.origin.x+addX;
	float fillX = x + size.width;
	float fillWidth = cellFrame.size.width - size.width - addX;
	
	[leftImage compositeToPoint:NSMakePoint(x, y) operation:NSCompositeSourceOver];

	size = [rightImage size];
	addX = size.width / 2.0;
	x = NSMaxX(cellFrame) - size.width - addX;
	fillWidth -= size.width+addX;
	
	[rightImage compositeToPoint:NSMakePoint(x, y) operation:NSCompositeSourceOver];
	
	[fillImage setScalesWhenResized:YES];
	[fillImage setSize:NSMakeSize(fillWidth, [fillImage size].height)];
	[fillImage compositeToPoint:NSMakePoint(fillX, y) operation:NSCompositeSourceOver];
}

- (void)drawKnob:(NSRect)rect
{
	NSImage *knob;
	
	if([self numberOfTickMarks] == 0)
		knob = [NSImage imageNamed:@"sliderbutton.png"];
	
	float x = rect.origin.x + (rect.size.width - [knob size].width) / 2;
	float y = NSMaxY(rect) - (rect.size.height - [knob size].height) / 2 ;
	
	[knob compositeToPoint:NSMakePoint(x, y) operation:NSCompositeSourceOver];
}

-(NSRect)knobRectFlipped:(BOOL)flipped
{
	NSRect rect = [super knobRectFlipped:flipped];
	if([self numberOfTickMarks] > 0){
		rect.size.height+=2;
		return NSOffsetRect(rect, 0, flipped ? 2 : -2);
		}
	return rect;
}

- (BOOL)_usesCustomTrackImage
{
	return YES;
}

@end
