//
//	Main Control
//

#import <Cocoa/Cocoa.h>
#import "MandelView.h"

typedef struct plc {
    double	xc, yc;
    double	xs;
    int		depth;
} plc;

@interface Place : NSObject
{
    double	xc;
	double	yc;
    double	xs;
    int		depth;	// -> tag
}

- (id)init;
- (id)copyWithZone:(NSZone *)zone;
- (void)setXc:(double)xc;
- (void)setYc:(double)yc;
- (void)setXs:(double)xs;
- (void)setDepth:(int)dp;
- (double)xc;
- (double)yc;
- (double)xs;
- (int)depth;

@end

@interface MandelControl : NSObject
{
    IBOutlet id				view;
	IBOutlet id				window;
    IBOutlet id				colorControl;
    IBOutlet id				places;
	IBOutlet NSPopUpButton	*depthButton;
    IBOutlet NSTextField	*xcField;
    IBOutlet NSTextField	*ycField;
    IBOutlet NSTextField	*xsField;
	IBOutlet NSButton		*leftButton;
	IBOutlet NSButton		*rightButton;
	IBOutlet NSTextField	*currentIndex;		// for debugging
	IBOutlet NSTextField	*totalInHistory;	// for debugging
	int						current;
	NSMutableArray			*history;
	NSArray					*presets;
}

- (id)init;

- (Place *)currentPlace;
- (IBAction)gotoPlace:(id)sender;
- (void)updatePlaceText;
- (void)clearHistory;
- (void)updatePlaceWithRect:(NSRect)rect;
- (void)truncateHistory;
- (IBAction)textChanged:(id)sender;
- (IBAction)back:(id)sender;
- (IBAction)next:(id)sender;

@end
