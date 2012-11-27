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
	SubRipItem *item1 = subtitleItems[0];
	STAssertEqualObjects(item1, expectedItem1, @"Item 1 doesn’t match expectations.");
	
}

@end
