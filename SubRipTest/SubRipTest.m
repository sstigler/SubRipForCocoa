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
static NSMutableDictionary *testStringsDict;

static NSString *malformedTestString1;

static NSString *testTaggedSRTString1;

@implementation SubRipTest

- (NSString *)loadTestFileWithName:(NSString *)testFileName
						fromBundle:(NSBundle *)testBundle
							 error:(NSError **)error
{
	NSString *testString;
	
    testString = [[NSString alloc] initWithContentsOfURL:[testBundle URLForResource:testFileName withExtension:@"srt"]
												encoding:NSUTF8StringEncoding
												   error:&(*error)];
	if (testString == nil) {
		NSLog(@"%@", *error);
	}
#if 0
	else {
		NSLog(@"%@", testString);
	}
#endif
	
	return testString;
}

- (void)setUp
{
	[super setUp];
	
	NSError *error = nil;
	
	NSBundle *testBundle = [NSBundle bundleForClass:[self class]];
	
	// Test string from http://www.visualsubsync.org/help/srt
	testStringsDict = [NSMutableDictionary dictionary];
	
	NSArray *testStringNames = [NSArray arrayWithObjects:@"test", @"test-newline", @"test-missing-trailing-newline", @"test-missing-milliseconds", @"test-empty-text", nil];
	for (NSString *testFileName in testStringNames) {
		[testStringsDict setObject:[self loadTestFileWithName:testFileName fromBundle:testBundle error:&error] forKey:testFileName];
	}
	
	testString1 = [testStringsDict objectForKey:@"test"];
	
	malformedTestString1 = [self loadTestFileWithName:@"test-malformed" fromBundle:testBundle error:&error];
	
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

- (void)testParsing
{
	NSError *error = nil;
	
	[testStringsDict enumerateKeysAndObjectsUsingBlock:^(NSString *testStringName, NSString *testString, BOOL *stop) {
		SubRip *subRip = [[SubRip alloc] initWithString:testString];
		if (subRip == nil) {
			NSLog(@"%@", error);
			STFail(@"Couldn’t parse %@.", testStringName);
		}
	}];
	
	SubRip *subRip = [[SubRip alloc] initWithString:malformedTestString1
											  error:&error];
	if (subRip != nil) {
		STFail(@"Could parse malformedTestString1.");
	}
#if 0
	else {
		NSLog(@"%@", error);
	}
#endif
}

- (void)testPosition
{
	NSError *error = nil;
	
	CGRect expectedFrame = CGRectMake(40, 20, 560, 30);

	SubRip *subRip = [[SubRip alloc] initWithString:testString1];
	if (subRip == nil) {
		NSLog(@"%@", error);
		STFail(@"Couldn’t parse testString1.");
	}
	
	NSArray *subtitleItems = subRip.subtitleItems;
	SubRipItem *item2 = [subtitleItems objectAtIndex:2];
	STAssertTrue(CGRectEqualToRect(item2.frame, expectedFrame), @"Item 2’s frame doesn’t match expectations.");
}

- (void)testSRTString
{
	NSError *error = nil;
	
	NSString *expectedString = [testStringsDict objectForKey:@"test-newline"];

	SubRip *subRip = [[SubRip alloc] initWithString:expectedString];
	if (subRip == nil) {
		NSLog(@"%@", error);
		STFail(@"Couldn’t parse testString1.");
	}
	
	NSString *srtString = subRip.srtString;
	
	STAssertEqualObjects(srtString, expectedString, @"Item 0 doesn’t match expectations.");
}

typedef struct _SubRipTestTimeIndexPair {
	CMTime time;
	NSUInteger index;
} SubRipTestTimeIndexPair;

- (void)testTimeAndIndex
{
	NSError *error = nil;
	
	SubRip *subRip = [[SubRip alloc] initWithString:testString1];
	if (subRip == nil) {
		NSLog(@"%@", error);
		STFail(@"Couldn’t parse testString1.");
	}
	
	SubRipTestTimeIndexPair timeIndexPairs[] = {
		{(CMTime){    0, 1000, 1}, NSNotFound},
		{(CMTime){12000, 1000, 1}, 0},
		{(CMTime){13000, 1000, 1}, 0},
		{(CMTime){15123, 1000, 1}, NSNotFound},
		{(CMTime){16000, 1000, 1}, 1},
		{(CMTime){17000, 1000, 1}, 1},
		{(CMTime){18000, 1000, 1}, NSNotFound},
		{(CMTime){20000, 1000, 1}, 2},
		{(CMTime){21000, 1000, 1}, 2},
		{(CMTime){22000, 1000, 1}, NSNotFound}
	};
	
	int timeIndexPairCount = sizeof(timeIndexPairs)/sizeof(timeIndexPairs[0]);
	
	for (int i = 0; i < timeIndexPairCount; i++) {
		NSUInteger index;
		CMTime time = timeIndexPairs[i].time;
		NSUInteger expectedIndex = timeIndexPairs[i].index;
		NSString *timeString = CFBridgingRelease(CMTimeCopyDescription(kCFAllocatorDefault, time));
		[subRip subRipItemForPointInTime:time index:&index];
		
		STAssertEquals(index, expectedIndex, @"Time test at %@ failed.", timeString);
	}
}

- (void)testNextTimeAndIndex
{
	NSError *error = nil;
	
	SubRip *subRip = [[SubRip alloc] initWithString:testString1];
	if (subRip == nil) {
		NSLog(@"%@", error);
		STFail(@"Couldn’t parse testString1.");
	}
	
	SubRipTestTimeIndexPair timeIndexPairs[] = {
		{(CMTime){    0, 1000, 1}, 0},
		{(CMTime){12000, 1000, 1}, 1},
		{(CMTime){13000, 1000, 1}, 1},
		{(CMTime){15123, 1000, 1}, 1},
		{(CMTime){16000, 1000, 1}, 2},
		{(CMTime){17000, 1000, 1}, 2},
		{(CMTime){18000, 1000, 1}, 2},
		{(CMTime){20000, 1000, 1}, NSNotFound},
		{(CMTime){21000, 1000, 1}, NSNotFound},
		{(CMTime){22000, 1000, 1}, NSNotFound}
	};
	
	int timeIndexPairCount = sizeof(timeIndexPairs)/sizeof(timeIndexPairs[0]);
	
	for (int i = 0; i < timeIndexPairCount; i++) {
		NSUInteger index;
		CMTime time = timeIndexPairs[i].time;
		NSUInteger expectedIndex = timeIndexPairs[i].index;
		NSString *timeString = CFBridgingRelease(CMTimeCopyDescription(kCFAllocatorDefault, time));
		[subRip nextSubRipItemForPointInTime:time index:&index];
		
		STAssertEquals(index, expectedIndex, @"Time test at %@ failed.", timeString);
	}
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

- (void)testConvertSRTString
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

- (void)testConvertNestedSRTString
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

- (void)testConvertNestedSRTString2
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

- (void)testConvertAngleBrackets
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
