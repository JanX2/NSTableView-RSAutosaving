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

#if __has_include("NSTableColumn+JXZoomable.h")
#	import "NSTableColumn+JXZoomable.h"
#	define JXZOOMABLE_ENABLED	1
#endif

NSString * const RSAutosavingColumnWidthKey = @"AutosavedColumnWidth";
NSString * const RSAutosavingColumnIndexKey = @"AutosavedColumnIndex";
NSString* const RSAutosavingColumnHiddenKey = @"AutosavedColumnHidden";


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
#ifdef JXZOOMABLE_ENABLED
		NSNumber *thisWidth = @(thisCol.unzoomedWidth);
#else
		NSNumber *thisWidth = @(thisCol.width);
#endif
		thisColDict[RSAutosavingColumnWidthKey] = thisWidth;
		
		// Save index
		NSInteger thisColIndex = [self columnWithIdentifier:thisColID];
		NSNumber *thisIndex = @(thisColIndex);
		thisColDict[RSAutosavingColumnIndexKey] = thisIndex;
		thisColDict[RSAutosavingColumnHiddenKey] = @(thisCol.isHidden);
		
		// Add it all to the big dict
		autoDict[thisColID] = thisColDict;
	}
	
	return autoDict;
}

- (void)adjustLayoutForAutosavedDictionary:(NSDictionary *)theDict
{
	// To get the column ordering right we have to make sure we "move" columns
	// to their respective indices from left to right, so that we never upset
	// the order of indices. So let's get an ordering of our keys by column index.
	NSArray *sortedColumnKeys = [theDict keysSortedByValueUsingSelector:@selector(compareByAutosavedIndex:)];
	
	NSRange columnIndexRange = NSMakeRange(0, self.numberOfColumns);
	
	// Set widths and index to saved values
	NSString *thisIdentifier;
	for (thisIdentifier in sortedColumnKeys) {
		NSDictionary *thisColDict = theDict[thisIdentifier];
		NSNumber *storedIndexNum = thisColDict[RSAutosavingColumnIndexKey];
		NSNumber *columnWidthNum = thisColDict[RSAutosavingColumnWidthKey];
		
		// Ensure proper column location
		NSInteger currentIndex = [self columnWithIdentifier:thisIdentifier];
		NSInteger desiredIndex = [storedIndexNum integerValue];
		if ((storedIndexNum != nil) &&
			(currentIndex != -1) &&
			(desiredIndex != -1) &&
			(NSLocationInRange(desiredIndex, columnIndexRange))) {
			[self moveColumn:currentIndex toColumn:desiredIndex];
		}
		
		// And adjust the width
		NSTableColumn *thisCol = [self tableColumnWithIdentifier:thisIdentifier];
		if ((columnWidthNum != nil) && (thisCol != nil)) {
			// Disable autosizing magic, because it interferes with our noble efforts
			// to set the width to a darned specific value.
			NSInteger saveMask = thisCol.resizingMask;
			thisCol.resizingMask = 0;
#ifdef JXZOOMABLE_ENABLED
			thisCol.unzoomedWidth = (CGFloat)columnWidthNum.doubleValue;
#else
			thisCol.width = (CGFloat)columnWidthNum.doubleValue;
#endif
			thisCol.resizingMask = saveMask;
			
			if(thisColDict[RSAutosavingColumnHiddenKey])
				thisCol.hidden = [thisColDict[RSAutosavingColumnHiddenKey] boolValue];
		}
	}
}

@end


@implementation NSDictionary (RSTableViewAutosaving)

// Implementing a custom comparator on NSDictionary is the easiest way to take care
// or reordering by a sub-attribute (the autosaved column index).

- (NSComparisonResult)compareByAutosavedIndex:(NSDictionary *)otherDict
{
	NSNumber *myIndex = self[RSAutosavingColumnIndexKey];
	NSNumber *otherIndex = otherDict[RSAutosavingColumnIndexKey];
	return [myIndex compare:otherIndex];
}

@end
