//
//	Main Control
//

#import "MandelControl.h"
#import "MandelColor.h"

#define NPLACES	10

// copied from original (NeXT) Mandelbrot
plc place_array[NPLACES] = {
    {-0.6000000000, 0.0010000000, 3.00000000000, 250},	// Home
    {-0.7099639773, 0.2697646400, 0.00227100006, 300},	// Black Hole
    {-0.7803739905, 0.2476640045, 0.36448600888, 250},	// Valley of Fear
    {-0.7258710265, 0.2510699927, 0.00454200012, 250},	// Ginger Bread Man
    {-0.1982370018, 1.1002370119, 0.00717600015, 250},	// Electric Porcupine
    {-0.7334700226, 0.2135519981, 0.02999999932, 250},	// Sea Horse
    {-0.7285389900, 0.2235859930, 0.00011500000, 250},	// Party
    {-0.6682249903, 0.4672900140, 0.12149500101, 250},	// Starfish
    {-0.8740490078, 0.2552669942, 0.00050000002, 250},	// Yin Yang
    {-0.9166089892, 0.3149220049, 0.00087400001, 250}	// Jewel
};

@implementation Place

- (id)init
{
	self = [super init];
	return self;
}

- (id)copyWithZone:(NSZone *)zone
{
	Place	*pl = [[Place alloc] init];
	pl.xc = xc;
	pl.yc = yc;
	pl.xs = xs;
	pl.depth = depth;

	return pl;
}

- (void)setXc:(double)xcVal
{
	xc = xcVal;
}

- (void)setYc:(double)ycVal
{
	yc = ycVal;
}

- (void)setXs:(double)xsVal
{
	xs = xsVal;
}

- (void)setDepth:(int)dpVal
{
	depth = dpVal;
}

- (double)xc
{
	return xc;
}

- (double)yc
{
	return yc;
}

- (double)xs
{
	return xs;
}

- (int)depth
{
	return depth;
}

@end

@implementation MandelControl

- (id)init
{
	NSMutableArray	*tmpArray = [NSMutableArray array];
	Place			*pl;
	int				i;

    self = [super init];
    if (!self) return nil;

	for (i = 0; i < NPLACES; i++) {
		pl = [[Place alloc] init];
		[pl setXc:place_array[i].xc];
		[pl setYc:place_array[i].yc];
		[pl setXs:place_array[i].xs];
		[pl setDepth:place_array[i].depth];
		[tmpArray addObject:pl];
	}
	presets = [NSArray arrayWithArray:tmpArray];
	history = [NSMutableArray array];
	[history addObject:[presets objectAtIndex:0]];
	current = 0;

    return self;
}

- (Place *)currentPlace
{
	return [history objectAtIndex:current];
}

- (void)updatePlaceText
{
	Place *pl = [history objectAtIndex:current];

	if (current == 0) {
		[leftButton setEnabled:NO];
	} else {
		[leftButton setEnabled:YES];
	}
	if (current == [history count] -1) {
		[rightButton setEnabled:NO];
	} else {
		[rightButton setEnabled:YES];
	}

// debug
[currentIndex setIntValue:current];
[totalInHistory setIntValue:[history count]];

	[xcField setDoubleValue:pl.xc];
	[xcField display];

	[ycField setDoubleValue:pl.yc];
	[ycField display];

	[xsField setDoubleValue:pl.xs];
	[xsField display];

	[depthButton selectItemWithTag:pl.depth];
	[depthButton display];
}

- (IBAction)textChanged:(id)sender
{
	Place	*pl = [[Place alloc] init];

	pl.xc = [xcField doubleValue];
	pl.yc = [ycField doubleValue];
	pl.xs = [xsField doubleValue];
	pl.depth = [[depthButton selectedItem] tag];

// truncate/append history
	[self truncateHistory];
	[history addObject:pl];
	current = [history count] - 1;

// display
	[self updatePlaceText];
	[view start];
}

- (void)clearHistory
{
	[history removeAllObjects];
	current = -1;
}

- (void)truncateHistory
{
	int		st = current + 1;
	int		len = [history count];

	if (len > st) {
		len -= st;
		[history removeObjectsInRange:NSMakeRange(st, len)];
	}
}

- (IBAction)back:(id)sender
{
	if (current > 0) {
		current -= 1;
		[self updatePlaceText];
		[view start];
	}
}

- (IBAction)next:(id)sender
{
	if (current < [history count] - 1) {
		current += 1;
		[self updatePlaceText];
		[view start];
	}
}

- (IBAction)gotoPlace:(id)sender
{
	int		ix = [[places selectedCell] tag];

	[self clearHistory]; // emulating new position.
	[history addObject:[presets objectAtIndex:ix]];
	current = 0;
	[self updatePlaceText];
	[view start];
}

- (IBAction)colorChanged:(id)sender
{
    int ptn;
    
    ptn = [[sender selectedCell] tag];
    [colorControl setColorPattern:ptn];
    [colorButton selectItemWithTag:ptn];
}

- (void)updatePlaceWithRect:(NSRect)rect
{
    double	current_ys;
    double	x0, y0, xc, yc, xs;
    double	factor, fx, fy;
    double	ratio;
    NSRect	bb = [view bounds];
	Place	*pl = [history objectAtIndex:current];
	Place	*newPl;

// calc new place
    ratio = bb.size.height / bb.size.width;
    current_ys = pl.xs * ratio;
    fx = rect.size.width / bb.size.width;
    fy = rect.size.height / bb.size.height;
    factor = MAX(fx, fy);
    xs = pl.xs*factor;
    x0 = pl.xc - pl.xs/2;
    y0 = pl.yc - current_ys/2;

    xc = x0 + pl.xs * rect.origin.x / bb.size.width + pl.xs*fx/2;
    yc = y0 + current_ys * rect.origin.y / bb.size.height + current_ys*fy/2;

// update place
	newPl = [pl copy];
	newPl.xc = xc;
	newPl.yc = yc;
	newPl.xs = xs;

// truncate and append history
	[self truncateHistory];
	[history addObject:newPl];
	current = [history count] - 1;

	[self updatePlaceText];
	[view start];
}

- (void)awakeFromNib
{
	[colorControl updateLUT];
	[self updatePlaceText];
	[view start];
}       

@end
