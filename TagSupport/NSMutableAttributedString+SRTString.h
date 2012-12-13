//
//  NSMutableAttributedString+SRTString.h
//  JXSRTTagsSupport
//
//  Created by Jan Weiß on 2012-12-02.
//  Based on DTCoreText, Copyright 2011 Drobnik.com
//  Copyright 2012 geheimwerk.de. All rights reserved.
//
//  This software is licensed under the terms of the BSD license.
//

@class NSMutableAttributedString;

@interface NSMutableAttributedString (SRTString)

/**
 @name Creating an NSMutableAttributedString
 */

/**
 Initializes and returns a new `NSMutableAttributedString` object from the tagged SRT string contained in the given object.
 @param string The HTML string from which to create the attributed string.
 @param options Specifies how the document should be loaded. Contains values described in “Option keys for parsing SRT strings.”
 @returns Returns an initialized object, or `nil` if the data can’t be decoded.
 */
- (id)initWithSRTString:(NSString *)string options:(NSDictionary *)options;

/**
 Creates and returns an NSMutableAttributedString object initialized using the provided string
 @param options Specifies how the document should be loaded. Contains values described in “Option keys for parsing SRT strings.”
 @returns Returns an initialized object, or `nil` if the data can’t be decoded.
 */
+ (NSMutableAttributedString *)attributedStringWithSRTString:(NSString *)string options:(NSDictionary *)options;

@end


@interface NSAttributedString (SRTString)

/**
 Encodes the receiver into a tagged SRT string.
 
 @returns An SRT string.
 */
- (NSString *)srtString;

@end
