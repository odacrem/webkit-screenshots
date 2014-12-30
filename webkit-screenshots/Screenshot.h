#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>

@interface ScriptingBridge : NSObject
{
  BOOL isStopped;
  id delegate;
}

- (void )stop;
- (BOOL) stopped;
- (void )start;
- (void) setDelegate:(id) pd;

@end


@interface Screenshot : NSObject
{
	void (^completedBlock)(NSBitmapImageRep *image);
  NSWindow *window;
	WebView *webView;
  ScriptingBridge *scriptingBridge;
  NSSize initSize;
  NSDictionary *options;
}

+ (Screenshot *)takeScreenshot:(NSURL *)url options:(NSDictionary *)options;


@end
