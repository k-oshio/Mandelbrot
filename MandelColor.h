//
//	Color Control
//

#import <Cocoa/Cocoa.h>

#define	TAB_SIZE	2000

typedef struct {
    float		freq;
    float		phase;
    float		contrast;
} WaveParam;

typedef struct {
    WaveParam	r;
    WaveParam	g;
    WaveParam	b;
} ColorParam;

@interface MandelColor : NSObject
{
    unsigned char		*rtab;
    unsigned char		*gtab;
    unsigned char		*btab;

    IBOutlet NSMatrix	*paramSlider;
    IBOutlet NSForm		*paramField;
    IBOutlet id			patternSelector;
    IBOutlet id			chSelector;
    IBOutlet id			colorView;
    IBOutlet id			mainView;
    IBOutlet id			control;

    int					channel;	// current channel
	int					pattern;	// current color pattern
    ColorParam			cparam;		// current param
}

- (unsigned char *)red;
- (unsigned char *)green;
- (unsigned char *)blue;

- (void)changeParam:(int)tag atChanel:(int)channel toVal:(float)val;
- (void)makeLUTforChannel:(int)channel;
- (void)updateLUT;

- (void)apply:(id)sender;
- (void)patternChanged:(id)sender;
- (void)channelChanged:(id)sender;
- (void)sliderMoved:(id)sender;
- (void)fieldSet:(id)sender;

@end
