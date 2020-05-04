//
//	Main View
//	Mandelbrot set calc is done here
//

#import "MandelView.h"
#import "MandelControl.h"
#import "MandelColor.h"

// z(n+1) = z(n)^2 + c (c = x + iy)
// z(0) = 0
int
mandel(double x, double y, int depth)
{
	double	u, v, u2, v2;
	int		i, col;

	u = v = 0;	// z0 = u + iv = 0
	for (i = 0; i < depth; i++) {
		u2 = u * u;
		v2 = v * v;
		if (u2 + v2 > 4.0) break;
		v = 2 * u * v + y;
		u = u2 - v2 + x;
	}
	col = i * (TAB_SIZE - 1) / depth;

	return col;
}

@implementation MandelView

int calc_mode = 1;	// 0: Single thread, 1: Multithread using NSOperation

- (void)reallocBitmap
{
    NSRect			bb = [self bounds];
    unsigned char 	*conversion_tmp[5] = {NULL};
	int				i;

    xdim = bb.size.width;
    ydim = bb.size.height;

//	if (image) [image release];
    image = [[NSBitmapImageRep alloc]
        initWithBitmapDataPlanes:&conversion_tmp[0]
            pixelsWide:xdim
            pixelsHigh:ydim
            bitsPerSample:8
            samplesPerPixel:3
            hasAlpha:NO
            isPlanar:NO
            colorSpaceName:NSDeviceRGBColorSpace
            bytesPerRow:xdim * 3
            bitsPerPixel:24];
//    data = [image bitmapData];
	if (data8) free(data8);
    data8 = (int *)malloc(sizeof(int) * xdim * ydim);
	for (i = 0; i < xdim * ydim; i++) {
		data8[i] = TAB_SIZE - 1;
	}
}

- (id)initWithFrame:(NSRect)frameRect
{
    self = [super initWithFrame:frameRect];
    if (!self) return nil;

    cursorOn = NO;
    cursorRect = NSZeroRect;
	[self reallocBitmap];

    return self;
}

- (void)drawRect:(NSRect)rect
{
    BOOL    sts;
    int		i, j;
    int		col;
    unsigned char   *r, *g, *b;
    unsigned char   *data = [image bitmapData];

    r = [colorControl red];
    g = [colorControl green];
    b = [colorControl blue];

    for (i = 0, j = 0; i < xdim * ydim; i++) {
        col = data8[i];
        data[j++] = r[col];
        data[j++] = g[col];
        data[j++] = b[col];
    }
    sts = [image drawInRect:rect];

    // draw cursor
    if (cursorOn) {
        [[NSColor whiteColor] set];
        NSFrameRect(cursorRect);    // draw box without anti-aliasing
    }
}

- (void)start
{
[[self window] discardCachedImage];
	place = [control currentPlace];
	switch (calc_mode) {
	case	0 :
		[self mandelCalc];		// single-thread
		break;
	case 1 :
		[self mandelCalcOP];	// multi-thread
		break;
	}
}

// Mandelbrot set calc, result is set to data8[] (index into 8bit color map)
- (void)mandelCalc
{
	NSRect		bb = [self bounds];
	double		ratio = bb.size.height / bb.size.width;
    int			i, j, k;
	double		xc, yc, xs, ys;
	int			depth;
    double		x, y;
    int			col;

	depth = [place depth];
	xc = [place xc];
	xs = [place xs];
	yc = [place yc];
	ys = xs * ratio;
	
	for (i = 0; i < ydim; i++) {
		y = (0.5 - (double)i/ydim)*ys + yc;
		for (j = 0; j < xdim; j++) {
			// for each pixel
			x = ((double)j/xdim - 0.5)*xs + xc;
			// =======
			col = mandel(x, y, depth);
			// =======
			k = i * xdim + j;
			data8[k] = col;		// output
		}
		if (i % 50 == 0) [self display];	// update screen after every 50 lines
	}
// display remaining lines
    [self display];
}

//
// NSOperation version
//
- (void)mandelCalcOP
{
	NSOperationQueue	*queue = [[NSOperationQueue alloc] init];
	MandelOp			*op;
//	int					nCore = [[NSProcessInfo processInfo] processorCount];
	int					nThread;
	int					linesPerBatch, nBatch;
	int					i, batch;
	int					st, len;

	nThread = 20;
	len = 2;
	linesPerBatch = len * nThread;
	nBatch = ceil((float)ydim / linesPerBatch);

	for (batch = 0; batch < nBatch; batch++) {
		for (i = 0; i < nThread; i++) {
			st = batch * linesPerBatch + i * len;
			op = [MandelOp opWithData:data8 start:st len:len place:place bounds:[self bounds]];
			[queue addOperation:op];
		}
		[queue waitUntilAllOperationsAreFinished];
        [self display];
	}
}

// rewrite below... display reflesh timing changed somewhere after 10.11
- (void)mouseDown:(NSEvent *)e
{
	NSRect  rect;   // result
	BOOL	cache_valid = NO;
	NSPoint startPoint, currPoint;

	// drag select rect
	startPoint = [e locationInWindow];
	startPoint = [self convertPoint:startPoint fromView:nil];
    rect = NSMakeRect(startPoint.x, startPoint.y, 0.0, 0.0);
 
    for (;;) {
        e = [[self window] nextEventMatchingMask:
            NSLeftMouseUpMask | NSLeftMouseDraggedMask];
        if ([e type] == NSLeftMouseUp) break;
        currPoint = [self convertPoint:[e locationInWindow] fromView:nil];

        rect.size.width = fabs(currPoint.x - startPoint.x);
        rect.size.height = fabs(currPoint.y - startPoint.y);
        rect.origin.x = MIN(currPoint.x, startPoint.x);
        rect.origin.y = MIN(currPoint.y, startPoint.y);
        if (rect.size.height == 0 || rect.size.width == 0) continue;

        cursorOn = YES;
        cursorRect = rect;
        [self display];
    }
    // rect selected
    cursorOn = NO;

    if ((rect.size.width > 0) && (rect.size.height > 0)) {
		[control updatePlaceWithRect:rect];
    }
}

- (void)copy:(id)sender
{
	NSPasteboard	*pb;
	NSData			*pbData;

	pb = [NSPasteboard generalPasteboard]; // existing pb
	[pb declareTypes:[NSArray arrayWithObjects:
                NSPDFPboardType,
                NSTIFFPboardType,
				nil] owner:nil];
	// PDF (for Cocoa)
	[self writePDFInsideRect:[self bounds] toPasteboard:pb];
	// TIFF (for Classic/Carbon)
	pbData = [image TIFFRepresentation];
	[pb setData:pbData forType:NSTIFFPboardType];
}

- (BOOL)isOpaque
{
	return YES;
}

- (BOOL)acceptsFirstResponder
{
	return YES;
}

- (BOOL)resignFirstResponder
{
	[self setNeedsDisplay:YES];
	return YES;
}

- (void)viewDidEndLiveResize
{
	[self reallocBitmap];
	[self start];
}

- (void)windowDidResize:(NSNotification *)notification
{
	if (![self inLiveResize]) {
		[self reallocBitmap];
		[self start];
	}
}


@end

//
//	NSOperation
//
@implementation MandelOp

+ (id)opWithData:(int *)data start:(int)st len:(int)len place:(Place *)pl bounds:(NSRect)bb
{
	MandelOp		*op;
	op = [[[MandelOp alloc] init]
        initWithData:data start:st len:len place:pl bounds:bb];
	return op;
}

- (id)initWithData:(int *)data start:(int)st len:(int)len place:(Place *)pl bounds:(NSRect)bb
{
	data8 = data;
	yStart = st;
	length = len;
	place = pl;
	bounds = bb;
	return self;
}

- (void)main
{
    int			i, j, k, line;
	double		xc, yc, xs, ys, ratio;
    double		x, y;
	int			xdim, ydim, depth;
    int			col;

	ratio = bounds.size.height / bounds.size.width;
	depth = [place depth];
	xc = [place xc];
	xs = [place xs];
	yc = [place yc];
	ys = xs * ratio;
    xdim = bounds.size.width;
    ydim = bounds.size.height;
	
	for (line = 0; line < length; line++) {
		i = yStart + line;
		if (i >= ydim) break;
		y = (0.5 - (double)i/ydim)*ys + yc;
		for (j = 0; j < xdim; j++) {
			// for each pixel
			x = ((double)j/xdim - 0.5)*xs + xc;
			// =======
			col = mandel(x, y, depth);
			// =======
			k = i * xdim + j;
			data8[k] = col;
		}
	}
}

@end
