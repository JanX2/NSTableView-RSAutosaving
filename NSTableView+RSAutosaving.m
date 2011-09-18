//
//  NSTableView+RSAutosaving.m
//  RSCommon
//
//  Created by Daniel Jalkut on 7/21/06.
//  Copyright 2006 Red Sweater Software. All rights reserved.
//
//	Freely licensed under the MIT license. See associated license file for details.
//

#import "NSTableView+RSAutosaving.h"

NSString* kAutosavedColumnWidthKey = @"AutosavedColumnWidth";
NSString* kAutosavedColumnIndexKey = @"AutosavedColumnIndex";

// We implement some methods on other classes as part of the private implementation.
// These are near the end of this file.
@interface NSTableColumn (RSTableViewAutosaving)
- (int) safeResizingMask;
- (void) setSafeResizingMask:(int) maskOrBOOL;
@end

@interface NSDictionary (RSTableViewAutosaving)
- (NSComparisonResult)compareByAutosavedIndex:(NSDictionary *)otherDict;
@end

@implementation NSTableView (RSAutosaving)

- (NSDictionary *) dictionaryForAutosavingLayout
{
	NSMutableDictionary* autoDict = [NSMutableDictionary dictionary];
	
	// Enumerate our columns and save width by column identifier
	NSEnumerator* colEnum = [[self tableColumns] objectEnumerator];
	NSTableColumn* thisCol;
	while (thisCol = [colEnum nextObject])
	{
		NSMutableDictionary* thisColDict = [NSMutableDictionary dictionary];
		NSString* thisColID = [thisCol identifier];
		
		// Save width
		NSNumber* thisWidth = [NSNumber numberWithFloat:[thisCol width]];
		[thisColDict setObject:thisWidth forKey:kAutosavedColumnWidthKey];
		
		// Save index
		NSNumber* thisIndex = [NSNumber numberWithInt:[self columnWithIdentifier:[thisCol identifier]]];
		[thisColDict setObject:thisIndex forKey:kAutosavedColumnIndexKey];

		// Add it all to the big dict
		[autoDict setObject:thisColDict forKey:thisColID];
	}
	
	return autoDict;
}

- (void) adjustLayoutForAutosavedDictionary:(NSDictionary*)theDict
{
	// To get the column ordering right we have to make sure we "move" columns 
	// to their respective indices from left to right, so that we never upset
	// the order of indices. So let's get an ordering of our keys by column index.
	NSArray* sortedColumnKeys = [theDict keysSortedByValueUsingSelector:@selector(compareByAutosavedIndex:)];
		
	// Set widths and index to saved values
	NSEnumerator* idEnum = [sortedColumnKeys objectEnumerator];
	NSString* thisIdentifier;
	while (thisIdentifier = [idEnum nextObject])
	{
		NSDictionary* thisColDict = [theDict objectForKey:thisIdentifier];

		// Ensure proper column location
		int currentIndex = [self columnWithIdentifier:thisIdentifier];
		int desiredIndex = [[thisColDict objectForKey:kAutosavedColumnIndexKey] intValue];
		[self moveColumn:currentIndex toColumn:desiredIndex];
		
		// And adjust the width
		NSTableColumn* thisCol = [self tableColumnWithIdentifier:thisIdentifier];
		if (thisCol != nil)
		{
			// Disable autosizing magic, because it interferes with our noble efforts
			// to set the width to a darned specific value.
			int saveMask = [thisCol safeResizingMask];		
			[thisCol setSafeResizingMask:0];
			[thisCol setWidth:[[thisColDict objectForKey:kAutosavedColumnWidthKey] floatValue]];
			[thisCol setSafeResizingMask:saveMask];
		}
	}
}

@end

@implementation NSTableColumn (RSTableViewAutosaving)

// We implement a 1-stop wrapper for setResizingMask and setResizable as appropriate 
// for the version of Mac OS X we are being built against.

- (int) safeResizingMask
{
	// 10.4 and later has "resizingMask". Earlier than that just pretend like the resizable BOOL is a mask
#if (MAC_OS_X_VERSION_MIN_REQUIRED >= 1040)
	return [self resizingMask];
#else
	return [self isResizable];
#endif
}

- (void) setSafeResizingMask:(int) maskOrBOOL
{
#if (MAC_OS_X_VERSION_MIN_REQUIRED >= 1040)
	[self setResizingMask:maskOrBOOL];
#else
	[self setResizable:maskOrBOOL];
#endif
}

@end

@implementation NSDictionary (RSTableViewAutosaving)

// Implementing a custom comparator on NSDictionary is the easiest way to take care
// or reordering by a sub-attribute (the autosaved column index).

- (NSComparisonResult)compareByAutosavedIndex:(NSDictionary *)otherDict
{	
	NSNumber* myIndex = [self objectForKey:kAutosavedColumnIndexKey];
	NSNumber* otherIndex = [otherDict objectForKey:kAutosavedColumnIndexKey];
	return [myIndex compare:otherIndex];
}

@end