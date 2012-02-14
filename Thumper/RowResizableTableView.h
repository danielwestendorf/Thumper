/*
 RowResizableTableView
 Written by Evan Jones <ejones@uwaterloo.ca>, 14-11-2002
 http://www.eng.uwaterloo.ca/~ejones/

 Released under the BSD Licence.

 That means that you can use this class in open source or commercial products.
 
 TODO LIST:
 - verifying that everything works when data sources change or update
 - verifying that it works in other edge cases like that
 - move the scrollview when the text insertion point moves off the screen
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

#import <AppKit/AppKit.h>

/** An NSTableView subclass which allows for resizable rows. At the moment the implementation is FAR from optimized, however it seems to run reasonably well with moderately sized tables. Right now, the table rows will resize itself to fit the contents of the text cells. In the future, it may be possible to programatically turn this feature on and off and use setHeightOfRow to programatically change the heights. */
@interface RowResizableTableView : NSTableView {

#include "RowResizableViewVars.h"
    
}

#include "RowResizableViewMethods.h"

// Gross hack to allow code sharing between RowResizable*Views
#define ROW_RESIZABLE_WILL_DISPLAY_CELL_SELECTOR @selector(tableView:willDisplayCell:forTableColumn:row:)

@end
