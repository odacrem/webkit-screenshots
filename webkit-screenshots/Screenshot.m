#import <Cocoa/Cocoa.h>
#import "Screenshot.h"
#pragma GCC diagnostic ignored "-Wundeclared-selector"


@implementation ScriptingBridge

- (ScriptingBridge *) init {
  isStopped = NO;
  return self;
}

- (void) start {
  isStopped = NO;
  if ([delegate respondsToSelector:@selector(capture)]) {
    [delegate performSelector:@selector(capture) withObject: delegate];
  }
}

- (BOOL) stopped {
  return isStopped;
}

- (void) stop {
  isStopped = YES;
}

- (void) setDelegate:(id) pd {
  delegate = pd;
}

+ (BOOL)isSelectorExcludedFromWebScript:(SEL)aSelector {
  return NO;
}
@end


@implementation Screenshot

+ (Screenshot *)takeScreenshot:(NSURL *)url options:(NSDictionary *)options {
  Screenshot *instance = [[self alloc] init:options];
  NSNumber *timeout = (NSNumber *)[options objectForKey:@"timeout"];
  [instance performSelector:@selector(timeout) withObject:instance afterDelay:[timeout doubleValue]];
	[instance download:url];
  return instance;
}

- (id)init:(NSDictionary *)pOptions {
	self = [super init];
	if (self != nil)
	{
    options = pOptions;
    initSize = [[options objectForKey:@"size"] sizeValue];
    if ([options objectForKey:@"completedBlock"] != nil) {
      completedBlock = [(void (^)(NSBitmapImageRep *))[options objectForKey:@"block"] copy];
    }
    [self setupView];
	}
	return self;
}

- (void) setupView {
  NSRect  rect = NSMakeRect(0, 0, 100, 100);
  window = [[NSWindow alloc] initWithContentRect:rect styleMask:NSBorderlessWindowMask backing:NSBackingStoreBuffered defer:NO];
  webView = [[WebView alloc] initWithFrame:rect frameName:nil groupName:nil];
  [webView setApplicationNameForUserAgent:@"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_9_3) AppleWebKit/537.75.14 (KHTML, like Gecko) Version/7.0.3 Safari/7046A194A"];
  [webView setPreferencesIdentifier:@"webkit-screenshots"];
  [[webView preferences] setJavaScriptEnabled:YES];
  [[webView preferences] setLoadsImagesAutomatically:YES];
  [[webView preferences] setPlugInsEnabled:YES];
  [[[webView mainFrame] frameView] setAllowsScrolling:NO];
  [webView setFrameLoadDelegate:self];
  [window setContentView:webView];
}

- (void) download:(NSURL *)url {
  NSLog(@"processing:%@",[url absoluteString]);
  NSRect rect = NSMakeRect(0, 0, initSize.width, initSize.height);
  [[webView window] setContentSize:initSize];
  [webView setFrame:rect];

  WebScriptObject *scriptObject = [webView windowScriptObject];
  ScriptingBridge *bridge = [[ScriptingBridge alloc] init];
  [bridge setDelegate:self];
  scriptingBridge = bridge;
  [scriptObject setValue:bridge forKey:@"WebkitScreenshots"];

  [[webView mainFrame] loadRequest:[NSURLRequest requestWithURL:url]];
}

- (void) capture {
  NSLog(@"capturing image");
  
  NSView *view = [[[webView mainFrame] frameView] documentView];

  NSRect bounds = [view bounds];
  [[webView window] display];
  [[webView window] setContentSize:initSize];

  //NSLog(@"width:%f height:%f",bounds.size.width,bounds.size.height);
  [webView setFrame:bounds];

  NSBitmapImageRep *bitmapdata = [view bitmapImageRepForCachingDisplayInRect:bounds];
  [webView cacheDisplayInRect:bounds toBitmapImageRep:bitmapdata];

  if ([options objectForKey:@"selector"] != nil) {
    NSString *selector = [options objectForKey:@"selector"];
    DOMDocument *doc = [[webView mainFrame] DOMDocument];
    DOMElement *el = [doc querySelector:selector];
    if (el != nil) {
      int left = 0;
      int top = 0;
      int width = [el offsetWidth ];
      int height = [el offsetHeight];
      DOMElement *parent = el;
      do {
        left += [parent offsetLeft];
        top += [parent offsetTop];
        parent = [parent offsetParent];
      } while (parent != nil);
      NSRect cropRect =  NSMakeRect(left,top,width,height);
      cropRect = [[view window] convertRectToBacking:cropRect];
      CGImageRef cropped = CGImageCreateWithImageInRect([bitmapdata CGImage], cropRect);
      bitmapdata = [[NSBitmapImageRep alloc] initWithCGImage:cropped];
      CGImageRelease(cropped);
    }
  }
  NSString *outfile  = (NSString *)[options objectForKey:@"outfile"];
  [[bitmapdata representationUsingType:NSPNGFileType properties:nil] writeToFile:outfile atomically:YES];
  NSLog(@"done");
  if (completedBlock != nil) {
    completedBlock(bitmapdata);
  } else {
    exit(0);
  }
}
- (void) timeout {
  NSLog(@"timed out");
  exit(1);
}

// FrameLoadDelegate Methods

- (void) webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)frame {
	if (frame != [sender mainFrame]) { return; }
  WebScriptObject *scriptObject = [webView windowScriptObject];
  NSString *js = (NSString *)[options objectForKey:@"js"];
  if (js != nil) {
    [scriptObject evaluateWebScript:js];
  }
  if ([scriptingBridge stopped]) {
  } else {
    float delay = [(NSNumber *)[options objectForKey:@"delay"] floatValue];
    [NSTimer scheduledTimerWithTimeInterval:delay target:self selector:@selector(capture) userInfo:self repeats:NO];
  }
}

- (void)webView:(WebView *)sender didReceiveTitle:(NSString *)title forFrame:(WebFrame *)frame {
  //NSLog(@"didReceiveTitle:%@",title);
}


- (void)webView:(WebView *)sender windowScriptObjectAvailable:(WebScriptObject *)windowScriptObject {
  //NSLog(@"windowScriptObjectAvailable");
}


- (void)webView:(WebView *)sender didStartProvisionalLoadForFrame:(WebFrame *)frame {
  //NSLog(@"didStartProvisionalLoadForFrame");
}

- (void)webView:(WebView *)sender willCloseFrame:(WebFrame *)frame {
  //NSLog(@"willCloseFrame");
}

- (void)webView:(WebView *)sender didFailProvisionalLoadWithError:(NSError *)error forFrame:(WebFrame *)frame {
  NSLog(@"didFailProvisionalLoadWithError: %@ %@", error, [error userInfo]);
  exit(1);
}

- (void)webView:(WebView*) sender didFailLoadWithError:(NSError *)error forFrame:(WebFrame *)frame {
  NSLog(@"didFailLoadWeithError: %@ %@", error, [error userInfo]);
}

@end

