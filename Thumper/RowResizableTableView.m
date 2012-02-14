/*
 RowResizableTableView
 Written by Evan Jones <ejones@uwaterloo.ca>, 14-11-2002
 http://evanjones.ca/

 Released under the BSD Licence.

 That means that you can use this class in open source or commercial products.

 TODO LIST:
 - verifying that everything works when data sources change or update
 - verifying that it works in other nasty edge cases like that
 - move the scrollview when the text insertion point moves off the screen: Use NSLayoutManager to get the NSPoint of the insertion point
 - get this working with outline views
 - define an API to play nice with others
 - package, document, promote
 
 Copyright (c) 2004-2005, Evan Jones
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are
met:

      * Redistributions of source code must retain the above copyright
        notice, this list of conditions and the following disclaimer.
      * Redistributions in binary form must reproduce the above
        copyright notice, this list of conditions and the following
        disclaimer in the documentation and/or other materials provided
        with the distribution.
      * Neither the name of RowResizableViews nor the names of its
        contributors may be used to endorse or promote products derived
        from this software without specific prior written permission.
THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS
IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER
OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "RowResizableTableView.h"

#define DISPLAY_RECT(r) r.origin.x, r.origin.y, r.size.width, r.size.height

@interface _NSKeyboardFocusClipView : NSClipView
- (NSRect) _getFocusRingFrame;
- (void) _adjustFocusRingSize: (NSSize) adjustment;
- (void) _adjustFocusRingLocation: (NSPoint) adjustment;
@end

@implementation RowResizableTableView

#include "RowResizableViewImplementation.h"

- (id)initWithCoder:(NSCoder *)decoder
{
    self = [self commonInitWithCoder: decoder];

    if ( self )
        {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(columnDidResize:)
                                                     name:@"NSTableViewColumnDidResizeNotification"
                                                   object:self];
        }
    return self;
}

// Override frameOfCell so we can substitute our custom row rectangles
- (NSRect)frameOfCellAtColumn:(int)column row:(int)row
{
    //NSLog( @"frameOfCell column: %d row: %d", column, row );

    NSSize intercellSpacing = [self intercellSpacing];

    // TODO: Would it be more efficient to do column widths ourselves?
    NSRect rect = [self rectOfColumn: column];
    rect.origin.x += ((int)intercellSpacing.width/2);
    rect.size.width = rect.size.width - intercellSpacing.width;

    // When calculating cell heights we call this method to get the column widths set correctly.
    // Therefore, this function gets called before we have the rowOrigins or rowHeights arrays created,
    // and before our super class will even respond correctly to "frameOfCellAtColumn:row:".
    // So, we do this little test to determine if we are in that situation or not.
    if ( row < [rowOrigins count] )
        {
        rect.origin.y = [[rowOrigins objectAtIndex: row] floatValue] + ((int)intercellSpacing.height/2);
        rect.size.height = [[rowHeights objectAtIndex: row] floatValue];

        /* FIXED HEIGHT TEST:
            NSRect superRect = [super frameOfCellAtColumn: column row: row];
        //NSLog( @"(%f, %f) : %f X %f", DISPLAY_RECT( superRect ) );
        //NSLog( @"(%f, %f) : %f X %f", DISPLAY_RECT( rect ) );

        NSAssert( NSEqualRects( superRect, rect), @"super returned a different cell frame" );
        */
        }

    return rect;    
}


- (void)willDisplayCell: (NSCell*) dataCell forTableColumn: (NSTableColumn*) tabCol row: (int) row
{
    // Inform the delegate that we "willDisplayCell", if supported
    if ( respondsToWillDisplayCell )
        {
        [_delegate tableView: self willDisplayCell: dataCell forTableColumn: tabCol row: row];
        }
}

- (id) getValueForTableColumn: (NSTableColumn*) tabCol row: (int) row
{
    return [[self dataSource] tableView:self objectValueForTableColumn:tabCol row: row];
}


@end
