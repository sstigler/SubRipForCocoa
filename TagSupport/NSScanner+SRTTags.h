//
//  NSScanner+SRTTags.h
//  JXSRTTagsSupport
//
//  Created by Jan Weiß on 2012-12-02.
//  Based on DTCoreText, Copyright 2011 Drobnik.com
//  Copyright 2012 geheimwerk.de. All rights reserved.
//
//  This software is licensed under the terms of the BSD license.
//


extern NSString * const ItalicTagName;
extern NSString * const BoldTagName;
extern NSString * const UnderlineTagName;
extern NSString * const FontTagName;


@interface NSScanner (SRTTags)

- (BOOL)scanSRTTag:(NSString **)tagName attributes:(NSDictionary **)attributes isOpen:(BOOL *)isOpen isClosed:(BOOL *)isClosed;

- (void)srtLogPosition;

@end

