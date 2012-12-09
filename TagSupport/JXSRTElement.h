//
//  DTHTMLElement.h
//  JXSRTTagsSupport
//
//  Created by Jan Weiß on 2012-12-02.
//  Based on DTCoreText, Copyright 2011 Drobnik.com
//  Copyright 2012 geheimwerk.de. All rights reserved.
//
//  This software is licensed under the terms of the BSD license.
//

@class DTCoreTextParagraphStyle;
@class DTCoreTextFontDescriptor;
@class DTTextAttachment;
@class DTColor;

@interface JXSRTElement : NSObject <NSCopying>

@property (nonatomic, strong) JXSRTElement *parent;
@property (nonatomic, copy) DTCoreTextFontDescriptor *fontDescriptor;
@property (nonatomic, copy) DTCoreTextParagraphStyle *paragraphStyle;
@property (nonatomic, strong) DTTextAttachment *textAttachment;
@property (nonatomic, strong) DTColor *textColor;
@property (nonatomic, copy) NSString *tagName;
@property (nonatomic, copy) NSString *text;
@property (nonatomic, assign) CTUnderlineStyle underlineStyle;
@property (nonatomic, assign) BOOL tagContentInvisible;
@property (nonatomic, assign) BOOL isColorInherited;
@property (nonatomic, assign) CGFloat textScale;
@property (nonatomic, assign) CGSize size;
@property (nonatomic, strong) NSDictionary *attributes;

- (NSAttributedString *)attributedString;
- (NSDictionary *)attributesDictionary;

- (NSString *)path;

- (NSString *)attributeForKey:(NSString *)key;

- (void)addChild:(JXSRTElement *)child;
- (void)removeChild:(JXSRTElement *)child;

- (JXSRTElement *)parentWithTagName:(NSString *)name;
- (BOOL)isContainedInBlockElement;

@end
