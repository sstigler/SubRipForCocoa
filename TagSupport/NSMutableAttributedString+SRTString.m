//
//  NSMutableAttributedString+SRTString.m
//  JXSRTTagsSupport
//
//  Created by Jan Weiß on 2012-12-02.
//  Based on DTCoreText, Copyright 2011 Drobnik.com
//  Copyright 2012 geheimwerk.de. All rights reserved.
//
//  This software is licensed under the terms of the BSD license.
//

#import "JXSRTTagsSupport.h"

@implementation NSMutableAttributedString (SRTString)

- (id)initWithSRTString:(NSString *)srtString options:(NSDictionary *)options
{
	if (srtString.length == 0)
	{
		return [[NSMutableAttributedString alloc] initWithString:@""];
	}
	
	// custom option to scale text
	CGFloat textScale = [[options objectForKey:NSTextSizeMultiplierDocumentOption] floatValue];
	if (!textScale)
	{
		textScale = 1.0f;
	}
	
	// for performance reasons we will return this mutable string
	NSMutableAttributedString *tmpString = [[NSMutableAttributedString alloc] init];
	
#if ALLOW_IPHONE_SPECIAL_CASES
	CGFloat nextParagraphAdditionalSpaceBefore = 0.0;
#endif
	
	// we must not skip any characters
	NSScanner *scanner = [NSScanner scannerWithString:srtString];
	scanner.charactersToBeSkipped = nil;
	
	// base tag with font defaults
	DTCoreTextFontDescriptor *defaultFontDescriptor = [[DTCoreTextFontDescriptor alloc] initWithFontAttributes:nil];
	defaultFontDescriptor.pointSize = 12.0f * textScale;
	
	NSString *defaultFontFamily = [options objectForKey:DTDefaultFontFamily];
	if (defaultFontFamily)
	{
		defaultFontDescriptor.fontFamily = defaultFontFamily;
	}
	else
	{
		defaultFontDescriptor.fontFamily = @"Times New Roman";
	}
	
	// default paragraph style
	DTCoreTextParagraphStyle *defaultParagraphStyle = [DTCoreTextParagraphStyle defaultParagraphStyle];
	
	JXSRTElement *defaultTag = [[JXSRTElement alloc] init];
	defaultTag.fontDescriptor = defaultFontDescriptor;
	defaultTag.paragraphStyle = defaultParagraphStyle;
	defaultTag.textScale = textScale;
	
	id defaultColor = [options objectForKey:DTDefaultTextColor];
	if (defaultColor)
	{
		if ([defaultColor isKindOfClass:[DTColor class]])
		{
			// already a DTColor
			defaultTag.textColor = defaultColor;
		}
		else
		{
			// need to convert first
			defaultTag.textColor = [DTColor colorWithHTMLName:defaultColor];
		}
	}
	
	
	JXSRTElement *currentTag = defaultTag; // our defaults are the root
	
	while (![scanner isAtEnd]) 
	{
		NSString *tagName = nil;
		NSDictionary *tagAttributesDict = nil;
		BOOL tagOpen = YES;
		BOOL immediatelyClosed = NO;
		
		if ([scanner scanSRTTag:&tagName attributes:&tagAttributesDict isOpen:&tagOpen isClosed:&immediatelyClosed] && tagName)
		{
			if (tagOpen)
			{
				// make new tag as copy of previous tag
				JXSRTElement *parent = currentTag;
				currentTag = [currentTag copy];
				currentTag.tagName = tagName;
				currentTag.textScale = textScale;
				currentTag.attributes = tagAttributesDict;
				[parent addChild:currentTag];
			}
			
			// ---------- Processing
			
			if ([tagName isEqualToString:BoldTagName])
			{
				currentTag.fontDescriptor.boldTrait = YES;
			}
			else if ([tagName isEqualToString:ItalicTagName])
			{
				currentTag.fontDescriptor.italicTrait = YES;
			}
			else if ([tagName isEqualToString:UnderlineTagName])
			{
				if (tagOpen)
				{
					currentTag.underlineStyle = kCTUnderlineStyleSingle;
				}
			}
			else if ([tagName isEqualToString:FontTagName])
			{
				if (tagOpen)
				{
					NSInteger size = [[currentTag attributeForKey:@"size"] intValue];
					
					switch (size) 
					{
						case 1:
							currentTag.fontDescriptor.pointSize = textScale * 9.0f;
							break;
						case 2:
							currentTag.fontDescriptor.pointSize = textScale * 10.0f;
							break;
						case 4:
							currentTag.fontDescriptor.pointSize = textScale * 14.0f;
							break;
						case 5:
							currentTag.fontDescriptor.pointSize = textScale * 18.0f;
							break;
						case 6:
							currentTag.fontDescriptor.pointSize = textScale * 24.0f;
							break;
						case 7:
							currentTag.fontDescriptor.pointSize = textScale * 37.0f;
							break;	
						case 3:
						default:
							currentTag.fontDescriptor.pointSize = defaultFontDescriptor.pointSize;
							break;
					}
					
					NSString *face = [currentTag attributeForKey:@"face"];
					
					if (face)
					{
						currentTag.fontDescriptor.fontName = face;
						
						// face usually invalidates family
						currentTag.fontDescriptor.fontFamily = nil; 
					}
					
					NSString *color = [currentTag attributeForKey:@"color"];
					
					if (color)
					{
						currentTag.textColor = [DTColor colorWithHTMLName:color];       
					}
				}
			}
			
			// --------------------- push tag on stack if it's opening
			if (tagOpen && immediatelyClosed)
			{
				JXSRTElement *popChild = currentTag;
				currentTag = currentTag.parent;
				[currentTag removeChild:popChild];
			}
			else if (!tagOpen)
			{
				// check if this tag is indeed closing the currently open one
				if ([tagName isEqualToString:currentTag.tagName])
				{
					JXSRTElement *popChild = currentTag;
					currentTag = currentTag.parent;
					[currentTag removeChild:popChild];
				}
				else 
				{
					// Ignoring non-open tag
				}
			}
		}
		else 
		{
			//----------------------------------------- TAG CONTENTS -----------------------------------------
			NSString *tagContents = nil;
			
			// if we find a < at this stage then we can assume it was a malformed tag, need to skip it to prevent endless loop
			
			BOOL skippedAngleBracket = NO;
			if ([scanner scanString:@"<" intoString:NULL])
			{
				skippedAngleBracket = YES;
			}
			
			if (skippedAngleBracket || [scanner scanUpToString:@"<" intoString:&tagContents])
			{
				if (skippedAngleBracket)
				{
					if (tagContents)
					{
						tagContents = [@"<" stringByAppendingString:tagContents];
					}
					else
					{
						tagContents = @"<";
					}
				}
				
				if ([tagContents length])
				{
					tagName = currentTag.tagName;
					
					currentTag.text = tagContents;
					
					[tmpString appendAttributedString:[currentTag attributedString]];
				}
			}
		}
	}
	
	return tmpString;
}

#pragma mark Convenience Methods

+ (NSMutableAttributedString *)attributedStringWithSRTString:(NSString *)string options:(NSDictionary *)options;
{
	NSMutableAttributedString *attrString = [[NSMutableAttributedString alloc] initWithSRTString:string options:options];
	
	return attrString;
}

#pragma mark HTML Encoding

NS_INLINE void closeTags(NSOrderedSet *closingTagsStack, NSMutableString *taggedString)
{
    for (NSString *tag in closingTagsStack)
    {
        if ((tag == ItalicTagName) || (tag == BoldTagName) || (tag == UnderlineTagName))
        {
            [taggedString appendFormat:@"</%@>", tag];
        }
        else/* if (tag == FontTagName) // sort of… */
        {
            [taggedString appendFormat:@"</%@>", FontTagName];
        }
    }
}

@end


@implementation NSAttributedString (SRTString)

- (NSString *)srtString
{
	NSString *plainString = [self string];
	
	NSMutableString *taggedString = [NSMutableString string];
	
	NSRange plainStringRange = NSMakeRange(0, [plainString length]);
	
	// add the attributed string ranges in this paragraph to the paragraph container
	NSRange effectiveRange;
	NSUInteger index = plainStringRange.location;
	
	NSMutableOrderedSet *openTagsStack = [NSMutableOrderedSet orderedSet];
	NSString *prevFontTagWithAttributes = nil;
	
	NSUInteger plainStringRangeEnd = NSMaxRange(plainStringRange);
	
	NSMutableOrderedSet *closingTags = [NSMutableOrderedSet orderedSet];
	NSMutableOrderedSet *openingTags = [NSMutableOrderedSet orderedSet];
	
	while (index < plainStringRangeEnd)
	{
		NSDictionary *attributes = [self attributesAtIndex:index
									 longestEffectiveRange:&effectiveRange
												   inRange:plainStringRange];
		
		index += effectiveRange.length;
		
		
		if (effectiveRange.length == 0)
		{
			continue;
		}
		
		NSString *currentSubString = [plainString substringWithRange:effectiveRange];
		
		// Text Color.
		CGColorRef textColor = (__bridge CGColorRef)[attributes objectForKey:(id)kCTForegroundColorAttributeName];
		if (textColor)
		{
			DTColor *color = [DTColor colorWithCGColor:textColor];
			NSString *fontTagWithAttributes = [FontTagName stringByAppendingFormat:@" color=\"#%@\"", [color htmlHexString]];
			
			if ([fontTagWithAttributes isEqualToString:prevFontTagWithAttributes] == NO)
			{
				[openingTags addObject:fontTagWithAttributes];
				
				if (prevFontTagWithAttributes != nil)
				{
					[closingTags addObject:prevFontTagWithAttributes];
				}

				prevFontTagWithAttributes = fontTagWithAttributes;
			}
			else
			{
				// The previous and current font tags are identical => do nothing.
			}
		}
		else
		{
			if (prevFontTagWithAttributes != nil)
			{
				[closingTags addObject:prevFontTagWithAttributes];
				prevFontTagWithAttributes = nil;
			}
		}
		
		// Italic, Bold.
		CTFontRef font = (__bridge CTFontRef)[attributes objectForKey:(id)kCTFontAttributeName];
		DTCoreTextFontDescriptor *fontDesc = nil;
		if (font)
		{
			fontDesc = [DTCoreTextFontDescriptor fontDescriptorForCTFont:font];
		}
		
		if (fontDesc && fontDesc.italicTrait)
		{
			[openingTags addObject:ItalicTagName];
		}
		else
		{
			[closingTags addObject:ItalicTagName];
		}
		
		if (fontDesc && fontDesc.boldTrait)
		{
			[openingTags addObject:BoldTagName];
		}
		else
		{
			[closingTags addObject:BoldTagName];
		}
		
		// Underline.
		NSNumber *underline = [attributes objectForKey:(id)kCTUnderlineStyleAttributeName];
		if (underline)
		{
			[openingTags addObject:UnderlineTagName];
		}
		else
		{
			[closingTags addObject:UnderlineTagName];
		}
		
		// Force order of closing tags to be the reverse of the order in which the tags were opened.
		NSMutableOrderedSet *closingTagsStack = [[openTagsStack reversedOrderedSet] mutableCopy];
		[closingTagsStack intersectOrderedSet:closingTags];
		
		// Only open those tags that are not open already.
		[openingTags minusOrderedSet:openTagsStack];
		
		closeTags(closingTagsStack, taggedString);
		
		// Remove tags that were closed above from the open tags stack. 
		[openTagsStack minusOrderedSet:closingTagsStack];
		
		for (NSString *tag in openingTags)
		{
			[taggedString appendFormat:@"<%@>", tag];
		}
		
		// Add the tags we have just opened to the open tags stack.
		[openTagsStack unionOrderedSet:openingTags];
		
		[taggedString appendString:currentSubString];

		[closingTags removeAllObjects];
		[openingTags removeAllObjects];
	}
	
	closeTags([openTagsStack reversedOrderedSet], taggedString);
	
	return taggedString;
}

@end
