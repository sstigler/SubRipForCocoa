//
//  NSScanner+SRTTags.m
//  JXSRTTagsSupport
//
//  Created by Jan Weiß on 2012-12-02.
//  Based on DTCoreText, Copyright 2011 Drobnik.com
//  Copyright 2012 geheimwerk.de. All rights reserved.
//
//  This software is licensed under the terms of the BSD license.
//

#import "NSScanner+SRTTags.h"
#import "NSCharacterSet+HTML.h"


NSString * const ItalicTagName			= @"i";
NSString * const BoldTagName			= @"b";
NSString * const UnderlineTagName		= @"u";
NSString * const FontTagName			= @"font";


static NSSet *_validTagNames = nil;

__attribute__((constructor))
static void initialize_validTagNames() {
	_validTagNames = [[NSSet alloc] initWithObjects:ItalicTagName, BoldTagName, UnderlineTagName, FontTagName, nil];
}

@implementation NSScanner (SRTTags)

- (BOOL)scanSRTTag:(NSString **)tagName attributes:(NSDictionary **)attributes isOpen:(BOOL *)isOpen isClosed:(BOOL *)isClosed;
{
	NSInteger initialScanLocation = [self scanLocation];
	
	if (![self scanString:@"<" intoString:NULL])
	{
		[self setScanLocation:initialScanLocation];
		return NO;
	}
	
	BOOL tagOpen = YES;
	BOOL immediatelyClosed = NO;
	BOOL invalidTag = NO;
	
	NSCharacterSet *tagCharacterSet = [NSCharacterSet tagNameCharacterSet];
	NSCharacterSet *tagAttributeNameCharacterSet = [NSCharacterSet tagAttributeNameCharacterSet];
	NSCharacterSet *quoteCharacterSet = [NSCharacterSet quoteCharacterSet];
	NSCharacterSet *whiteCharacterSet = [NSCharacterSet whitespaceAndNewlineCharacterSet];
	NSCharacterSet *nonquoteAttributedEndCharacterSet = [NSCharacterSet nonQuotedAttributeEndCharacterSet];
	
	NSString *scannedTagName = nil;
	NSMutableDictionary *tmpAttributes = [NSMutableDictionary dictionary];
	
	if ([self scanString:@"/" intoString:NULL])
	{
		// Close of tag
		tagOpen = NO;
	}
	
	// Read the tag name
	if ([self scanCharactersFromSet:tagCharacterSet intoString:&scannedTagName])
	{
		// make tags lowercase
		scannedTagName = [scannedTagName lowercaseString];
		if ([_validTagNames containsObject:scannedTagName])
		{
			[self scanCharactersFromSet:whiteCharacterSet intoString:NULL];
		}
		else
		{
			invalidTag = YES;
		}
	}
	else
	{
		invalidTag = YES;
	}
	
	if (invalidTag)
	{
		// not a valid tag, treat as text
		[self setScanLocation:initialScanLocation];
		return NO;
	}
	
	// Read attributes of tag
	while (![self isAtEnd] && !immediatelyClosed)
	{
		if ([self scanString:@"/" intoString:NULL])
		{
			immediatelyClosed = YES;
		}
		
		[self scanCharactersFromSet:whiteCharacterSet intoString:NULL];
		
		if ([self scanString:@">" intoString:NULL])
		{
			break;
		}
		
		NSString *attrName = nil;
		NSString *attrValue = nil;
		
		if (![self scanCharactersFromSet:tagAttributeNameCharacterSet intoString:&attrName])
		{
			immediatelyClosed = YES;
			break;
		}
		
		attrName = [attrName lowercaseString];
		
		[self scanCharactersFromSet:whiteCharacterSet intoString:NULL];
		
		if (![self scanString:@"=" intoString:nil])
		{
			// solo attribute
			[tmpAttributes setObject:attrName forKey:attrName];
		}
		else 
		{
			// attribute = value
			NSString *quote = nil;
			
			[self scanCharactersFromSet:whiteCharacterSet intoString:NULL];
			
			if ([self scanCharactersFromSet:quoteCharacterSet intoString:&quote])
			{
				if ([quote length]==1)
				{
					[self scanUpToString:quote intoString:&attrValue];	
					[self scanString:quote intoString:NULL];
				}
				else
				{
					// most likely e.g. href=""
					attrValue = @"";
				}

				[tmpAttributes setObject:attrValue forKey:attrName];
			}
			else 
			{
				// non-quoted attribute, ends at /, > or whitespace
				if ([self scanUpToCharactersFromSet:nonquoteAttributedEndCharacterSet intoString:&attrValue])
				{
					[tmpAttributes setObject:attrValue forKey:attrName];
				}
			}
		}
		
		[self scanCharactersFromSet:whiteCharacterSet intoString:NULL];
	}
	
	// Success 
	if (isClosed)
	{
		*isClosed = immediatelyClosed;
	}
	
	if (isOpen)
	{
		*isOpen = tagOpen;
	}
	
	if (attributes)
	{
		// converting to immutable costs 10.4% of method
		//*attributes = [NSDictionary dictionaryWithDictionary:tmpAttributes];
		*attributes = tmpAttributes;
	}
	
	if (tagName)
	{
		*tagName = scannedTagName;
	}
	
	return YES;
}

// for debugging scanner
- (void)srtLogPosition;
{
	NSLog(@"%@", [[self string] substringFromIndex:[self scanLocation]]);
}

@end
