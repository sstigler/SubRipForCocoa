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
#import <SubRip/DTCoreTextConstants.h>
#import "NSMutableAttributedString+SRTString.h"

static NSString *testString1;
static NSString *testTaggedSRTString1;

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
	
	testTaggedSRTString1 = @""
	"Another subtitle demonstrating tags:\n"
	"<b>bold</b>, <i>italic</i>, <u>underlined</u>\n"
	"<font color=\"#ff0000\">red text</font>";

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

- (void)testCoding
{
	NSError *error = nil;
	
	SubRip *subRip = [[SubRip alloc] initWithString:testString1];
	if (subRip == nil) {
		NSLog(@"%@", error);
		STFail(@"Couldn’t parse testString1.");
	}
	
	NSData *data1 = [NSKeyedArchiver archivedDataWithRootObject:subRip];
	SubRip *subRipDecoded = [NSKeyedUnarchiver unarchiveObjectWithData:data1];
	NSData *data2 = [NSKeyedArchiver archivedDataWithRootObject:subRipDecoded];

	STAssertEqualObjects(data1, data2, @"Coding test failed.");
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

- (void)testTagGenerationSupport
{
	NSString *expectedText = testTaggedSRTString1;
	
	SubRipItem *item1 = [[SubRipItem alloc] initWithText:nil
											   startTime:CMTimeMakeWithSeconds(16.000, 1000)
												 endTime:CMTimeMakeWithSeconds(18.000, 1000)];
	
	// This will also set item1.text to text with tags generated based on the options.
	item1.attributedText = [[NSMutableAttributedString alloc] initWithSRTString:testTaggedSRTString1
																		options:nil];
	
	STAssertEqualObjects(item1.text, expectedText, @"Tag generation #1 from attributedText failed.");
}

- (void)testTagParsingWithOptionsSupport
{
	NSError *error = nil;
	
	CGFloat defaultSize = 16.0;
	NSString *defaultFontName = @"Times";

	NSFont *font = [NSFont fontWithName:defaultFontName
								   size:defaultSize];
	
	NSDictionary *expectedAttributes = @{NSFontAttributeName : font};
	
	SubRip *subRip = [[SubRip alloc] initWithString:testString1];
	if (subRip == nil) {
		NSLog(@"%@", error);
		STFail(@"Couldn’t parse testString1.");
	}
	
	NSDictionary *srtStringParsingAttributes = @{
		DTDefaultFontFamily : defaultFontName,
		NSTextSizeMultiplierDocumentOption : @(16.0/12.0)
	};
	
	[subRip parseTagsWithOptions:srtStringParsingAttributes];
	
	NSArray *subtitleItems = subRip.subtitleItems;
	SubRipItem *item1 = [subtitleItems objectAtIndex:1];
	NSDictionary *attributes = [item1.attributedText attributesAtIndex:0 effectiveRange:NULL];
	STAssertEqualObjects(attributes, expectedAttributes, @"Item 1 attributedText attributes don’t match expectations.");
	
}

#define VERBOSE_TEST	0

- (void)testSRTString
{
	NSString *sourceSRTString = testTaggedSRTString1;
	
	NSMutableAttributedString *string = [[NSMutableAttributedString alloc] initWithSRTString:sourceSRTString
																					 options:nil];
	
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
																					 options:nil];
	
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
																					 options:nil];
	
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
																					 options:nil];
	
	if (VERBOSE_TEST)  NSLog(@"\n---\n%@\n---", string.string);
	
	NSString *resultSRTString = string.srtString;
	
	if (VERBOSE_TEST)  NSLog(@"\n---\n%@\n---", resultSRTString);
	
	STAssertEqualObjects(sourceSRTString, resultSRTString, @"Output on SRT String Test differs");
	
	if (VERBOSE_TEST)  NSLog(@"\n------");
}

#endif

@end
