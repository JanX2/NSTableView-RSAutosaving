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

NSString *kAutosavedColumnWidthKey = @"AutosavedColumnWidth";
NSString *kAutosavedColumnIndexKey = @"AutosavedColumnIndex";

// We implement some methods on other classes as part of the private implementation.
// These are near the end of this file.
@interface NSTableColumn (RSTableViewAutosaving)
- (NSInteger)safeResizingMask;
- (void)setSafeResizingMask:(NSInteger)maskOrBOOL;
@end

@interface NSDictionary (RSTableViewAutosaving)
- (NSComparisonResult)compareByAutosavedIndex:(NSDictionary *)otherDict;
@end

@implementation NSTableView (RSAutosaving)

- (NSDictionary *)dictionaryForAutosavingLayout
{
	NSMutableDictionary *autoDict = [NSMutableDictionary dictionary];
	
	// Loop over our columns and save width by column identifier
	NSTableColumn *thisCol;
	for (thisCol in [self tableColumns]) {
		NSMutableDictionary *thisColDict = [NSMutableDictionary dictionary];
		NSString *thisColID = [thisCol identifier];
		
		// Save width
		NSNumber *thisWidth = [NSNumber numberWithDouble:[thisCol width]];
		[thisColDict setObject:thisWidth forKey:kAutosavedColumnWidthKey];
		
		// Save index
		NSNumber *thisIndex = [NSNumber numberWithInteger:[self columnWithIdentifier:[thisCol identifier]]];
		[thisColDict setObject:thisIndex forKey:kAutosavedColumnIndexKey];
		
		// Add it all to the big dict
		[autoDict setObject:thisColDict forKey:thisColID];
	}
	
	return autoDict;
}

- (void)adjustLayoutForAutosavedDictionary:(NSDictionary *)theDict
{
	// To get the column ordering right we have to make sure we "move" columns
	// to their respective indices from left to right, so that we never upset
	// the order of indices. So let's get an ordering of our keys by column index.
	NSArray *sortedColumnKeys = [theDict keysSortedByValueUsingSelector:@selector(compareByAutosavedIndex:)];
	
	// Set widths and index to saved values
	NSString *thisIdentifier;
	for (thisIdentifier in sortedColumnKeys) {
		NSDictionary *thisColDict = [theDict objectForKey:thisIdentifier];
		
		// Ensure proper column location
		NSInteger currentIndex = [self columnWithIdentifier:thisIdentifier];
		NSInteger desiredIndex = [[thisColDict objectForKey:kAutosavedColumnIndexKey] integerValue];
		if ((currentIndex != -1) && (desiredIndex != -1)) {
			[self moveColumn:currentIndex toColumn:desiredIndex];
		}
		
		// And adjust the width
		NSTableColumn *thisCol = [self tableColumnWithIdentifier:thisIdentifier];
		if (thisCol != nil) {
			// Disable autosizing magic, because it interferes with our noble efforts
			// to set the width to a darned specific value.
			NSInteger saveMask = [thisCol safeResizingMask];
			[thisCol setSafeResizingMask:0];
			[thisCol setWidth:(CGFloat)[[thisColDict objectForKey:kAutosavedColumnWidthKey] doubleValue]];
			[thisCol setSafeResizingMask:saveMask];
		}
	}
}

@end

@implementation NSTableColumn (RSTableViewAutosaving)

// We implement a 1-stop wrapper for setResizingMask and setResizable as appropriate
// for the version of Mac OS X we are being built against.

- (NSInteger)safeResizingMask
{
	// 10.4 and later has "resizingMask". Earlier than that just pretend like the resizable BOOL is a mask
#if (MAC_OS_X_VERSION_MIN_REQUIRED >= 1040)
	return [self resizingMask];
#else
	return [self isResizable];
#endif
}

- (void)setSafeResizingMask:(NSInteger)maskOrBOOL
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
	NSNumber *myIndex = [self objectForKey:kAutosavedColumnIndexKey];
	NSNumber *otherIndex = [otherDict objectForKey:kAutosavedColumnIndexKey];
	return [myIndex compare:otherIndex];
}

@end
