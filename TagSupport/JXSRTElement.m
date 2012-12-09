//
//  DTHTMLElement.m
//  JXSRTTagsSupport
//
//  Created by Jan Weiß on 2012-12-02.
//  Based on DTCoreText, Copyright 2011 Drobnik.com
//  Copyright 2012 geheimwerk.de. All rights reserved.
//
//  This software is licensed under the terms of the BSD license.
//

#import "JXSRTTagsSupport.h"
#import "JXSRTElement.h"

@interface JXSRTElement ()

@property (nonatomic, strong) NSMutableDictionary *fontCache;
@property (nonatomic, strong) NSMutableArray *children;

@end


@implementation JXSRTElement
{
	JXSRTElement *_parent;
	
	DTCoreTextFontDescriptor *_fontDescriptor;
	DTCoreTextParagraphStyle *_paragraphStyle;
	
	DTColor *_textColor;
	
	CTUnderlineStyle _underlineStyle;
	
	NSString *_tagName;
	NSString *_text;
	
	NSMutableDictionary *_fontCache;
	
	NSMutableDictionary *_additionalAttributes;
	
	BOOL _isColorInherited;
	
	BOOL _preserveNewlines;
	
	CGFloat _textScale;
	CGSize _size;
	
	NSMutableArray *_children;
	NSDictionary *_attributes; // contains all attributes from parsing
}

- (id)init
{
	self = [super init];
	if (self)
	{
	}
	
	return self;
}

- (NSDictionary *)attributesDictionary
{
	NSMutableDictionary *tmpDict = [NSMutableDictionary dictionary];
	
	BOOL shouldAddFont = YES;
	
	// copy additional attributes
	if (_additionalAttributes)
	{
		[tmpDict setDictionary:_additionalAttributes];
	}
	
	// otherwise we have a font
	if (shouldAddFont)
	{
		// try font cache first
		NSNumber *key = [NSNumber numberWithUnsignedInteger:[_fontDescriptor hash]];
		CTFontRef font = (__bridge CTFontRef)[self.fontCache objectForKey:key];
		
		if (!font)
		{
			font = [_fontDescriptor newMatchingFont];
			
			if (font)
			{
				[self.fontCache setObject:CFBridgingRelease(font) forKey:key];
			}
		}
		
		if (font)
		{
			// __bridge since its already retained elsewhere
			[tmpDict setObject:(__bridge id)(font) forKey:(id)kCTFontAttributeName];
		}
	}
	
	// set underline style
	if (_underlineStyle)
	{
		[tmpDict setObject:[NSNumber numberWithInteger:_underlineStyle] forKey:(id)kCTUnderlineStyleAttributeName];
		
		// we could set an underline color as well if we wanted, but not supported by HTML
		//	  [attributes setObject:(id)[DTColor redColor].CGColor forKey:(id)kCTUnderlineColorAttributeName];
	}
	
	if (_textColor)
	{
		[tmpDict setObject:(id)[_textColor CGColor] forKey:(id)kCTForegroundColorAttributeName];
	}
	
	return tmpDict;
}

- (NSAttributedString *)attributedString
{
	NSDictionary *attributes = [self attributesDictionary];
	
	{
		{
			return [[NSAttributedString alloc] initWithString:_text attributes:attributes];
		}
	}
}

- (void)addChild:(JXSRTElement *)child
{
	child.parent = self;
	[self.children addObject:child];
}

- (void)removeChild:(JXSRTElement *)child
{
	child.parent = nil;
	[self.children removeObject:child];
}

- (JXSRTElement *)parentWithTagName:(NSString *)name
{
	if ([self.parent.tagName isEqualToString:name])
	{
		return self.parent;
	}
	
	return [self.parent parentWithTagName:name];
}

- (BOOL)isContainedInBlockElement
{
	if (!_parent || !_parent.tagName) // default tag has no tag name
	{
		return NO;
	}
	
	{
		return [self.parent isContainedInBlockElement];
	}
	
	return YES;
}

- (NSString *)attributeForKey:(NSString *)key
{
	return [_attributes objectForKey:key];
}

#pragma mark Calulcating Properties

- (id)valueForKeyPathWithInheritance:(NSString *)keyPath
{
	id value = [self valueForKeyPath:keyPath];
	
	// if property is not set we also go to parent
	if (!value && _parent)
	{
		return [_parent valueForKeyPathWithInheritance:keyPath];
	}
	
	// enum properties have 0 for inherit
	if ([value isKindOfClass:[NSNumber class]])
	{
		NSNumber *number = value;
		
		if (([number integerValue]==0) && _parent)
		{
			return [_parent valueForKeyPathWithInheritance:keyPath];
		}
	}
	
	// string properties have 'inherit' for inheriting
	if ([value isKindOfClass:[NSString class]])
	{
		NSString *string = value;
		
		if ([string isEqualToString:@"inherit"] && _parent)
		{
			return [_parent valueForKeyPathWithInheritance:keyPath];
		}
	}
	
	// obviously not inherited
	return value;
}


#pragma mark Copying

- (id)copyWithZone:(NSZone *)zone
{
	JXSRTElement *newObject = [[JXSRTElement allocWithZone:zone] init];
	
	newObject.fontDescriptor = self.fontDescriptor; // copy
	newObject.paragraphStyle = self.paragraphStyle; // copy
	
	newObject.underlineStyle = self.underlineStyle;
	newObject.tagContentInvisible = self.tagContentInvisible;
	newObject.textColor = self.textColor;
	newObject.isColorInherited = YES;
	
	newObject.fontCache = self.fontCache; // reference
	
	return newObject;
}

#pragma mark Properties

- (NSMutableDictionary *)fontCache
{
	if (!_fontCache)
	{
		_fontCache = [[NSMutableDictionary alloc] init];
	}
	
	return _fontCache;
}

- (void)setTextColor:(DTColor *)textColor
{
	if (_textColor != textColor)
	{
		_textColor = textColor;
		_isColorInherited = NO;
	}
}

- (NSString *)path
{
	if (_parent)
	{
		return [[_parent path] stringByAppendingFormat:@"/%@", self.tagName];
	}
	
	if (_tagName)
	{
		return _tagName;
	}
	
	return @"root";
}

- (NSMutableArray *)children
{
	if (!_children)
	{
		_children = [[NSMutableArray alloc] init];
	}
	
	return _children;
}

- (void)setAttributes:(NSDictionary *)attributes
{
	if (_attributes != attributes)
	{
		_attributes = attributes;
		
		// decode size contained in attributes, might be overridden later by CSS size
		_size = CGSizeMake([[self attributeForKey:@"width"] floatValue], [[self attributeForKey:@"height"] floatValue]); 
	}
}

@synthesize parent = _parent;
@synthesize fontDescriptor = _fontDescriptor;
@synthesize paragraphStyle = _paragraphStyle;
@synthesize textColor = _textColor;
@synthesize tagName = _tagName;
@synthesize text = _text;
@synthesize underlineStyle = _underlineStyle;
@synthesize isColorInherited = _isColorInherited;
@synthesize textScale = _textScale;
@synthesize size = _size;

@synthesize fontCache = _fontCache;
@synthesize children = _children;
@synthesize attributes = _attributes;

@end


