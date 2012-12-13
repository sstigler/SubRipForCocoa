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

+ (void)parseTimecodeString:(NSString *)timecodeString intoSeconds:(NSInteger *)totalNumSeconds milliseconds:(NSInteger *)milliseconds {
    NSArray *timeComponents = [timecodeString componentsSeparatedByString:@":"];
    
    NSInteger hours = [(NSString *)[timeComponents objectAtIndex:0] integerValue];
    NSInteger minutes = [(NSString *)[timeComponents objectAtIndex:1] integerValue];
    
    NSArray *secondsComponents = [(NSString *)[timeComponents objectAtIndex:2] componentsSeparatedByString:@","];
#if SUBRIP_SUBVIEWER_SUPPORT
	if (secondsComponents.count < 2)  secondsComponents = [(NSString *)[timeComponents objectAtIndex:2] componentsSeparatedByString:@"."];
#endif
    NSInteger seconds = [(NSString *)[secondsComponents objectAtIndex:0] integerValue];
    
    *milliseconds = [(NSString *)[secondsComponents objectAtIndex:1] integerValue];
    *totalNumSeconds = (hours * 3600) + (minutes * 60) + seconds;
}

+ (CMTime)parseIntoCMTime:(NSString *)timecodeString {
    NSInteger milliseconds;
    NSInteger totalNumSeconds;
    
    [SubRip parseTimecodeString:timecodeString
                  intoSeconds:&totalNumSeconds
                 milliseconds:&milliseconds];
    
    CMTime startSeconds = CMTimeMake(totalNumSeconds, 1);
    CMTime millisecondsCMTime = CMTimeMake(milliseconds, 1000);
    CMTime time = CMTimeAdd(startSeconds, millisecondsCMTime);
    
    return time;
}

// returns YES if successful, NO if not succesful.
// assumes that str is a correctly-formatted SRT file.
-(BOOL)_populateFromString:(NSString *)str {
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
                
                cur.startTime = [SubRip parseIntoCMTime:beginning];
                cur.endTime = [SubRip parseIntoCMTime:ending];
                
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
			(int)floor(seconds / 60 / 60),						// H
			(int)floor(seconds / 60),							// M
			(int)floor(seconds_floor_int % 60),					// S
			(int)round((seconds - seconds_floor) * 1000.0f)];	// cs

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

-(NSUInteger)indexOfSubRipItemWithStartTime:(CMTime)desiredTime {
    return [self indexOfSubRipItemForPointInTime:desiredTime];
}

-(NSUInteger)indexOfSubRipItemForPointInTime:(CMTime)desiredTime {
    // This is slower than necessary as it will traverse all subtitleItems: O(n). We could reimplement this using a binary search,
    // which would require that we ensure the subtitleItems are ordered.
    return [self.subtitleItems indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
        if ((CMTIME_COMPARE_INLINE(desiredTime, >=, [(SubRipItem *)obj startTime])) &&
            (CMTIME_COMPARE_INLINE(desiredTime, <=, [(SubRipItem *)obj endTime]))
            ) {
            *stop = YES;
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


-(NSString *)description {
#if SUBRIP_TAG_SUPPORT
	NSString *text = [_attributedText srtString];
#else
	NSString *text = self.text;
#endif

    return [NSString stringWithFormat:@"%@ ---> %@\n%@", self.startTimeString, self.endTimeString, text];
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
    self.startTime = [SubRip parseIntoCMTime:timecodeString];
}

-(void)setEndTimeFromString:(NSString *)timecodeString {
    self.endTime = [SubRip parseIntoCMTime:timecodeString];
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