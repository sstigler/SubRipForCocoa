//
//  SubRipTest.m
//  SubRipTest
//
//  Created by Jan on 27.11.12.
//
//

#import "SubRipTest.h"

#import "SubRip.h"

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
}

- (void)tearDown
{
	// Tear-down code here.
	
	[super tearDown];
}

- (void)testBasic
{
	NSError *error = nil;
	
	SubRip *subRip = [[SubRip alloc] initWithString:testString1];
	if (subRip == nil) {
		NSLog(@"%@", error);
		STFail(@"Couldn’t parse testString1.");
	}
	
	//subtitleItems = subRip.subtitleItems;
	NSLog(@"%@", subRip);
}

@end
