//
//  SubRip.h
//
/*
 This software is licensed under the terms of the BSD license:
 
 Copyright (c) 2011, Sam Stigler
 Copyright (c) 2012, Jan Weiß
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/
// encapsulates and parses the .srt subtitle file format. 

#import <Foundation/Foundation.h>
#import <CoreMedia/CMTime.h>
#import <AVFoundation/AVTime.h>

#import "JXArcCompatibilityMacros.h"

@interface SubRipItem : NSObject < NSCoding > {
    NSString *_uniqueID;
    NSDictionary *_attributeOptions;
}

@property(assign) CMTime startTime;
@property(assign) CMTime endTime;
@property(copy) NSString *text;
@property(nonatomic, copy) NSAttributedString *attributedText;
@property(nonatomic, readonly, JX_STRONG) NSDictionary *attributeOptions;

@property(readonly, getter = startTimeString) NSString *startTimeString;
@property(readonly, getter = endTimeString) NSString *endTimeString;
@property(readonly) NSString *uniqueID;

@property (nonatomic, assign) CGRect frame;

- (instancetype)initWithText:(NSString *)text
                   startTime:(CMTime)startTime
                     endTime:(CMTime)endTime;

- (void)parseTagsWithOptions:(NSDictionary *)options;

// Without milliseconds!
-(NSString *)startTimeString;
-(NSString *)endTimeString;

// SRT timecode strings
-(NSString *)startTimecodeString;
-(NSString *)endTimecodeString;

-(NSString *)_convertCMTimeToString:(CMTime)theTime;

-(NSString *)positionString;

-(NSString *)description;

-(NSInteger)startTimeInSeconds;
-(NSInteger)endTimeInSeconds;

// These methods are for development only due to the issues involving floating-point arithmetic.
-(double)startTimeDouble;
-(double)endTimeDouble;

-(void)setStartTimeFromString:(NSString *)timecodeString;
-(void)setEndTimeFromString:(NSString *)timecodeString;

-(BOOL)containsString:(NSString *)str;

-(void)encodeWithCoder:(NSCoder *)encoder;
-(instancetype)initWithCoder:(NSCoder *)decoder;

-(NSDictionary *)dictionaryRepresentation; // returns a subtitle dictionary suitable for use with AV Foundation.

@end

@interface SubRip : NSObject < NSCoding > {
    NSMutableArray *_subtitleItems;
}

@property(JX_STRONG) NSMutableArray *subtitleItems;
@property(readonly) NSUInteger totalCharacterCountOfText;

-(instancetype)initWithFile:(NSString *)filePath;
-(instancetype)initWithURL:(NSURL *)fileURL encoding:(NSStringEncoding)encoding error:(NSError **)error;
-(instancetype)initWithData:(NSData *)data;
-(instancetype)initWithData:(NSData *)data encoding:(NSStringEncoding)encoding;
-(instancetype)initWithData:(NSData *)data encoding:(NSStringEncoding)encoding error:(NSError **)error;
-(instancetype)initWithString:(NSString *)str;
-(instancetype)initWithString:(NSString *)str
                        error:(NSError **)error;
-(instancetype)initWithSubtitleItems:(NSMutableArray *)subtitleItems;

-(BOOL)_populateFromString:(NSString *)str;

- (void)parseTags;
- (void)parseTagsWithOptions:(NSDictionary *)options;

-(NSString *)srtString;
-(NSString *)srtStringWithLineBreaksInSubtitlesAllowed:(BOOL)lineBreaksAllowed;

-(NSString *)description;

-(NSUInteger)indexOfSubRipItemWithStartTime:(CMTime)desiredTime DEPRECATED_ATTRIBUTE; // The name of this method doesn’t match what it does.
-(NSUInteger)indexOfSubRipItemForPointInTime:(CMTime)desiredTime;

- (SubRipItem *)subRipItemAtIndex:(NSUInteger)index; // In contrast to NSArray’s -objectAtIndex:, this returns nil if the index it out of bounds.
- (SubRipItem *)subRipItemForPointInTime:(CMTime)desiredTime index:(NSUInteger *)index; // The index is optional: you can pass NULL.
- (SubRipItem *)nextSubRipItemForPointInTime:(CMTime)desiredTime index:(NSUInteger *)index; // The index is optional: you can pass NULL.

-(NSUInteger)indexOfSubRipItemWithCharacterIndex:(NSUInteger)idx;

-(NSUInteger)totalCharacterCountOfText;

-(void)encodeWithCoder:(NSCoder *)encoder;
-(instancetype)initWithCoder:(NSCoder *)decoder;

@end

extern const int kJXCouldNotParseSRT;
