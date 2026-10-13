#import <UIKit/UIKit.h>

@interface CrosshairWindow : UIWindow
@end

@implementation CrosshairWindow
// Cho phép chạm xuyên qua (Touch pass-through) để bắn và vuốt không bị cản trở
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    return nil;
}
@end

static CrosshairWindow *gCrosshairWindow = nil;

__attribute__((constructor))
static void initCrosshairOverlay(void) {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (gCrosshairWindow) return;
        
        UIScreen *screen = [UIScreen mainScreen];
        CGRect screenBounds = screen.bounds;
        
        // Khởi tạo Window trong suốt bao phủ toàn màn hình
        gCrosshairWindow = [[CrosshairWindow alloc] initWithFrame:screenBounds];
        gCrosshairWindow.backgroundColor = [UIColor clearColor];
        gCrosshairWindow.windowLevel = UIWindowLevelStatusBar + 9999.0;
        gCrosshairWindow.userInteractionEnabled = NO;
        gCrosshairWindow.hidden = NO;
        
        CGFloat centerX = screenBounds.size.width / 2.0;
        CGFloat centerY = screenBounds.size.height / 2.0;
        
        // Chấm đỏ siêu nhỏ ở chính giữa màn hình (đường kính 6px)
        UIView *centerDot = [[UIView alloc] initWithFrame:CGRectMake(centerX - 3.0, centerY - 3.0, 6.0, 6.0)];
        centerDot.backgroundColor = [UIColor colorWithRed:1.0 green:0.1 blue:0.25 alpha:1.0];
        centerDot.layer.cornerRadius = 3.0;
        centerDot.layer.shadowColor = [UIColor redColor].CGColor;
        centerDot.layer.shadowRadius = 4.0;
        centerDot.layer.shadowOpacity = 0.9;
        centerDot.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
        [gCrosshairWindow addSubview:centerDot];
        
        // 4 vạch ngắm Neon siêu mảnh
        UIColor *cyanNeon = [UIColor colorWithRed:0.0 green:0.95 blue:1.0 alpha:0.9];
        
        // Vạch trên
        UIView *topLine = [[UIView alloc] initWithFrame:CGRectMake(centerX - 1.0, centerY - 14.0, 2.0, 8.0)];
        topLine.backgroundColor = cyanNeon;
        topLine.autoresizingMask = centerDot.autoresizingMask;
        [gCrosshairWindow addSubview:topLine];
        
        // Vạch dưới
        UIView *bottomLine = [[UIView alloc] initWithFrame:CGRectMake(centerX - 1.0, centerY + 6.0, 2.0, 8.0)];
        bottomLine.backgroundColor = cyanNeon;
        bottomLine.autoresizingMask = centerDot.autoresizingMask;
        [gCrosshairWindow addSubview:bottomLine];
        
        // Vạch trái
        UIView *leftLine = [[UIView alloc] initWithFrame:CGRectMake(centerX - 14.0, centerY - 1.0, 8.0, 2.0)];
        leftLine.backgroundColor = cyanNeon;
        leftLine.autoresizingMask = centerDot.autoresizingMask;
        [gCrosshairWindow addSubview:leftLine];
        
        // Vạch phải
        UIView *rightLine = [[UIView alloc] initWithFrame:CGRectMake(centerX + 6.0, centerY - 1.0, 8.0, 2.0)];
        rightLine.backgroundColor = cyanNeon;
        rightLine.autoresizingMask = centerDot.autoresizingMask;
        [gCrosshairWindow addSubview:rightLine];
        
        [gCrosshairWindow makeKeyAndVisible];
    });
}
