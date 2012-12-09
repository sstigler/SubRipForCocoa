//
//  SubRipTest.m
//  SubRipTest
//
//  Created by Jan on 27.11.12.
//
//

#import "SubRipTest.h"

#import <CoreMedia/CMTime.h>

#import <SubRip/SubRip.h>
#import "NSMutableAttributedString+SRTString.h"

static NSString *testString1;

@implementation SubRipTest

- (void)setUp
{
	[super setUp];
	
	NSError *error = nil;
	
	NSBundle *testBundle = [NSBundle bundleForClass:[self class]];
	// Test string from http://www.visualsubsync.org/help/srt
	testString1 = [[NSString alloc] initWithContentsOfURL:[testBundle URLForResource:@"test" withExtension:@"srt"]
												 encoding:NSUTF8StringEncoding
													error:&error];
	if (testString1 == nil) {
		NSLog(@"%@", error);
	}
#if 0
	else {
		NSLog(@"%@", subRip);
	}
#endif
}

- (void)tearDown
{
	// Tear-down code here.
	
	[super tearDown];
}

- (void)testBasic
{
	NSError *error = nil;
	
	SubRipItem *expectedItem1 = [[SubRipItem alloc] initWithText:@"This is the first subtitle"
													   startTime:CMTimeMakeWithSeconds(12.000, 1000)
														 endTime:CMTimeMakeWithSeconds(15.123, 1000)];
	
	SubRip *subRip = [[SubRip alloc] initWithString:testString1];
	if (subRip == nil) {
		NSLog(@"%@", error);
		STFail(@"Couldn’t parse testString1.");
	}
	
	NSArray *subtitleItems = subRip.subtitleItems;
	SubRipItem *item0 = [subtitleItems objectAtIndex:0];
	STAssertEqualObjects(item0, expectedItem1, @"Item 0 doesn’t match expectations.");
	
}

#if SUBRIP_TAG_SUPPORT
- (void)testTagParsingSupport
{
	NSError *error = nil;
	
	NSString *expectedText = @""
	"Another subtitle demonstrating tags:\n"
	"bold, italic, underlined\n"
	"red text";
	
	SubRip *subRip = [[SubRip alloc] initWithString:testString1];
	if (subRip == nil) {
		NSLog(@"%@", error);
		STFail(@"Couldn’t parse testString1.");
	}
	
	[subRip parseTags];
	
	NSArray *subtitleItems = subRip.subtitleItems;
	SubRipItem *item1 = [subtitleItems objectAtIndex:1];
	STAssertEqualObjects(item1.attributedText.string, expectedText, @"Item 1 attributedText.string doesn’t match expectations.");
	
}

#define VERBOSE_TEST	0

- (void)testSRTString
{
	NSString *sourceSRTString = @""
	"Another subtitle demonstrating tags:\n"
	"<b>bold</b>, <i>italic</i>, <u>underlined</u>\n"
	"<font color=\"#ff0000\">red text</font>";
	
	NSMutableAttributedString *string = [[NSMutableAttributedString alloc] initWithSRTString:sourceSRTString
																				  attributes:nil];
	
	if (VERBOSE_TEST)  NSLog(@"\n---\n%@\n---", string.string);
	
	NSString *resultSRTString = string.srtString;
	
	if (VERBOSE_TEST)  NSLog(@"\n---\n%@\n---", resultSRTString);
	
	STAssertEqualObjects(sourceSRTString, resultSRTString, @"Output on SRT String Test differs");
	
	if (VERBOSE_TEST)  NSLog(@"\n------");
}

- (void)testNestedSRTString
{
	NSString *sourceSRTString = @""
	"<b>bold, <i>bold and italic, <u>bold-italic-underlined</u></i></b>\n"
	"<font color=\"#ff0000\">red text, </font><font color=\"#00ff00\">green text</font>";
	
	NSMutableAttributedString *string = [[NSMutableAttributedString alloc] initWithSRTString:sourceSRTString
																				  attributes:nil];
	
	if (VERBOSE_TEST)  NSLog(@"\n---\n%@\n---", string.string);
	
	NSString *resultSRTString = string.srtString;
	
	if (VERBOSE_TEST)  NSLog(@"\n---\n%@\n---", resultSRTString);
	
	STAssertEqualObjects(sourceSRTString, resultSRTString, @"Output on nested SRT String Test differs");
	
	if (VERBOSE_TEST)  NSLog(@"\n------");
}

- (void)testNestedSRTString2
{
	NSString *sourceSRTString = @""
	"<font color=\"#ff0000\"><b>red bold text</b>, </font><font color=\"#00ff00\"><b>bold green text</b></font>";
	
	NSMutableAttributedString *string = [[NSMutableAttributedString alloc] initWithSRTString:sourceSRTString
																				  attributes:nil];
	
	if (VERBOSE_TEST)  NSLog(@"\n---\n%@\n---", string.string);
	
	NSString *resultSRTString = string.srtString;
	
	if (VERBOSE_TEST)  NSLog(@"\n---\n%@\n---", resultSRTString);
	
	STAssertEqualObjects(sourceSRTString, resultSRTString, @"Output on nested SRT String Test 2 differs");
	
	if (VERBOSE_TEST)  NSLog(@"\n------");
}

- (void)testAngleBrackets
{
	NSString *sourceSRTString = @""
	"a < b + c\n"
	"OR\n"
	"a >= b + c";
	
	NSMutableAttributedString *string = [[NSMutableAttributedString alloc] initWithSRTString:sourceSRTString
																				  attributes:nil];
	
	if (VERBOSE_TEST)  NSLog(@"\n---\n%@\n---", string.string);
	
	NSString *resultSRTString = string.srtString;
	
	if (VERBOSE_TEST)  NSLog(@"\n---\n%@\n---", resultSRTString);
	
	STAssertEqualObjects(sourceSRTString, resultSRTString, @"Output on SRT String Test differs");
	
	if (VERBOSE_TEST)  NSLog(@"\n------");
}

#endif

@end
