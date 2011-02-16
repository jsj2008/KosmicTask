/*
 *  GlossyGradient.c
 *  KosmicQuitter
 *
 *  Created by Jonathan on 04/01/2009.
 *  Copyright 2009 mugginsoft.com. All rights reserved.
 *
 */

#include "GlossyGradient.h"

typedef struct
	{
		float color[4];
		float caustic[4];
		float expCoefficient;
		float expScale;
		float expOffset;
		float initialWhite;
		float finalWhite;
	} GlossParameters;

//
// see http://cocoawithlove.com/2008/09/drawing-gloss-gradients-in-coregraphics.html
//
float perceptualGlossFractionForColor(float *inputComponents)
{
    const float REFLECTION_SCALE_NUMBER = 0.2f;
    const float NTSC_RED_FRACTION = 0.299f;
    const float NTSC_GREEN_FRACTION = 0.587f;
    const float NTSC_BLUE_FRACTION = 0.114f;
	
    float glossScale =
	NTSC_RED_FRACTION * inputComponents[0] +
	NTSC_GREEN_FRACTION * inputComponents[1] +
	NTSC_BLUE_FRACTION * inputComponents[2];
    glossScale = (float)pow(glossScale, REFLECTION_SCALE_NUMBER);
    return glossScale;
}
void perceptualCausticColorForColor(float *inputComponents, float *outputComponents)
{
    const float CAUSTIC_FRACTION = 0.60f;
    const float COSINE_ANGLE_SCALE = 1.4f;
    const float MIN_RED_THRESHOLD = 0.95f;
    const float MAX_BLUE_THRESHOLD = 0.7f;
    const float GRAYSCALE_CAUSTIC_SATURATION = 0.2f;
    
    NSColor *source =
	[NSColor
	 colorWithCalibratedRed:inputComponents[0]
	 green:inputComponents[1]
	 blue:inputComponents[2]
	 alpha:inputComponents[3]];
	
    float hue, saturation, brightness, alpha;
    [source getHue:&hue saturation:&saturation brightness:&brightness alpha:&alpha];
	
    float targetHue, targetSaturation, targetBrightness;
    [[NSColor yellowColor] getHue:&targetHue saturation:&targetSaturation brightness:&targetBrightness alpha:&alpha];
    
    if (saturation < 1e-3)
    {
        hue = targetHue;
        saturation = GRAYSCALE_CAUSTIC_SATURATION;
    }
	
    if (hue > MIN_RED_THRESHOLD)
    {
        hue -= 1.0f;
    }
    else if (hue > MAX_BLUE_THRESHOLD)
    {
        [[NSColor magentaColor] getHue:&targetHue saturation:&targetSaturation brightness:&targetBrightness alpha:&alpha];
    }
	
    float scaledCaustic = CAUSTIC_FRACTION * 0.5f * (1.0f + (float)cos(COSINE_ANGLE_SCALE * M_PI * (hue - targetHue)));
	
    NSColor *targetColor =
	[NSColor
	 colorWithCalibratedHue:hue * (1.0f - scaledCaustic) + targetHue * scaledCaustic
	 saturation:saturation
	 brightness:brightness * (1.0f - scaledCaustic) + targetBrightness * scaledCaustic
	 alpha:inputComponents[3]];
    [targetColor getComponents:outputComponents];
}

static void glossInterpolation(void *info, const float *input,
							   float *output)
{
    GlossParameters *params = (GlossParameters *)info;
	
    float progress = *input;
    if (progress < 0.5)
    {
        progress = progress * 2.0f;
		
        progress =
		1.0f - params->expScale * (expf(progress * -params->expCoefficient) - params->expOffset);
		
        float currentWhite = progress * (params->finalWhite - params->initialWhite) + params->initialWhite;
        
        output[0] = params->color[0] * (1.0f - currentWhite) + currentWhite;
        output[1] = params->color[1] * (1.0f - currentWhite) + currentWhite;
        output[2] = params->color[2] * (1.0f - currentWhite) + currentWhite;
        output[3] = params->color[3] * (1.0f - currentWhite) + currentWhite;
    }
    else
    {
        progress = (progress - 0.5f) * 2.0f;
		
        progress = params->expScale *
		(expf((1.0f - progress) * -params->expCoefficient) - params->expOffset);
		
        output[0] = params->color[0] * (1.0f - progress) + params->caustic[0] * progress;
        output[1] = params->color[1] * (1.0f - progress) + params->caustic[1] * progress;
        output[2] = params->color[2] * (1.0f - progress) + params->caustic[2] * progress;
        output[3] = params->color[3] * (1.0f - progress) + params->caustic[3] * progress;
    }
}

void DrawGlossGradient(CGContextRef context, NSColor *color, NSRect inRect)
{
    const float EXP_COEFFICIENT = 1.2f;
    const float REFLECTION_MAX = 0.60f;
    const float REFLECTION_MIN = 0.20f;
    
    GlossParameters params;
    
    params.expCoefficient = EXP_COEFFICIENT;
    params.expOffset = expf(-params.expCoefficient);
    params.expScale = 1.0f / (1.0f - params.expOffset);
	
    NSColor *source =
	[color colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
    [source getComponents:params.color];
    if ([source numberOfComponents] == 3)
    {
        params.color[3] = 1.0f;
    }
    
    perceptualCausticColorForColor(params.color, params.caustic);
    
    float glossScale = perceptualGlossFractionForColor(params.color);
	
    params.initialWhite = glossScale * REFLECTION_MAX;
    params.finalWhite = glossScale * REFLECTION_MIN;
	
    static const float input_value_range[2] = {0, 1};
    static const float output_value_ranges[8] = {0, 1, 0, 1, 0, 1, 0, 1};
    CGFunctionCallbacks callbacks = {0, glossInterpolation, NULL};
    
    CGFunctionRef gradientFunction = CGFunctionCreate(
													  (void *)&params,
													  1, // number of input values to the callback
													  input_value_range,
													  4, // number of components (r, g, b, a)
													  output_value_ranges,
													  &callbacks);
    
    CGPoint startPoint = CGPointMake(NSMinX(inRect), NSMaxY(inRect));
    CGPoint endPoint = CGPointMake(NSMinX(inRect), NSMinY(inRect));
	
    CGColorSpaceRef colorspace = CGColorSpaceCreateDeviceRGB();
    CGShadingRef shading = CGShadingCreateAxial(colorspace, startPoint,
												endPoint, gradientFunction, FALSE, FALSE);
    
    CGContextSaveGState(context);
    CGContextClipToRect(context, NSRectToCGRect(inRect));
    CGContextDrawShading(context, shading);
    CGContextRestoreGState(context);
    
    CGShadingRelease(shading);
    CGColorSpaceRelease(colorspace);
    CGFunctionRelease(gradientFunction);
}
