//
//  MGSObjectStyler.m
//  KosmicTask
//
//  Created by Jonathan on 07/04/2010.
//  Copyright 2010 mugginsoft.com. All rights reserved.
//
#import "MLog.h"
#import "MGSObjectStyler.h"
#import "NSString_Mugginsoft.h"
#import "NSArray_Mugginsoft.h"
#import "NSColor_Mugginsoft.h"
#import "NSDictionary_Mugginsoft.h"
#import "MGSResultFormat.h"

static void setItalicOrObliqueFont( NSMutableDictionary *attrs );
static void removeItalicOrObliqueFont( NSMutableDictionary *attrs );
static NSString *parseCSSStyleAttribute( NSString *style, NSMutableDictionary *currentAttributes );

#define JVItalicObliquenessValue 0.16f

// style dictionary keys
NSString *MGSStyleFilter = @"MGSStyleFilter";
NSString *MGSStyleLevel = @"MGSStyleLevel";

// style name keys
NSString *MGSLevelStyleName = @"MGSLevelStyleName";
NSString *MGSTerminatorStyleName = @"MGSTerminatorStyleName";
NSString *MGSAppendTerminatorStyleName = @"MGSAppendTerminatorStyleName";

// default style name keys
NSString *MGSDefaultAttributesStyleName = @"MGSDefaultAttributesStyleName";

// dictionary style name keys
NSString *MGSDictAttributesStyleName = @"MGSDictAttributesStyleName";
NSString *MGSDictKeyAttributesStyleName = @"MGSDictKeyAttributesStyleName";
NSString *MGSDictObjectAttributesStyleName = @"MGSDictObjectAttributesStyleName";
NSString *MGSDictFilterStyleName = @"MGSDictFilterStyleName";
NSString *MGSDictKeyFilterStyleName = @"MGSDictKeyFilterStyleName";
NSString *MGSDictInLineStyleName = @"MGSDictInLineStyleName";
NSString *MGSDictKeySuffixStyleName = @"MGSDictKeySuffixStyleName";

// computed style name keys
NSString *MGSComputedAttributesStyleName = @"MGSComputedAttributesStyleName";

// array style name keys
NSString *MGSArrayAttributeStyleName = @"MGSArrayAttributeStyleName";
NSString *MGSArrayEvenAttributeStyleName = @"MGSArrayEvenAttributeStyleName";
NSString *MGSArrayOddAttributesStyleName = @"MGSArrayOddAttributesStyleName";

// class extension
@interface MGSObjectStyler ()
- (BOOL)filterObject:(id)anObject filterKey:(NSString *)filterKeyName withStyle:(NSDictionary *)styleDict;
- (void)incrementStyleLevel:(NSMutableDictionary *)styleDict;
+ (void)parseCSS:(id)css intoAttributes:(NSMutableDictionary *)attributes;
+ (CGFloat)attributePointSize:(NSString *)attr existingPointSize:(CGFloat)existingPointSize;
@end

@implementation MGSObjectStyler

/*
 
 + stylerWithObject:
 
 */
+ (MGSObjectStyler *)stylerWithObject:(id)object
{
	return [[self alloc] initWithObject:object];
}

/*
 
 - styleDictionaryWithAttributes:
 
 */
+ (NSMutableDictionary *)baseAttributes
{
	// form the base attribute dictionary
	NSMutableDictionary *baseAttributes = [NSMutableDictionary dictionaryWithCapacity:5];
	[baseAttributes setObject:[NSFont controlContentFontOfSize:0] forKey:NSFontAttributeName];
	[baseAttributes setObject:[NSColor blackColor] forKey:NSForegroundColorAttributeName];
	
	return baseAttributes;
}

/*
 
 - styleDictionaryWithAttributes:
 
 */
+ (NSDictionary *)styleDictionaryWithAttributes:(NSDictionary *)defaultAttributes
{
	// form the base attribute dictionary
	NSMutableDictionary *baseAttributes = self.baseAttributes;
	[baseAttributes addEntriesFromDictionary:defaultAttributes];
	
	// extract base properties
	NSFont *baseFont = [baseAttributes objectForKey:NSFontAttributeName];
	NSColor *baseColor = [baseAttributes objectForKey:NSForegroundColorAttributeName];
	
	// prepare fonts
	NSFont *keyFont = [[NSFontManager sharedFontManager] convertFont:baseFont toHaveTrait:NSBoldFontMask];
	
	//
	// default attribute dictionaries
	// this is the default style
	//
	NSDictionary *defaultAttrs = [NSDictionary dictionaryWithObjectsAndKeys:baseFont, NSFontAttributeName, 
								 baseColor, NSForegroundColorAttributeName,
								 [NSColor whiteColor], NSBackgroundColorAttributeName, nil];
	/*
	 // info key styling
	[MGSResultFormat infoKeys]
	[NSDictionary dictionaryWithObjectsAndKeys:[NSColor blueColor], NSForegroundColorAttributeName, nil];
	
	 // error key styling
	[MGSResultFormat errorKeys]
	[NSDictionary dictionaryWithObjectsAndKeys:[NSColor redColor], NSForegroundColorAttributeName, nil];
	*/
	
	//
	// computed attribute dictionaries
	//
	NSDictionary *computedAttrs = [NSDictionary new];
	
	//
	// dictionary attribute dictionaries
	//
	NSDictionary *dictAttrs = [NSDictionary new];
	NSDictionary *dictObjectAttrs = [NSDictionary new];
	NSDictionary *dictKeyAttrs = [NSDictionary dictionaryWithObjectsAndKeys:keyFont, NSFontAttributeName, nil];
	
	// dictionary filters
	NSDictionary *dictFilter = [NSDictionary dictionaryWithObjectsAndKeys:
								[MGSResultFormat dictStyleFilterKeys], MGSStyleFilter,
								[NSNumber numberWithInteger:-1], MGSStyleLevel,
								nil];
	
	NSDictionary *dictKeyFilter = [NSDictionary dictionaryWithObjectsAndKeys:
								   [MGSResultFormat dictKeyStyleFilterKeys], MGSStyleFilter,
								   [NSNumber numberWithInteger:-1], MGSStyleLevel,
								   nil];
	
	// dictionary style keys
	NSArray *dictInlineStyleNames = [MGSResultFormat inlineStyleKeys];
	
	//
	// array attribute dictionaries
	//
	NSArray *colorAlternates = [NSColor controlAlternatingRowBackgroundColors];
	NSUInteger colorIndexEven = 0, colorIndexOdd = 0;
	
	NSAssert([colorAlternates count] > 0, @"Alternate row colours not available");
	
	if ([colorAlternates count] >= 2) {
		colorIndexOdd = 1;
	}
	
	NSDictionary *arrayAttrs = [NSDictionary new];
	NSDictionary *arrayAttrsEven = [NSDictionary dictionaryWithObjectsAndKeys:[colorAlternates objectAtIndex:colorIndexEven], NSBackgroundColorAttributeName, nil];
	NSDictionary *arrayAttrsOdd = [NSDictionary dictionaryWithObjectsAndKeys: [colorAlternates objectAtIndex:colorIndexOdd], NSBackgroundColorAttributeName, nil];
	
	// define keys to style our result
	NSDictionary *styleDict = [NSDictionary dictionaryWithObjectsAndKeys:
							   
							   // generic
							   [NSNumber numberWithInteger:0], MGSLevelStyleName,
							   
							   // terminator
							   @"\n", MGSTerminatorStyleName,
							   [NSNumber numberWithBool:YES], MGSAppendTerminatorStyleName,
							   
							   // default styles
							   defaultAttrs, MGSDefaultAttributesStyleName,
							   
							   // computed styles
							   computedAttrs, MGSComputedAttributesStyleName,
							
							   // array styles
							   arrayAttrs, MGSArrayAttributeStyleName,
							   arrayAttrsEven, MGSArrayEvenAttributeStyleName,
							   arrayAttrsOdd,  MGSArrayOddAttributesStyleName,
							   
							   // dictionary styles
							   @": ", MGSDictKeySuffixStyleName,
							   dictAttrs, MGSDictAttributesStyleName,
							   dictKeyAttrs, MGSDictKeyAttributesStyleName,
							   dictObjectAttrs, MGSDictObjectAttributesStyleName,
							   dictFilter, MGSDictFilterStyleName,
							   dictKeyFilter, MGSDictKeyFilterStyleName,
							   dictInlineStyleNames, MGSDictInLineStyleName,
							   nil];
	
	return styleDict;
}

/*
 
 + parseCSSToAttributes:
 
 */
+ (void)parseCSS:(id)css intoAttributes:(NSMutableDictionary *)attributes
{

	NSString *CSSString = nil;

	// get CSS string
	if ([css isKindOfClass:[NSString class]]) {
		CSSString = css;
		
		// permit an array of style defs
	} else if ([css isKindOfClass:[NSArray class]]) {
		
		NSMutableString *newString = [[NSMutableString alloc] initWithString:@""];
		for (id styleItem in css) {
			[newString appendString:[styleItem description]];
		}
		
		CSSString = newString;
	}

	// convert CSS string to NSAttributedString attributes
	if (CSSString) {
		parseCSSStyleAttribute(CSSString, attributes);
	} else {
		MLogInfo(@"inline style must be a string. type %@ found", [css class]);
	}
	
}

/*
 
 - initWithObject:
 
 designated initialiser
 
 */
- (MGSObjectStyler *)initWithObject:(id)object
{
	if ((self = [super init])) {
		targetObject = object;
	}
	
	return self;
}

/*
 
 - init
  
 */
- (MGSObjectStyler *)init
{
	return [self initWithObject:nil];
}

/*
 
 - object:descriptionWithStyle:
 
 */
- (NSAttributedString *)object:(id)anObject descriptionWithStyle:(NSDictionary *)inputStyleDict
{
	
	// we will apply attributes as required to our attributed string
	NSMutableAttributedString *mString = [[NSMutableAttributedString alloc] init];
	
	// make a mutable style dictionary copy
	NSMutableDictionary *styleDict= [inputStyleDict mutableCopy];
	
	// computed attributes
	NSDictionary *computedAttributes = [styleDict objectForKey:MGSComputedAttributesStyleName];

	// default attributes
	NSDictionary *defaultAttributes = [styleDict objectForKey:MGSDefaultAttributesStyleName];		
	NSAssert(defaultAttributes, @"Default styling attributes not found");

	//
	// style array
	//
	if ([anObject isKindOfClass:[NSArray class]]) {
		
		// get array attributes
		NSMutableDictionary *arrayAttributes = [[styleDict objectForKey:MGSArrayAttributeStyleName] mutableCopy];
		
		// increment level for objects in collection
		[self incrementStyleLevel:styleDict];

		// form even row attribute dictionaries 
		NSMutableDictionary *arrayAttributesEven = [arrayAttributes mutableCopy];
		[arrayAttributesEven addEntriesFromDictionary:[styleDict objectForKey:MGSArrayEvenAttributeStyleName]];
		
		NSMutableDictionary *arrayComputedAttributesEven = [arrayAttributesEven mutableCopy];
		[arrayComputedAttributesEven addEntriesFromDictionary:computedAttributes];

		// form odd row attribute dictionaries 
		NSMutableDictionary *arrayAttributesOdd = [arrayAttributes mutableCopy];
		[arrayAttributesOdd addEntriesFromDictionary:[styleDict objectForKey:MGSArrayOddAttributesStyleName]];
		
		NSMutableDictionary *arrayComputedAttributesOdd = [arrayAttributesOdd mutableCopy];
		[arrayComputedAttributesOdd addEntriesFromDictionary:computedAttributes];

		BOOL isOdd = NO;
		NSColor *backgroundColor = [arrayAttributes objectForKey:NSBackgroundColorAttributeName];
		if ([arrayAttributesEven objectForKey:NSBackgroundColorAttributeName] == backgroundColor) {
			isOdd = YES;
		}

		NSDictionary *arrayRowAttributes = nil;
		NSDictionary *arrayComputedAttributes = nil;

		// alternate array item background colour styling
		for (id item in (NSArray *)anObject) {
			
			// apply row styling
			if (isOdd) {
				arrayRowAttributes = arrayAttributesOdd;
				arrayComputedAttributes = arrayComputedAttributesOdd;
			} else {
				arrayRowAttributes = arrayAttributesEven;
				arrayComputedAttributes = arrayComputedAttributesEven;
			}
			
			// form style dict 
			//[styleDict setObject:arrayRowAttributes forKey:MGSArrayAttributeStyleName];
			[styleDict setObject:arrayComputedAttributes forKey:MGSComputedAttributesStyleName];
			
			// get attributed description
			NSAttributedString *itemRep = [self object:item descriptionWithStyle:styleDict];
			
			// append
			[mString appendAttributedString:itemRep];
			
			// alternate rows
			isOdd = !isOdd;
		}
	}
	//
	// style dictionary
	//	
	else if ([anObject isKindOfClass:[NSDictionary class]]) {
		
		// get key suffix from style dict
		NSString *keySuffix = [styleDict objectForKey:MGSDictKeySuffixStyleName];
		
		// validate keys all NSString instances
		NSArray *allKeys = [(NSDictionary *)anObject allKeys];
        
        // sort keys?
        NSMutableArray *keys = nil;
        BOOL sortKeys = YES;
        
        // sorting keys may not be desirable as user may have ordered the keys for display.
        // however it seems that for many languages the order that the keys are inserted
        // or created has little or no bearing on the order in which thet are rendered.
        // TODO: make sorting optional
        if (sortKeys) {
            keys = [NSMutableArray arrayWithArray:[allKeys mgs_sortedArrayUsingBestSelector]];
        } else {
            keys = [NSMutableArray arrayWithArray:allKeys];
        }
        
		// increment level for objects in collection
		[self incrementStyleLevel:styleDict];
		
		//
		// get inline CSS styling string and attributes
		//
		NSMutableDictionary *inlineAttributes = [NSMutableDictionary dictionaryWithCapacity:10];
		id inlineCSS = [(NSDictionary *)anObject mgs_objectForKeys:[styleDict objectForKey:MGSDictInLineStyleName] caseSensitive:false];
		if (inlineCSS) {
			//
			// CSS font parsing requires an NSFontInstance to operate on.
			// if none present then insert the default font
			//
			if (![inlineAttributes objectForKey:NSFontAttributeName]) {
				NSFont *defaultFont = [defaultAttributes objectForKey:NSFontAttributeName];
				NSAssert(defaultFont, @"default font not found");
				
				[inlineAttributes setObject:defaultFont forKey:NSFontAttributeName];
			}
			[[self class] parseCSS:inlineCSS intoAttributes:inlineAttributes];
		}
		
        // move keys to be discarded to the top of the sorted keys array.
        NSDictionary *filterDict = [styleDict objectForKey:MGSDictKeyFilterStyleName];
        NSArray *filterKeys = [filterDict objectForKey:MGSStyleFilter];
        
        // we need to move the filter keys to the start of the keys array in reverse order
        NSEnumerator *enumerator = [filterKeys reverseObjectEnumerator];
                
        // look for filter key in our keys.
        // if found move it to the start of the list
        for (NSString* filterKey in enumerator) {
            
            // this is slow but I don't really want to force
            // all the keys to lower case as the user may have
            // deliberateky used upper and lower case keys
            for (NSString *key in [keys copy]) {
                
                // if we find the filter key then move it to
                // to the start of the list
                if ([key caseInsensitiveCompare:filterKey] == NSOrderedSame) {
                    [keys removeObject:key];
                    [keys insertObject:key atIndex:0];
                    break;
                }
            }

        }
        
		// iterate over keys in sorted order
        // append to our output string
		for (__strong id key in keys) {
			
			//
			// apply dictionary filter to remove objects not to be displayed
			//
			if ([self filterObject:key filterKey:MGSDictFilterStyleName withStyle:styleDict]) {
				continue;
			}
				
			//
			// apply dictionary key filter to discard keys 
			//
			BOOL displayKey = ![self filterObject:key filterKey:MGSDictKeyFilterStyleName withStyle:styleDict];
			
			//
			// get object
			//
			id objectForKey = [(NSDictionary *)anObject objectForKey:key]; 
			
			//
			// apply formatting to key depending on object class
			//
			if (displayKey) {
				BOOL appendTerminatorToKey = NO;
					
				//
				// apply formatting to key depending on object class
				//
				if ([objectForKey isKindOfClass:[NSArray class]]) {
					appendTerminatorToKey = YES;
				} else if ([objectForKey isKindOfClass:[NSDictionary class]]) {
					appendTerminatorToKey = YES;
				}  else if ([objectForKey isKindOfClass:[NSString class]]) {
					
					NSString *objectString = objectForKey;
					
					// append terminator for longer strings
					if ([objectString mgs_occurrencesOfString:@"\n"] > 0) {
						appendTerminatorToKey = YES;
					}
					objectForKey = objectString;
				}
				
				// key description
				if (keySuffix && [key isKindOfClass:[NSString class]]) {
					key = [key stringByAppendingString:keySuffix];
				}
				
				// 
				// style the key
				//
				// form key style dict
				NSMutableDictionary *keyStyleDict = [styleDict mutableCopy];
				
				//
				// override computed attributes 
				//
				// TODO: move this out of the loop
				//
				NSMutableDictionary *attributes = [computedAttributes mutableCopy];
				[attributes addEntriesFromDictionary:[styleDict objectForKey:MGSDictKeyAttributesStyleName]];	
				[attributes addEntriesFromDictionary:inlineAttributes];
				[keyStyleDict setObject:attributes forKey:MGSComputedAttributesStyleName];
				
				[keyStyleDict setObject:[NSNumber numberWithBool:appendTerminatorToKey] forKey:MGSAppendTerminatorStyleName];
			

				// style it
				NSAttributedString *keyDesc = [self object:key descriptionWithStyle:keyStyleDict];
				[mString appendAttributedString:keyDesc];
			}
			
			//
			// style the object
			//
			// TODO: move this out of the loop
			//
			NSMutableDictionary *objectStyleDict = [styleDict mutableCopy];
			
			// override computed attributes 
			NSMutableDictionary *attributes = [computedAttributes mutableCopy];
			[attributes addEntriesFromDictionary:[styleDict objectForKey:MGSDictObjectAttributesStyleName]];	
			[attributes addEntriesFromDictionary:inlineAttributes];
			[objectStyleDict setObject:attributes forKey:MGSComputedAttributesStyleName];
			
            // get string representation of our object
			NSAttributedString *valueDesc = [self object:objectForKey descriptionWithStyle:objectStyleDict];
            
            // append to our result string
			[mString appendAttributedString:valueDesc];
		}
	}
	//
	// default - style as string representation 
	//
	else  {

		// get string rep
		NSString *outputString = [anObject description];
		
		// append terminator.
		// background colour will extend to edge of NSTextView if trailing \n is included in the formatting
		NSNumber *appendTerminator = [styleDict objectForKey:MGSAppendTerminatorStyleName];
		if (appendTerminator && [appendTerminator boolValue]) {
			outputString = [outputString stringByAppendingString:[styleDict objectForKey:MGSTerminatorStyleName]];
		}
		
		NSMutableDictionary *appliedAttributes = [defaultAttributes mutableCopy];
		[appliedAttributes addEntriesFromDictionary:computedAttributes];
		
		// apply string styling attributes.
		// note that this is the only place in the method where attributes are set.
		mString = [[NSMutableAttributedString alloc] initWithString:outputString attributes:appliedAttributes];
	}
	
	return mString;
}

/*
 
 - incrementStyleLevel:
 
 */
- (void)incrementStyleLevel:(NSMutableDictionary *)styleDict
{
	NSInteger level = 0;
	NSNumber *levelNumber = [styleDict objectForKey:MGSLevelStyleName];
	
	// get current level and increment
	if (levelNumber) {
		level = [levelNumber integerValue];
		level++;
	}
	
	// increment
	[styleDict setObject:[NSNumber numberWithInteger:level] forKey:MGSLevelStyleName];
	
}
/*
 
 - descriptionWithStyle:
 
 */
- (NSAttributedString *)descriptionWithStyle:(NSDictionary *)inputStyleDict
{
	return [self object:targetObject descriptionWithStyle:inputStyleDict];
}

/*
 
 - filterObject:filterKey:withStyle:
 
 */
- (BOOL)filterObject:(id)anObject filterKey:(NSString *)filterKeyName withStyle:(NSDictionary *)styleDict
{
	BOOL filterMatched = NO;

	// get the filter
	NSDictionary *filterDict = [styleDict objectForKey:filterKeyName];
	if (!filterDict) {
		return filterMatched;
	}
	
	// validate filter key
	if (![filterKeyName isKindOfClass:[NSString class]]) {
		return filterMatched;
	}
	
	// get the current styling level
	NSInteger level = [[styleDict objectForKey:MGSLevelStyleName] integerValue];

	// get keys to filter on
	NSArray *filterKeys = [filterDict objectForKey:MGSStyleFilter];
	
	// get the level at which to apply the filter
	NSNumber *filterLevelNumber = [filterDict objectForKey:MGSStyleLevel];
	NSInteger filterLevel = -1;	// filter at all levels
	if (filterLevelNumber) {
		filterLevel = [filterLevelNumber integerValue];	// filter level
	}
	
	if ((level == filterLevel || filterLevel == -1)) {
				
		// apply filter
		for (NSString *filterItem in filterKeys) {
			if ([(NSString *)anObject caseInsensitiveCompare:filterItem] == NSOrderedSame) {
				filterMatched = YES;
				break;
			}
		}
		
	}
	
	return filterMatched;
}

/*
 
 - attributePointSize:
 
 */

+ (CGFloat)attributePointSize:(NSString *)attr existingPointSize:(CGFloat)existingPointSize
{
	NSScanner *attrScanner = [NSScanner scannerWithString:attr];
	CGFloat pointSize = -1.0f;
	
	// increment font size
	float attrValue = 0;
	if ([attr rangeOfString:@"pt" options:NSBackwardsSearch].location != NSNotFound) {
		if ([attrScanner scanFloat:&attrValue] ) {
			pointSize = (CGFloat)attrValue;
		}
	} else if ([attr rangeOfString:@"px" options:NSBackwardsSearch].location != NSNotFound) {
		if ([attrScanner scanFloat:&attrValue] ) {
			pointSize = (CGFloat)attrValue * 12.f / 16.f;	// approx
		}
	} else if ([attr rangeOfString:@"em" options:NSBackwardsSearch].location != NSNotFound) {
		if ([attrScanner scanFloat:&attrValue] ) {
			pointSize = (CGFloat)attrValue * 12.f;	// approx
		}
	} else if ([attr rangeOfString:@"%" options:NSBackwardsSearch].location != NSNotFound) {
		if ([attrScanner scanFloat:&attrValue] ) {
			pointSize = (CGFloat)attrValue / 100.f * existingPointSize;
		}
	} 
	
	return pointSize;

}
/*
 
  the following this is GPL

	an alternative might be to create a HTML doc containing the CSS.
	this can then be imported as BSAttributedString
*/
/*
 
 http://source.colloquy.info/svn/trunk/Additions/NSAttributedStringMoreAdditions.m
 
 // Created by Graham Booker for Fire.
 // Changes by Timothy Hatcher for Colloquy.
 // Copyright Graham Booker and Timothy Hatcher. All rights reserved.
 
 */
static void setItalicOrObliqueFont( NSMutableDictionary *attrs ) {
	NSFontManager *fm = [NSFontManager sharedFontManager];
	NSFont *font = [attrs objectForKey:NSFontAttributeName];
	if( ! font ) font = [NSFont userFontOfSize:12];
	if( ! ( [fm traitsOfFont:font] & NSItalicFontMask ) ) {
		NSFont *newFont = [fm convertFont:font toHaveTrait:NSItalicFontMask];
		if( newFont == font ) {
			// font couldn't be made italic
			[attrs setObject:[NSNumber numberWithFloat:JVItalicObliquenessValue] forKey:NSObliquenessAttributeName];
		} else {
			// We got an italic font
			[attrs setObject:newFont forKey:NSFontAttributeName];
			[attrs removeObjectForKey:NSObliquenessAttributeName];
		}
	}
}

static void removeItalicOrObliqueFont( NSMutableDictionary *attrs ) {
	NSFontManager *fm = [NSFontManager sharedFontManager];
	NSFont *font = [attrs objectForKey:NSFontAttributeName];
	if( ! font ) font = [NSFont userFontOfSize:12];
	if( [fm traitsOfFont:font] & NSItalicFontMask ) {
		font = [fm convertFont:font toNotHaveTrait:NSItalicFontMask];
		[attrs setObject:font forKey:NSFontAttributeName];
	}
	[attrs removeObjectForKey:NSObliquenessAttributeName];
}

static NSString *parseCSSStyleAttribute( NSString *style, NSMutableDictionary *currentAttributes ) {
	NSScanner *scanner = [NSScanner scannerWithString:style];
	NSMutableString *unhandledStyles = [NSMutableString string];
	
	while( ! [scanner isAtEnd] ) {
		NSString *prop = nil;
		NSString *attr = nil;
		BOOL handled = NO;
		
 		[scanner scanCharactersFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet] intoString:NULL];
		[scanner scanUpToString:@":" intoString:&prop];
		[scanner scanString:@":" intoString:NULL];
 		[scanner scanCharactersFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet] intoString:NULL];
		[scanner scanUpToString:@";" intoString:&attr];
		[scanner scanString:@";" intoString:NULL];
		
		if( ! [prop length] || ! [attr length] ) continue;
		
		if( [prop isEqualToString:@"color"] ) {
			NSColor *color = [NSColor mgs_colorWithCSSAttributeValue:attr];
			if( color ) {
				[currentAttributes setObject:color forKey:NSForegroundColorAttributeName];
				handled = YES;
			}
		} else if( [prop isEqualToString:@"background-color"] ) {
			NSColor *color = [NSColor mgs_colorWithCSSAttributeValue:attr];
			if( color ) {
				[currentAttributes setObject:color forKey:NSBackgroundColorAttributeName];
				handled = YES;
			}
		} else if( [prop isEqualToString:@"line-height"] ) {	// MGS added
			
			NSFont *existingFont = [currentAttributes objectForKey:NSFontAttributeName];
			
			// get attribute point size
			CGFloat newPointSize = [MGSObjectStyler attributePointSize:attr existingPointSize:[existingFont pointSize]];

			NSMutableParagraphStyle *paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
			[paragraphStyle setLineBreakMode:NSLineBreakByClipping];
			[paragraphStyle setMinimumLineHeight:newPointSize];
			[paragraphStyle setMaximumLineHeight:newPointSize];
			//[paragraphStyle setFirstLineHeadIndent:25];	// use these for indenting text
			//[paragraphStyle setHeadIndent:25];
			[currentAttributes setObject:paragraphStyle forKey:NSParagraphStyleAttributeName];
			
		} else if( [prop isEqualToString:@"font-size"] ) {	// MGS added
			/*
			 points to pivels and vice versa is devic dependent
			 
			 lookup table for points to pixels
			 http://reeddesign.co.uk/test/points-pixels.html
			 
			 assume 12pt equiv 16px
			 
			 */
			NSFont *existingFont = [currentAttributes objectForKey:NSFontAttributeName];
			if (existingFont) {
				
				CGFloat existingFontSize = [existingFont pointSize];
				
				// get attribute point size
				CGFloat newFontSize = [MGSObjectStyler attributePointSize:attr existingPointSize:existingFontSize];
				
				if (newFontSize > 0) { 
					handled = YES;

					if (fabsf(newFontSize - existingFontSize) > 0.1) {
						handled = NO;

						NSFont *font = [[NSFontManager sharedFontManager] convertFont:existingFont toSize:newFontSize];
						if( font ) {
							[currentAttributes setObject:font forKey:NSFontAttributeName];
							handled = YES;
						}
					}
				}
			}
			
		} else if( [prop isEqualToString:@"font-weight"] ) {
			if( [attr rangeOfString:@"bold"].location != NSNotFound || [attr intValue] >= 500 ) {
				NSFont *font = [[NSFontManager sharedFontManager] convertFont:[currentAttributes objectForKey:NSFontAttributeName] toHaveTrait:NSBoldFontMask];
				if( font ) {
					[currentAttributes setObject:font forKey:NSFontAttributeName];
					handled = YES;
				}
			} else {
				NSFont *font = [[NSFontManager sharedFontManager] convertFont:[currentAttributes objectForKey:NSFontAttributeName] toNotHaveTrait:NSBoldFontMask];
				if( font ) {
					[currentAttributes setObject:font forKey:NSFontAttributeName];
					handled = YES;
				}
			}
		} else if( [prop isEqualToString:@"font-style"] ) {
			if( [attr rangeOfString:@"italic"].location != NSNotFound ) {
				setItalicOrObliqueFont( currentAttributes );
				handled = YES;
			} else {
				removeItalicOrObliqueFont( currentAttributes );
				handled = YES;
			}
		} else if( [prop isEqualToString:@"font-variant"] ) {
			if( [attr rangeOfString:@"small-caps"].location != NSNotFound ) {
				NSFont *font = [[NSFontManager sharedFontManager] convertFont:[currentAttributes objectForKey:NSFontAttributeName] toHaveTrait:NSSmallCapsFontMask];
				if( font ) {
					[currentAttributes setObject:font forKey:NSFontAttributeName];
					handled = YES;
				}
			} else {
				NSFont *font = [[NSFontManager sharedFontManager] convertFont:[currentAttributes objectForKey:NSFontAttributeName] toNotHaveTrait:NSSmallCapsFontMask];
				if( font ) {
					[currentAttributes setObject:font forKey:NSFontAttributeName];
					handled = YES;
				}
			}
		} else if( [prop isEqualToString:@"font-stretch"] ) {
			if( [attr rangeOfString:@"normal"].location != NSNotFound ) {
				NSFont *font = [[NSFontManager sharedFontManager] convertFont:[currentAttributes objectForKey:NSFontAttributeName] toNotHaveTrait:( NSCondensedFontMask | NSExpandedFontMask )];
				if( font ) {
					[currentAttributes setObject:font forKey:NSFontAttributeName];
					handled = YES;
				}
			} else if( [attr rangeOfString:@"condensed"].location != NSNotFound || [attr rangeOfString:@"narrower"].location != NSNotFound ) {
				NSFont *font = [[NSFontManager sharedFontManager] convertFont:[currentAttributes objectForKey:NSFontAttributeName] toHaveTrait:NSCondensedFontMask];
				if( font ) {
					[currentAttributes setObject:font forKey:NSFontAttributeName];
					handled = YES;
				}
			} else {
				NSFont *font = [[NSFontManager sharedFontManager] convertFont:[currentAttributes objectForKey:NSFontAttributeName] toHaveTrait:NSExpandedFontMask];
				if( font ) {
					[currentAttributes setObject:font forKey:NSFontAttributeName];
					handled = YES;
				}
			}
		} else if( [prop isEqualToString:@"text-decoration"] ) {
			if( [attr rangeOfString:@"underline"].location != NSNotFound ) {
				[currentAttributes setObject:[NSNumber numberWithUnsignedLong:1] forKey:NSUnderlineStyleAttributeName];
				handled = YES;
			} else {
				[currentAttributes removeObjectForKey:NSUnderlineStyleAttributeName];
				handled = YES;
			}
		}
		
		if( ! handled ) {
			if( [unhandledStyles length] ) [unhandledStyles appendString:@";"];
			[unhandledStyles appendFormat:@"%@: %@", prop, attr];
		}
		
 		[scanner scanCharactersFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet] intoString:NULL];
	}
	
	if ([unhandledStyles length] > 0) {
		NSLog(@"Unhandled styles: %@", unhandledStyles);
	}
	
	return ( [unhandledStyles length] ? unhandledStyles : nil );
}

@end
