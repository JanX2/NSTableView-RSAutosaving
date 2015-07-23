//
//  NSTableView+RSAutosaving.h
//  RSCommon
//
//  Created by Daniel Jalkut on 7/21/06.
//  Copyright 2006 Red Sweater Software. All rights reserved.
//
//	Freely licensed under the MIT license. See associated license file for details.
//

#import <Cocoa/Cocoa.h>

extern NSString * const RSAutosavingColumnWidthKey;
extern NSString * const RSAutosavingColumnIndexKey;

@interface NSTableView (RSAutosaving)
- (NSDictionary *)dictionaryForAutosavingLayout;
- (void)adjustLayoutForAutosavedDictionary:(NSDictionary *)theDict;
@end
