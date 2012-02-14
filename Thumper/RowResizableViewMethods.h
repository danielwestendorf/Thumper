/*
 RowResizableViewMethods.h
 Written by Evan Jones <ejones@uwaterloo.ca>, 14-11-2002
 http://evanjones.ca/

 Released under the BSD Licence.

 That means that you can use this class in open source or commercial products.

 IMPORTANT NOTE:

 This file is included into both RowResizableTableView.h and RowResizableOutlineView.h. This is because these two classes share the implementation of the methods defined in this file.

 Yes, I know that this is an ugly hack, but it is the least ugly hack I could find. It is simple to use and to understand. Search the MacOSX-dev mailing list archives for the thread with the subject "Objective-C Multiple Inheritance Work Arounds?" for a detailed discussion. A short list of stuff I tried or thought about and rejected:

 - Hacking the classes so that RowResizableTableView could be both a subclass of NSTableView and NSOutlineView, and then RowResizeableOutlineView became a subclass of "RowResizableTableView-copy".
 - Using the "concrete protocols" library.

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


/* "PUBLIC" METHODS: These can be called by anyone. */
   
/** Sets the height for the specified row to the specified height. It will automatically adjust all other row origins and setNeedsDisplay if required. */
- (void) setHeightOfRow: (int) row toHeight: (float)height;


/* SUBCLASS OVERRIDES */
- (void) dealloc;

- (void) setDelegate: (id) obj;
- (void) tile;
- (void) viewDidEndLiveResize;
- (void) textDidEndEditing:(NSNotification *)aNotification;
- (void) textDidChange:(NSNotification *)notification;
- (NSRect) rectOfRow:(int)row;


/* "PRIVATE" METHODS: These methods are part of the "implementation" of RowResizable*View. */

/** Performs initialization (primarily of instance variables) that is common to both RowResizable*View. */
- (id) commonInitWithCoder: (NSCoder*) decoder;

    /** Recalculates the row heights for the entire table. */
- (void) recalculateGrid;
    /** Finds the height of the tallest cell in a specified row. */
- (float) maxHeightInRow:(int)row;
    /** Returns the cell object for the specified row and column. */
- (NSCell*) cellForRow:(int)row column:(int)col;

    /** Returns the height of the cell in the specified column and row. */
- (float) findHeightForColumn: (int) column row: (int) row withValue: (id) value;

/** Sets up dataCell to display the information in tabCol and row. */
- (void) willDisplayCell: (NSCell*) dataCell forTableColumn: (NSTableColumn*) tabCol row: (int) row;

- (id) getValueForTableColumn: (NSTableColumn*) tabCol row: (int) row;
- (void)columnDidResize:(NSNotification*)aNotification;
    /** Returns the rectange for the cells in a column, adjusted for intercell spacing and indent. */
//- (NSRect) rectOfCellsForColumn: (int) column row: (int) row;

