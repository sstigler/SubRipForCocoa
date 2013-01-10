//
//  SubRip.m
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

#import "SubRip.h"

#if SUBRIP_TAG_SUPPORT
#import <SubRip/NSMutableAttributedString+SRTString.h>
#endif

@implementation SubRip

@dynamic totalCharacterCountOfText;
@synthesize subtitleItems = _subtitleItems;

-(instancetype)initWithFile:(NSString *)filePath {
    if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        NSData *data = [NSData dataWithContentsOfFile:filePath];
        return [self initWithData:data encoding:NSUTF8StringEncoding];
    } else {
        return nil;
    }
}

-(instancetype)initWithURL:(NSURL *)fileURL encoding:(NSStringEncoding)encoding error:(NSError **)error {
    if ([fileURL checkResourceIsReachableAndReturnError:error] == YES) {
        NSData *data = [NSData dataWithContentsOfURL:fileURL
                                             options:NSDataReadingMappedIfSafe
                                               error:error];
        return [self initWithData:data encoding:encoding];
    } else {
        return nil;
    }
}

-(instancetype)initWithData:(NSData *)data {
    return [self initWithData:data encoding:NSUTF8StringEncoding];
}

-(instancetype)initWithData:(NSData *)data encoding:(NSStringEncoding)encoding {
    NSString *str = JX_AUTORELEASE([[NSString alloc] initWithData:data encoding:encoding]);
    return [self initWithString:str];
}

-(instancetype)initWithString:(NSString *)str {
    self = [super init];
    
    if (self) {
        self.subtitleItems = [NSMutableArray arrayWithCapacity:100];
        BOOL success = [self _populateFromString:str];
        if (!success) {
            JX_RELEASE(self);
            return nil;
        }
    }
    
    return self;
}
  
-(instancetype)initWithSubtitleItems:(NSMutableArray *)subtitleItems {
    self = [super init];
    
    if (self) {
        self.subtitleItems = subtitleItems;
    }
    
    return self;
}

#if (JX_HAS_ARC == 0)
- (void)dealloc
{
    self.subtitleItems = nil;
    
    [super dealloc];
}
#endif


typedef struct _SubRipTime {
    int hours;
    int minutes;
    int seconds;
    int milliseconds;
} SubRipTime;

NS_INLINE int totalSecondsForHoursMinutesSeconds(int hours, int minutes, int seconds) {
    return (hours * 3600) + (minutes * 60) + seconds;
}

+ (void)parseTimecodeString:(NSString *)timecodeString intoSeconds:(int *)totalNumSeconds milliseconds:(int *)milliseconds {
    NSArray *timeComponents = [timecodeString componentsSeparatedByString:@":"];
    
    int hours = [(NSString *)[timeComponents objectAtIndex:0] intValue];
    int minutes = [(NSString *)[timeComponents objectAtIndex:1] intValue];
    
    NSArray *secondsComponents = [(NSString *)[timeComponents objectAtIndex:2] componentsSeparatedByString:@","];
#if SUBRIP_SUBVIEWER_SUPPORT
    if (secondsComponents.count < 2)  secondsComponents = [(NSString *)[timeComponents objectAtIndex:2] componentsSeparatedByString:@"."];
#endif
    int seconds = [(NSString *)[secondsComponents objectAtIndex:0] intValue];
    
    *milliseconds = [(NSString *)[secondsComponents objectAtIndex:1] intValue];
    *totalNumSeconds = totalSecondsForHoursMinutesSeconds(hours, minutes, seconds);
}

NS_INLINE CMTime convertSecondsMillisecondsToCMTime(int seconds, int milliseconds) {
    CMTime secondsTime = CMTimeMake(seconds, 1);
    CMTime millisecondsTime = CMTimeMake(milliseconds, 1000);
    CMTime time = CMTimeAdd(secondsTime, millisecondsTime);
    return time;
}

+ (CMTime)parseTimecodeStringIntoCMTime:(NSString *)timecodeString {
    int milliseconds;
    int totalNumSeconds;
    
    [SubRip parseTimecodeString:timecodeString
                    intoSeconds:&totalNumSeconds
                   milliseconds:&milliseconds];
    
    CMTime time = convertSecondsMillisecondsToCMTime(totalNumSeconds, milliseconds);
    
    return time;
}

NS_INLINE CMTime convertSubRipTimeToCMTime(SubRipTime subRipTime) {
    int totalSeconds = totalSecondsForHoursMinutesSeconds(subRipTime.hours, subRipTime.minutes, subRipTime.seconds);
    CMTime time = convertSecondsMillisecondsToCMTime(totalSeconds, subRipTime.milliseconds);
    return time;
}


-(BOOL)_populateFromString:(NSString *)str {
    return [self _populateFromString:str error:NULL];
}

NS_INLINE BOOL scanLinebreak(NSScanner *scanner, NSString *linebreakString, int linenr) {
    BOOL success = ([scanner scanString:linebreakString intoString:NULL] && (++linenr >= 0));
    return success;
}

NS_INLINE BOOL scanString(NSScanner *scanner, NSString *str) {
    BOOL success = [scanner scanString:str intoString:NULL];
    return success;
}

// returns YES if successful, NO if not succesful.
// assumes that str is a correctly-formatted SRT file.
-(BOOL)_populateFromString:(NSString *)str
                     error:(NSError **)error {
#if 1
    // Basis for implementation donated by Peter Ljunglöf (SubTTS)
#   define SCAN_LINEBREAK() scanLinebreak(scanner, linebreakString, lineNr)
#   define SCAN_STRING(str) scanString(scanner, (str))

    NSScanner *scanner = [NSScanner scannerWithString:str];
    [scanner setCharactersToBeSkipped:[NSCharacterSet whitespaceCharacterSet]];
    
    // Auto-detect linebreakString
    NSString *linebreakString = nil;
    {
        NSCharacterSet *newlineCharacterSet = [NSCharacterSet newlineCharacterSet];
        BOOL ok = ([scanner scanUpToCharactersFromSet:newlineCharacterSet intoString:NULL] &&
                   [scanner scanCharactersFromSet:newlineCharacterSet intoString:&linebreakString]);
        if (ok == NO) {
            NSLog(@"Parse error in SRT string: no line break found!");
            linebreakString = @"\n";
        }
        [scanner setScanLocation:0];
    }
    
    NSString *subTextLineSeparator = @"\n";
    int subtitleNr = 0;
    int lineNr = 1;
    
    while (SCAN_LINEBREAK()); // Skip empty lines.
   
    while (![scanner isAtEnd]) {
        NSString *subText;
        NSMutableArray *subTextLines;
        NSString *subTextLine;
        SubRipTime start, end;
        int subtitleNr_;

        subtitleNr++;
        
        BOOL ok = ([scanner scanInt:&subtitleNr_] && SCAN_LINEBREAK() &&
                   [scanner scanInt:&start.hours] && SCAN_STRING(@":") &&
                   [scanner scanInt:&start.minutes] && SCAN_STRING(@":") &&
                   [scanner scanInt:&start.seconds] &&
#if SUBRIP_SUBVIEWER_SUPPORT
                   (SCAN_STRING(@",") || SCAN_STRING(@".")) &&
#else
                   SCAN_STRING(@",") &&
#endif
                   [scanner scanInt:&start.milliseconds] &&
                   
                   SCAN_STRING(@"-->") &&
                   
                   [scanner scanInt:&end.hours] && SCAN_STRING(@":") &&
                   [scanner scanInt:&end.minutes] && SCAN_STRING(@":") &&
                   [scanner scanInt:&end.seconds] &&
#if SUBRIP_SUBVIEWER_SUPPORT
                   (SCAN_STRING(@",") || SCAN_STRING(@".")) &&
#else
                   SCAN_STRING(@",") &&
#endif
                   [scanner scanInt:&end.milliseconds] &&
                   (
                    SCAN_LINEBREAK() || ([scanner scanUpToString:linebreakString intoString:NULL] && SCAN_LINEBREAK() /* Scan past position for now. */)
                   ) &&
                   [scanner scanUpToString:linebreakString intoString:&subTextLine] && (SCAN_LINEBREAK() || [scanner isAtEnd])
                   );
        
        if (!ok) {
#if 0
            NSUInteger contextLength = 20;
            NSString *beforeError = [str substringToIndex:[scanner scanLocation]];
            if ([beforeError length] > contextLength)
                beforeError = [beforeError substringFromIndex: [beforeError length]-contextLength];
            NSString *afterError = [str substringFromIndex: [scanner scanLocation]];
            if ([afterError length] > contextLength)
                afterError = [afterError substringToIndex: contextLength];
            WARN(@"Parse error in subtitle #%d (line %d):\n%@<HERE>%@",
                 subtitleNr, lineNr, beforeError, afterError);
#endif
            if (error != NULL) {
				*error = [[NSError alloc] initWithDomain:NSCocoaErrorDomain
                                                    code:NSFileReadCorruptFileError
                                                userInfo:nil];
			}
            
            return NO;
        }
        if (subtitleNr != subtitleNr_) {
            //WARN(@"Subtitle nr mismatch (line %d): got %d, expected %d", lineNr, subtitleNr_, subtitleNr);
            subtitleNr = subtitleNr_;
        }
        
        subTextLines = [NSMutableArray arrayWithObject:subTextLine];
        while ([scanner scanUpToString:linebreakString intoString:&subTextLine] && (SCAN_LINEBREAK() || [scanner isAtEnd])) {
            [subTextLines addObject:subTextLine];
        }
        subText = [subTextLines componentsJoinedByString:subTextLineSeparator];
        
        CMTime startTime = convertSubRipTimeToCMTime(start);
        CMTime endTime = convertSubRipTimeToCMTime(end);

        SubRipItem *item = [[SubRipItem alloc] initWithText:subText startTime:startTime endTime:endTime];
        [_subtitleItems addObject:item];
        
        while (SCAN_LINEBREAK());
    }
    
#if DEBUG
    NSLog(@"Read %d = %lu subtitles", subtitleNr, [_subtitleItems count]);
    SubRipItem* sub = [_subtitleItems objectAtIndex:0];
    NSLog(@"FIRST: '%@'", sub);
    sub = [_subtitleItems lastObject];
    NSLog(@"LAST: '%@'", sub);
#endif
    
    return YES;

#   undef SCAN_LINEBREAK
#   undef SCAN_STRING
#else
    NSCharacterSet *alphanumericCharacterSet = [NSCharacterSet alphanumericCharacterSet];
    
    __block SubRipItem *cur = [SubRipItem new];
    __block SubRipScanPosition scanPosition = SubRipScanPositionArrayIndex;
    [str enumerateLinesUsingBlock:^(NSString *line, BOOL *stop) {
        // Blank lines are delimiters.
        NSRange r = [line rangeOfCharacterFromSet:alphanumericCharacterSet];
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
                
                cur.startTime = [SubRip parseTimecodeStringIntoCMTime:beginning];
                cur.endTime = [SubRip parseTimecodeStringIntoCMTime:ending];
                
                scanPosition = SubRipScanPositionText;
                actionAlreadyTaken = YES;
            }
            
            if ((scanPosition == SubRipScanPositionText) && (!actionAlreadyTaken)) {
                NSString *prevText = cur.text;
                if (prevText == nil) {
                    cur.text = line;
                } else {
                    cur.text = [cur.text stringByAppendingFormat:@"\n%@", line];
                }
                scanPosition = SubRipScanPositionText;
            }
        }
        else {
#if SUBRIP_SUBVIEWER_SUPPORT
            NSString *currentText = cur.text;
            NSRange currentTextRange = NSMakeRange(0, currentText.length);
            NSString *subViewerLineBreak = @"[br]";
            NSRange subViewerLineBreakRange = [currentText rangeOfString:subViewerLineBreak
                                                                 options:NSLiteralSearch
                                                                   range:currentTextRange];
            
            if (subViewerLineBreakRange.location != NSNotFound) {
                NSRange subViewerLineBreakSearchRange = NSMakeRange(subViewerLineBreakRange.location,
                                                                    (currentTextRange.length - subViewerLineBreakRange.location));
                
                cur.text = [currentText stringByReplacingOccurrencesOfString:subViewerLineBreak
                                                                  withString:@"\n"
                                                                     options:NSLiteralSearch
                                                                       range:subViewerLineBreakSearchRange];
            }
#endif
            
            [_subtitleItems addObject:cur];
            JX_RELEASE(cur);
            cur = [SubRipItem new];
            scanPosition = SubRipScanPositionArrayIndex;
        }
    }];
    
    switch (scanPosition) {
        case SubRipScanPositionArrayIndex:
            JX_RELEASE(cur);
            break;
            
        case SubRipScanPositionText:
            [_subtitleItems addObject:cur];
            JX_RELEASE(cur);
            break;
            
        default:
            break;
    }
    
    return YES;
#endif
}

- (void)parseTags;
{
    [self parseTagsWithOptions:nil];
}

- (void)parseTagsWithOptions:(NSDictionary *)options;
{
#if SUBRIP_TAG_SUPPORT
    for (SubRipItem *item in _subtitleItems) {
        [item parseTagsWithOptions:options];
    }
#endif
}


NSString * srtTimecodeStringForCMTime(CMTime time) {
    double seconds = CMTimeGetSeconds(time);
    double seconds_floor = floor(seconds);
    long long seconds_floor_int = (long long)seconds_floor;
    return [NSString stringWithFormat:@"%02d:%02d:%02d,%03d",
            (int)floor(seconds / 60 / 60),                        // H
            (int)floor(seconds / 60),                            // M
            (int)floor(seconds_floor_int % 60),                    // S
            (int)round((seconds - seconds_floor) * 1000.0f)];    // cs

}

NS_INLINE NSString * subRipItem2SRTBlock(SubRipItem *item, BOOL lineBreaksAllowed) {
    NSString *srtText = item.text;
    if (lineBreaksAllowed == NO) {
        srtText = [srtText stringByReplacingOccurrencesOfString:@"\n"
                                                     withString:@"|"];
    }
    
    NSString *srtBlock = [NSString stringWithFormat:@"%@ --> %@\n%@",
            srtTimecodeStringForCMTime(item.startTime),
            srtTimecodeStringForCMTime(item.endTime), srtText];
    
    return srtBlock;
}

-(NSString *)srtString {
    return [self srtStringWithLineBreaksInSubtitlesAllowed:YES];
}

-(NSString *)srtStringWithLineBreaksInSubtitlesAllowed:(BOOL)lineBreaksAllowed {
    if (_subtitleItems == nil)  return nil;
    
    NSMutableString *srtText = [NSMutableString string];
    NSUInteger srtNum = 1;
    for (SubRipItem *item in _subtitleItems) {
        [srtText appendFormat:@"%lu\n%@\n\n",
         (unsigned long)srtNum,
         subRipItem2SRTBlock(item, lineBreaksAllowed)];
        
        srtNum++;
    }
    
    return srtText;
}

-(NSString *)description {
    return [NSString stringWithFormat:@"SRT file: %@", self.subtitleItems];
}

- (SubRipItem *)subRipItemAtIndex:(NSUInteger)index {
    if (index >= _subtitleItems.count)
        return nil;
    else
        return [_subtitleItems objectAtIndex:index];
}

-(NSUInteger)indexOfSubRipItemWithStartTime:(CMTime)desiredTime {
    return [self indexOfSubRipItemForPointInTime:desiredTime];
}

-(NSUInteger)indexOfSubRipItemForPointInTime:(CMTime)desiredTime {
    NSUInteger index;
    [self subRipItemForPointInTime:desiredTime index:&index];
    return index;
}

- (SubRipItem *)subRipItemForPointInTime:(CMTime)desiredTime index:(NSUInteger *)index {
    // Finds the first SubRipItem whose startTime <= desiredTime < endTime.
    // Requires that we ensure the subtitleItems are ordered, because we are using binary search.
    
    NSUInteger subtitleItemsCount = _subtitleItems.count;
    
    // Custom binary search.
    NSUInteger low = 0;
    NSUInteger high = subtitleItemsCount - 1;
    
    while (low <= high) {
        NSUInteger mid = (low + high) >> 1;
        SubRipItem *thisSub = [_subtitleItems objectAtIndex:mid];
        CMTime thisStartTime = thisSub.startTime;
        
        if (CMTIME_COMPARE_INLINE(thisStartTime, <=, desiredTime)) {
            CMTime thisEndTime = thisSub.endTime;
            if (CMTIME_COMPARE_INLINE(desiredTime, <, thisEndTime)) {
                // desiredTime in range.
                if (index != NULL)  *index = mid;
                return thisSub;
            }
            else {
                // Continue search in upper *half*.
                low = mid + 1;
            }
        }
        else /*if (CMTIME_COMPARE_INLINE(subStartTime, >, desiredTime))*/ {
            if (mid == 0)  break; // Nothing found.
            // Continue search in lower *half*.
            high = mid - 1;
        }
    }
    
    if (index != NULL)  *index = NSNotFound;
    return nil;
}

- (SubRipItem *)nextSubRipItemForPointInTime:(CMTime)desiredTime index:(NSUInteger *)index {
    // Finds the first SubRipItem whose startTime > desiredTime.
    // Requires that we ensure the subtitleItems are ordered, because we are using binary search.
    // Donated by Peter Ljunglöf (SubTTS)
    
    NSUInteger subtitleItemsCount = _subtitleItems.count;
    
    // Customized binary search.
    NSUInteger low = 0;
    NSUInteger high = subtitleItemsCount;
    
    while (low < high) {
        NSUInteger mid = (low + high) >> 1;
        SubRipItem *sub = [_subtitleItems objectAtIndex:mid];
        
        if (CMTIME_COMPARE_INLINE(desiredTime, <, sub.startTime)) {
            high = mid;
        } else {
            low = mid + 1;
        }
    }
    
    if (low >= subtitleItemsCount) {
        if (index != NULL)  *index = NSNotFound;
        return nil;
    }
    else {
        if (index != NULL)  *index = low;
        return [_subtitleItems objectAtIndex:low];
    }
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
    [encoder encodeObject:_subtitleItems forKey:@"subtitleItems"];
}

-(instancetype)initWithCoder:(NSCoder *)decoder {
    self = [self init];
    self.subtitleItems = [decoder decodeObjectForKey:@"subtitleItems"];
    return self;
}

@end

@implementation SubRipItem

@synthesize startTime = _startTime, endTime = _endTime, text = _text, uniqueID = _uniqueID;
#if SUBRIP_TAG_SUPPORT
@synthesize attributedText = _attributedText;
@synthesize attributeOptions = _attributeOptions;
#endif
@dynamic startTimeString, endTimeString;

- (instancetype)init {
    self = [super init];
    if (self) {
        _uniqueID = JX_RETAIN([[NSProcessInfo processInfo] globallyUniqueString]);
    }
    return self;
}

- (instancetype)initWithText:(NSString *)text
                   startTime:(CMTime)startTime
                     endTime:(CMTime)endTime {
    self = [self init];
    if (self) {
        self.text = text;
        _startTime = startTime;
        _endTime = endTime;
    }
    return self;
}

#if (JX_HAS_ARC == 0)
- (void)dealloc
{
    [_text release];
    [_uniqueID release];
    
    [super dealloc];
}
#endif


- (void)parseTagsWithOptions:(NSDictionary *)options;
{
#if SUBRIP_TAG_SUPPORT
    _attributeOptions = options;
    _attributedText = [[NSMutableAttributedString alloc] initWithSRTString:_text
                                                                   options:_attributeOptions];
#else
    _attributedText = nil;
#endif
}


-(NSString *)startTimeString {
    return [self _convertCMTimeToString:_startTime];
}

-(NSString *)endTimeString {
    return [self _convertCMTimeToString:_endTime];
}


-(NSString *)_convertCMTimeToString:(CMTime)theTime {
    // Need a string of format "hh:mm:ss". (No milliseconds.)
    NSTimeInterval seconds = (NSTimeInterval)CMTimeGetSeconds(theTime);
    NSDate *date1 = JX_AUTORELEASE([NSDate new]);
    NSDate *date2 = [NSDate dateWithTimeInterval:seconds sinceDate:date1];
    unsigned int unitFlags = NSHourCalendarUnit | NSMinuteCalendarUnit | NSSecondCalendarUnit;
    NSDateComponents *converted = [[NSCalendar currentCalendar] components:unitFlags fromDate:date1 toDate:date2 options:0];
    
    NSString *str = [NSString stringWithFormat:@"%02d:%02d:%02d",
                     (int)[converted hour],
                     (int)[converted minute],
                     (int)[converted second]];
    return str;
}


-(NSString *)startTimecodeString {
    return srtTimecodeStringForCMTime(_startTime);
}

-(NSString *)endTimecodeString {
    return srtTimecodeStringForCMTime(_endTime);
}


-(NSString *)description {
    NSString *text = self.text;

    return [NSString stringWithFormat:@"%@ ---> %@: %@", self.startTimecodeString, self.endTimecodeString, text];
}

- (BOOL)isEqual:(id)obj
{
    if (obj == nil) {
        return NO;
    }
    
    if (![obj isKindOfClass:[SubRipItem class]]) {
        return NO;
    }

    SubRipItem *other = (SubRipItem *)obj;
    
    id otherText = other.text;
    
    return ((CMTimeCompare(other.startTime, _startTime) == 0) &&
            (CMTimeCompare(other.endTime, _endTime) == 0) &&
            ((otherText == _text) || [otherText isEqualTo:_text]));
}

- (BOOL)isEqualToSubRipItem:(SubRipItem *)other
{
    if (other == nil) {
        return NO;
    }
    
    id otherText = other.text;
    
    return ((CMTimeCompare(other.startTime, _startTime) == 0) &&
            (CMTimeCompare(other.endTime, _endTime) == 0) &&
            ((otherText == _text) || [otherText isEqualTo:_text]));
}


-(NSInteger)startTimeInSeconds {
    return (NSInteger)CMTimeGetSeconds(_startTime);
}

-(NSInteger)endTimeInSeconds {
    return (NSInteger)CMTimeGetSeconds(_endTime);
}

-(double)startTimeDouble {
    return (double)CMTimeGetSeconds(_startTime);
}

-(double)endTimeDouble {
    return (double)CMTimeGetSeconds(_endTime);
}


-(void)setStartTimeFromString:(NSString *)timecodeString {
    self.startTime = [SubRip parseTimecodeStringIntoCMTime:timecodeString];
}

-(void)setEndTimeFromString:(NSString *)timecodeString {
    self.endTime = [SubRip parseTimecodeStringIntoCMTime:timecodeString];
}

#if SUBRIP_TAG_SUPPORT
-(void)setAttributedText:(NSAttributedString *)attributedText {
    _attributedText = attributedText;
    _text = [attributedText srtString];
}
#endif


-(BOOL)containsString:(NSString *)str {
    NSRange searchResult = [_text rangeOfString:str options:NSCaseInsensitiveSearch];
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
    [encoder encodeCMTime:_startTime forKey:@"startTime"];
    [encoder encodeCMTime:_endTime forKey:@"endTime"];
    [encoder encodeObject:_text forKey:@"text"];
#if SUBRIP_TAG_SUPPORT
    BOOL didParseTags = (_attributedText != nil);
    [encoder encodeBool:didParseTags forKey:@"didParseTags"];
    [encoder encodeObject:_attributeOptions forKey:@"attributeOptions"];
#endif
}

-(instancetype)initWithCoder:(NSCoder *)decoder {
    self = [self init];
    _startTime = [decoder decodeCMTimeForKey:@"startTime"];
    _endTime = [decoder decodeCMTimeForKey:@"endTime"];
    self.text = [decoder decodeObjectForKey:@"text"];
#if SUBRIP_TAG_SUPPORT
    NSDictionary *options = [decoder decodeObjectForKey:@"attributeOptions"];
    BOOL didParseTags = [decoder decodeBoolForKey:@"didParseTags"];
    if (didParseTags) {
        [self parseTagsWithOptions:options];
    }
#endif
    return self;
}
            
@end