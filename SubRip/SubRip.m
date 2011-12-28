//
//  SubRip.m
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

#import "SubRip.h"

@implementation SubRip

@dynamic totalCharacterCountOfText;
@synthesize subtitleItems;

-(SubRip *)initWithFile:(NSString *)filePath {
    if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        NSString *srt = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:NULL];
        self = [super init];
        if (self) {
            self.subtitleItems = [NSMutableArray arrayWithCapacity:100];
            BOOL success = [self _populateFromString:srt];
            if (!success) {
                return nil;
            }
        }
        return self;
    } else {
        return nil;
    }
}

-(SubRip *)initWithData:(NSData *)data {
    self = [super init];
    if (self) {
        NSString *str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        self.subtitleItems = [NSMutableArray arrayWithCapacity:100];
        BOOL success = [self _populateFromString:str];
        if (!success) {
            return nil;
        }
    }
    return self;
}

-(SubRip *)initWithString:(NSString *)str {
    self = [super init];
    if (self) {
        self.subtitleItems = [NSMutableArray arrayWithCapacity:100];
        BOOL success = [self _populateFromString:str];
        if (!success) {
            return nil;
        }
    }
    return self;
}
  
// returns YES if successful, NO if not succesful.
// assumes that str is a correctly-formatted SRT file.
-(BOOL)_populateFromString:(NSString *)str {
    SubRipItem __block *cur = [SubRipItem new];
    SubRipScanPosition __block scanPosition = SubRipScanPositionArrayIndex;
    [str enumerateLinesUsingBlock:^(NSString *line, BOOL *stop) {
        // skip over blank lines.
        NSRange r = [line rangeOfCharacterFromSet:[NSCharacterSet alphanumericCharacterSet]];
        if (r.location != NSNotFound) {
            BOOL actionAlreadyTaken = NO;
            if (scanPosition == SubRipScanPositionArrayIndex) {
                scanPosition = SubRipScanPositionTimes; // skip past the array index number.
                actionAlreadyTaken = YES;
            }
            if ((scanPosition == SubRipScanPositionTimes) && (!actionAlreadyTaken)) {
                NSArray *times = [line componentsSeparatedByString:@" --> "];
                NSString *beginning = [times objectAtIndex:0];
                NSString *ending = [times objectAtIndex:1];
                
                // working with the beginning first...
                NSArray *timeComponents = [beginning componentsSeparatedByString:@":"];
                NSInteger hours = [(NSString *)[timeComponents objectAtIndex:0] integerValue];
                NSInteger minutes = [(NSString *)[timeComponents objectAtIndex:1] integerValue];
                NSArray *secondsComponents = [(NSString *)[timeComponents objectAtIndex:2] componentsSeparatedByString:@","];
                NSInteger seconds = [(NSString *)[secondsComponents objectAtIndex:0] integerValue];
                NSInteger milliseconds = [(NSString *)[secondsComponents objectAtIndex:1] integerValue];
                NSInteger totalNumSeconds = (hours * 3600) + (minutes * 60) + seconds;
                CMTime startSeconds = CMTimeMake(totalNumSeconds, 1);
                CMTime millisecondsCMTime = CMTimeMake(milliseconds, 1000);
                cur.startTime = CMTimeAdd(startSeconds, millisecondsCMTime);
                
                // and then the end:
                timeComponents = [ending componentsSeparatedByString:@":"];
                hours = [(NSString *)[timeComponents objectAtIndex:0] integerValue];
                minutes = [(NSString *)[timeComponents objectAtIndex:1] integerValue];
                secondsComponents = [(NSString *)[timeComponents objectAtIndex:2] componentsSeparatedByString:@","];
                seconds = [(NSString *)[secondsComponents objectAtIndex:0] integerValue];
                milliseconds = [(NSString *)[secondsComponents objectAtIndex:1] integerValue];
                totalNumSeconds = (hours * 3600) + (minutes * 60) + seconds;
                CMTime endSeconds = CMTimeMake(totalNumSeconds, 1);
                millisecondsCMTime = CMTimeMake(milliseconds, 1000);
                cur.endTime = CMTimeAdd(endSeconds, millisecondsCMTime);
                scanPosition = SubRipScanPositionText;
                actionAlreadyTaken = YES;
            }
            if ((scanPosition == SubRipScanPositionText) && (!actionAlreadyTaken)) {
                cur.text = line;
                [subtitleItems addObject:cur];
                cur = [SubRipItem new];
                scanPosition = SubRipScanPositionArrayIndex;
            }
        }
    }];
    return YES;
}

-(NSString *)description {
    return [NSString stringWithFormat:@"SRT file: %@", self.subtitleItems];
}

-(NSUInteger)indexOfSubRipItemWithStartTime:(CMTime)theTime {
    NSInteger __block desiredTimeInSeconds = theTime.value / theTime.timescale;
    return [self.subtitleItems indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
        if ((desiredTimeInSeconds >= [(SubRipItem *)obj startTimeInSeconds]) && (desiredTimeInSeconds <= [(SubRipItem *)obj endTimeInSeconds])) {
            return true;
        } else {
            return false;
        }
    }];
}

-(NSUInteger)indexOfSubRipItemWithCharacterIndex:(NSUInteger)idx {
    if (idx >= self.totalCharacterCountOfText) {
        return NSNotFound;
    }
    NSUInteger currentCharacterCount = 0;
    NSUInteger currentItemIndex = 0;
    SubRipItem *cur = [self.subtitleItems objectAtIndex:currentItemIndex];
    while (currentCharacterCount < idx) {
        currentCharacterCount += cur.text.length;
        currentItemIndex++;
    }
    return currentItemIndex;
}

-(NSUInteger)totalCharacterCountOfText {
    NSUInteger totalLength = 0;
    for (SubRipItem *cur in self.subtitleItems) {
        totalLength += cur.text.length;
    }
    return totalLength;
}

-(void)encodeWithCoder:(NSCoder *)encoder {
    [encoder encodeObject:subtitleItems forKey:@"subtitleItems"];
}

-(id)initWithCoder:(NSCoder *)decoder {
    self = [self init];
    self.subtitleItems = [decoder decodeObjectForKey:@"subtitleItems"];
    return self;
}

@end

@implementation SubRipItem

@synthesize startTime, endTime, text, uniqueID;
@dynamic startTimeString, endTimeString;

- (id)init {
    self = [super init];
    if (self) {
        uniqueID = [[NSProcessInfo processInfo] globallyUniqueString];
    }
    return self;
}

-(NSString *)startTimeString {
    return [self _convertCMTimeToString:self.startTime];
}

-(NSString *)endTimeString {
    return [self _convertCMTimeToString:self.endTime];
}

-(NSString *)_convertCMTimeToString:(CMTime)theTime {
    // Need a string of format "hh:mm:ss". (No milliseconds.)
    NSInteger seconds = theTime.value / theTime.timescale;
    NSDate *date1 = [NSDate new];
    NSDate *date2 = [NSDate dateWithTimeInterval:seconds sinceDate:date1];
    unsigned int unitFlags = NSHourCalendarUnit | NSMinuteCalendarUnit | NSSecondCalendarUnit;
    NSDateComponents *converted = [[NSCalendar currentCalendar] components:unitFlags fromDate:date1 toDate:date2 options:0];
    
    NSMutableString *str = [NSMutableString stringWithCapacity:6];
    if ([converted hour] < 10) {
        [str appendString:@"0"];
    }
    [str appendFormat:@"%ld:", [converted hour]];
    if ([converted minute] < 10) {
        [str appendString:@"0"];
    }
    [str appendFormat:@"%ld:", [converted minute]];
    if ([converted second] < 10) {
        [str appendString:@"0"];
    }
    [str appendFormat:@"%ld", [converted second]];
    return str;
}

-(NSString *)description {
    return [NSString stringWithFormat:@"%@ ---> %@\n%@", self.startTimeString, self.endTimeString, self.text];
}
            
-(NSInteger)startTimeInSeconds {
    return self.startTime.value / self.startTime.timescale;
}

-(NSInteger)endTimeInSeconds {
    return self.endTime.value / self.endTime.timescale;
}

-(BOOL)containsString:(NSString *)str {
    NSRange searchResult = [self.text rangeOfString:str options:NSCaseInsensitiveSearch];
    if (searchResult.location == NSNotFound) {
        if ([str length] < 9) {
            searchResult = [[self startTimeString] rangeOfString:str options:NSCaseInsensitiveSearch];
            if (searchResult.location == NSNotFound) {
                searchResult = [[self endTimeString] rangeOfString:str options:NSCaseInsensitiveSearch];
                if (searchResult.location == NSNotFound) {
                    return false;
                } else {
                    return true;
                }
            } else {
                return true;
            }
        } else {
            return false;
        }
    } else {
        return true;
    }
}

-(void)encodeWithCoder:(NSCoder *)encoder {
    [encoder encodeCMTime:startTime forKey:@"startTime"];
    [encoder encodeCMTime:endTime forKey:@"endTime"];
    [encoder encodeObject:text forKey:@"text"];
}

-(id)initWithCoder:(NSCoder *)decoder {
    self = [self init];
    self.startTime = [decoder decodeCMTimeForKey:@"startTime"];
    self.endTime = [decoder decodeCMTimeForKey:@"endTime"];
    self.text = [decoder decodeObjectForKey:@"text"];
    return self;
}
            
@end