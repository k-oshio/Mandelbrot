//
//	Color Control
//

#import "MandelColor.h"
#import "MandelControl.h"

// color tabs are same as original NeXT version
// but origin for phase change is set to max index, not 0
ColorParam	cp_array[] = {
//	R: 	f     p      c		G: f    p      c		B: f     p      c
	{{3.0,    0.5,   0.4},	{5.0,   0.5,   0.4},	{1.0,   0.87,  0.87}},	// storms
	{{5.0,    0.5,   0.5},	{5.0,   0.5,   0.5},	{5.0,   0.5,   0.5}},	// zebra
	{{0.66,   0.514, 0.46},	{2.1,   0.436, 0.8}, 	{2.0,   0.576, 0.5}},	// oasis
	{{0.5,    0.5,   0.88},	{1.5,   0.5,   0.5},	{0.5,   0.5,   0.1}},	// arctic
	{{3.0,    0.5,   0.73},	{3.0,   0.74,  0.87},	{1.1,   0.43,  0.54}},	// gothic
	{{1.0,    0.5,   0.46},	{5.0,   0.5,   0.8},	{3.0,   0.5,   0.5}},	// deco
	{{0.5,    0.5,   0.5},	{0.5,   0.5,   0.5},	{0.5,   0.5,   0.5}}	// linear
};

@implementation MandelColor

- (id)init
{
    self = [super init];
    if (!self) return nil;

    rtab = (unsigned char *)malloc(TAB_SIZE);
    gtab = (unsigned char *)malloc(TAB_SIZE);
    btab = (unsigned char *)malloc(TAB_SIZE);
    channel = 0;	// red
	pattern = 0;	// storm
	cparam = cp_array[0];

    return self;
}

- (void)awakeFromNib
{
	NSNumberFormatter	*formatter = [[NSNumberFormatter alloc] init];

	[formatter setFormat:@"0.##;0;-0.##"];
    [[paramField cellAtIndex:0] setFormatter:formatter];
    [[paramField cellAtIndex:1] setFormatter:formatter];
    [[paramField cellAtIndex:2] setFormatter:formatter];
}

- (void)patternChanged:(id)sender
{
	pattern = [[sender selectedCell] tag];
    [self setColorPattern:pattern];
    [control colorChanged:sender];
}

- (void)setColorPattern:(int)pt
{
    int    i;
    cparam = cp_array[pt];
    [self channelChanged:self];    // update sliders
    for (i = 0; i < 3; i++) { // rgb
        [self makeLUTforChannel:i];
    }
    [colorView display];
    [mainView display];
    [patternSelector selectItemWithTag:pt];
}

- (void)channelChanged:(id)sender
{
    float				f, p, c;

    channel = [[chSelector selectedCell] tag];
    switch (channel) {
	case 0:	// red
	default :
		f = cparam.r.freq;
		p = cparam.r.phase;
		c = cparam.r.contrast;
		break;
	case 1:	// green
		f = cparam.g.freq;
		p = cparam.g.phase;
		c = cparam.g.contrast;
		break;
	case 2:	// blue
		f = cparam.b.freq;
		p = cparam.b.phase;
		c = cparam.b.contrast;
		break;
    }

    [[paramSlider cellWithTag:0] setFloatValue:f];
    [[paramSlider cellWithTag:1] setFloatValue:p];
    [[paramSlider cellWithTag:2] setFloatValue:c];

    [[paramField cellAtIndex:0] setFloatValue:f];
    [[paramField cellAtIndex:1] setFloatValue:p];
    [[paramField cellAtIndex:2] setFloatValue:c];
}

- (void)changeParam:(int)tag atChanel:(int)ch toVal:(float)val
{
    switch(tag) {
	case 0:	// freq
		switch (ch) {
		case 0: // red
			cparam.r.freq = val;
			break;
		case 1: // green
			cparam.g.freq = val;
			break;
		case 2: // blue
			cparam.b.freq = val;
			break;
		}
		break;
	case 1:	// phase
		switch (ch) {
		case 0: // red
			cparam.r.phase = val;
			break;
		case 1: // green
			cparam.g.phase = val;
			break;
		case 2: // blue
			cparam.b.phase = val;
			break;
		}
		break;
	case 2:	// contrast
		switch (ch) {
		case 0: // red
			cparam.r.contrast = val;
			break;
		case 1: // green
			cparam.g.contrast = val;
			break;
		case 2: // blue
			cparam.b.contrast = val;
			break;
		}
		break;
    }
}
- (void)sliderMoved:(id)sender
{
    id		sld = [sender selectedCell];
    int		tag = [sld tag];
    id		tf = [paramField cellAtIndex:tag];
    float	val;

    val = [sld floatValue];
    [tf setFloatValue:val];
    [self changeParam:tag atChanel:channel toVal:val];
    [self makeLUTforChannel:channel];
    [colorView display];
    [mainView display];
}

- (void)fieldSet:(id)sender
{
    id		tf = [sender selectedCell];
    int		tag = [tf tag];
    id		sld = [paramSlider cellWithTag:tag];
    float	val;

    val = [tf floatValue];
    [sld setFloatValue:val];
    [self changeParam:tag atChanel:channel toVal:val];
    [self makeLUTforChannel:channel];
    [colorView display];
    [mainView display];
}

- (void)apply:(id)sender
{
    [mainView display];
}

- (unsigned char *)red
{
    return rtab;
}

- (unsigned char *)green
{
    return gtab;
}

- (unsigned char *)blue
{
    return btab;
}

void
calc_col_tab(unsigned char *tab, int tab_size, float f, float p, float c)
{
    float	val;
    int		i;

    for (i = 0; i < tab_size; i++) {
        if (c == 0.0) {
            val = 255;
        } else
        if (c == 1.0) {
            val = 0;
        } else {
			val = cos((f * (i - tab_size) / tab_size + p) * 2 * M_PI);
			if (c > 0.5) {
				val = (4 - (1 - val) / (1 - c)) * 64;
			} else {
				val = (1 + val) / c * 64;
			}
		}
        if (val < 0) val = 0;
        if (val > 255) val = 255;
        tab[i] = val;
    }
}

- (void)makeLUTforChannel:(int)ch
{
    float	f, p, c;

    switch (ch) {
	case 0: // r
		f = cparam.r.freq;
		p = cparam.r.phase;
		c = cparam.r.contrast;
		calc_col_tab(rtab, TAB_SIZE, f, p, c);
		break;
	case 1: // g
		f = cparam.g.freq;
		p = cparam.g.phase;
		c = cparam.g.contrast;
		calc_col_tab(gtab, TAB_SIZE, f, p, c);
		break;
	case 2: // b
		f = cparam.b.freq;
		p = cparam.b.phase;
		c = cparam.b.contrast;
		calc_col_tab(btab, TAB_SIZE, f, p, c);
		break;
    }
}

- (void)updateLUT	// update all three
{
    [self makeLUTforChannel:0];
    [self makeLUTforChannel:1];
    [self makeLUTforChannel:2];
    [colorView display];
}

@end
