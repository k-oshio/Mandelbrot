//
//	Main View
//	Mandelbrot set calc is done here
//

#import <Cocoa/Cocoa.h>
//#import "MandelControl.h"
//#import "MandelColor.h"

@class Place, MandelControl, MandelColor;

@interface MandelView : NSView
{
    IBOutlet MandelControl  *control;
    IBOutlet MandelColor    *colorControl;
	// bitmap
    NSBitmapImageRep        *image;
    int                     xdim, ydim;
    int                     *data8;		// palette index plane
	Place                   *place;
    BOOL                    cursorOn;
    NSRect                  cursorRect;
}

- (void)start;
- (void)mandelCalc;		// single-thread
- (void)mandelCalcOP;	// multi-thread version

@end

// mandelCalcOP
@interface MandelOp : NSOperation
{
	//	param
	Place				*place;
	NSRect				bounds;
	// in/out
	int					yStart;
	int					length;
	int					*data8;
}

+ (id)opWithData:(int *)data start:(int)st len:(int)len place:(Place *)pl bounds:(NSRect)bb;
- (id)initWithData:(int *)data start:(int)st len:(int)len place:(Place *)pl bounds:(NSRect)bb;
- (void)main;

@end

