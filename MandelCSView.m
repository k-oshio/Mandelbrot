//
//	Color Scale View
//

#import "MandelCSView.h"

@implementation MandelCSView

- (void)drawRect:(NSRect)rects
{
    int				i, ix, n;
    NSRect			bb;
    unsigned char	*r, *g, *b;

    r = [colorControl red];
    g = [colorControl green];
    b = [colorControl blue];

    bb = [self bounds];
    n = bb.size.width;
    bb.size.width = 1;
    for (i = 0; i < n; i++) {
        ix = i * TAB_SIZE / n;
        bb.origin.x = i;
        [[NSColor colorWithDeviceRed:r[ix]/255.0
                               green:g[ix]/255.0
                                blue:b[ix]/255.0
                               alpha:1.0] set];
        NSRectFill(bb);
    }
}

@end
