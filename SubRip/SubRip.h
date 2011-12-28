//
//  SubRip.h
//
/*
 This software is licensed under the terms of the BSD license:
 
 Copyright (c) 2011, Sam Stigler
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

typedef enum {
    SubRipScanPositionArrayIndex,
    SubRipScanPositionTimes,
    SubRipScanPositionText
} SubRipScanPosition;

@interface SubRipItem : NSObject < NSCoding > {
    CMTime startTime;
    CMTime endTime;
    NSString *text;
    NSString *uniqueID;
}

@property(assign) CMTime startTime;
@property(assign) CMTime endTime;
@property(copy) NSString *text;

@property(readonly, getter = startTimeString) NSString *startTimeString;
@property(readonly, getter = endTimeString) NSString *endTimeString;
@property(readonly) NSString *uniqueID;

-(NSString *)startTimeString;
-(NSString *)endTimeString;

-(NSString *)_convertCMTimeToString:(CMTime)theTime;

-(NSString *)description;

-(NSInteger)startTimeInSeconds;
-(NSInteger)endTimeInSeconds;

-(BOOL)containsString:(NSString *)str;

-(void)encodeWithCoder:(NSCoder *)encoder;
-(id)initWithCoder:(NSCoder *)decoder;

@end

@interface SubRip : NSObject < NSCoding > {
    NSMutableArray *subtitleItems;
}

@property(strong) NSMutableArray *subtitleItems;
@property(readonly) NSUInteger totalCharacterCountOfText;

-(SubRip *)initWithFile:(NSString *)filePath;
-(SubRip *)initWithData:(NSData *)data;
-(SubRip *)initWithString:(NSString *)str;
-(BOOL)_populateFromString:(NSString *)str;

-(NSString *)description;

-(NSUInteger)indexOfSubRipItemWithStartTime:(CMTime)theTime;

-(NSUInteger)indexOfSubRipItemWithCharacterIndex:(NSUInteger)idx;

-(NSUInteger)totalCharacterCountOfText;

-(void)encodeWithCoder:(NSCoder *)encoder;
-(id)initWithCoder:(NSCoder *)decoder;

@end