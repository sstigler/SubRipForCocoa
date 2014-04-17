#if TARGET_OS_IPHONE
#import <CoreText/CoreText.h>
#elif TARGET_OS_MAC
#import <ApplicationServices/ApplicationServices.h>
#endif

// global constants
#import "DTCoreTextConstants.h"
#import "DTCompatibility.h"

#import "DTColor+HTML.h"

// common classes
#import "DTCoreTextFontDescriptor.h"
#import "JXSRTElement.h"
#import "NSCharacterSet+HTML.h"
#import "NSScanner+SRTTags.h"
#import "NSString+HTML.h"
#import "DTCoreTextParagraphStyle.h"
#import "NSMutableAttributedString+SRTString.h"
#import "NSMutableAttributedString+HTML.h"
