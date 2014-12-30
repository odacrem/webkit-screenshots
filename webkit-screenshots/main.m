//
//  main.m
//  screenshots
//
//  Created by Pablo Mercado on 12/24/14.
//  Copyright (c) 2014 Pablo Mercado. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Screenshot.h"
#if DEBUG == 0
#define DebugLog(...)
#elif DEBUG == 1
#define DebugLog(...) NSLog(__VA_ARGS__)
#endif


Screenshot *mm;
NSArray *options;
NSArray *options_desc;


void usage() {
  printf("%s\n","Usage: screenshots [options] http://example.net/");
  printf("\n");
  printf("%s\n","Options");
  for (int i =0; i < [options count]; i++) {
    NSString *option = (NSString *)[options objectAtIndex:i];
    NSString *option_desc = (NSString *)[options_desc objectAtIndex:i];
    printf("%s\t\t%s\n",[option UTF8String],[option_desc UTF8String]);
  }
  exit(1);
}

void timeout() {
  exit(1);
}

NSMutableDictionary* processArgs() {
  NSProcessInfo   *proc = [NSProcessInfo processInfo];
  NSMutableArray         *args = [NSMutableArray arrayWithArray:[proc arguments]];
  NSMutableDictionary *opts = [[NSMutableDictionary alloc] init];
  
  //DEFAULTS
  NSURL* url;
  int width = 1440;
  int height = 900;
  double timeout = 60;
  float delay = 0;
  NSString *js = nil;
  NSString *selector=nil;
  NSString *outfile = nil;
  
  //OPTIONS
  options = @[@"--js", @"--selector",@"--width",@"--height",@"--outfile",@"--delay",@"--timeout"];
  options_desc = @[@"javascript to execute", @"css selector to capture",@"width",@"height",@"output file",@"delay between page load finishing and screenshot",@"page load timeout (60)"];
  
  // remove program arg
  [args removeObjectAtIndex:0];
  
  // make sure at least the url argument is specified
  if ([args count] == 0) {
    usage();
  }
  
  // url should always be last index
  NSString *url_string = (NSString *)[args lastObject];
  url = [NSURL URLWithString: url_string];
  if ([url scheme] == nil) {
    url_string = [NSString stringWithFormat:@"http://%@",url_string];
    url = [NSURL URLWithString: url_string];
  }
  [args removeLastObject];
  // validate the url sort of
  if (url == nil || (![[url scheme] isEqualToString:@"http"] && ![[url scheme] isEqualToString:@"https"])) {
    usage();
  }
  
  // parse out the rest of of the options
  for (int i = 0; i < [args count]; i++) {
    NSString *opt_arg = (NSString *)[args objectAtIndex: i ];
    NSMutableArray *keyval = [NSMutableArray arrayWithArray:[opt_arg componentsSeparatedByString:@"="]];
    NSString *opt_key = (NSString*)[keyval objectAtIndex:0];
    NSString *opt_val;
    if ([keyval count] > 1) {
      [keyval removeObjectAtIndex:0];
      opt_val = (NSString*)[keyval componentsJoinedByString:@"="];
    }
    DebugLog(@"key:%@ value:%@",opt_key,opt_val);
    int opt_key_index = (int)[options indexOfObject:opt_key];
    switch (opt_key_index) {
      case 0:
        js = opt_val;
        break;
      case 1:
        selector = opt_val;
        break;
      case 2:
        width = [opt_val intValue];
        break;
      case 3:
        height = [opt_val intValue];
        break;
      case 4:
        outfile = opt_val;
        break;
      case 5:
        delay = [opt_val floatValue];
        break;
      case 6:
        timeout = [opt_val doubleValue];
        break;
      default:
        break;
    }
  }
  // set the default outfile option
  if (outfile == nil) {
    NSDateFormatter *dateformate=[[NSDateFormatter alloc]init];
    [dateformate setDateFormat:@"YYYY-MM-dd-HH-mm-ss"]; // Date formater
    NSString *date = [dateformate stringFromDate:[NSDate date]];
    outfile = [NSString stringWithFormat:@"%@-%@.png",[url host],date];
  }
  [opts setObject:outfile forKey:@"outfile"];
  //set js option if specified
  if (js !=nil) [opts setObject:js forKey:@"js"];
  // set selector option if specified
  if (selector != nil) [opts setObject:selector forKey:@"selector"];
  // set the url option
  [opts setObject:url forKey:@"url"];
  //set the size option
  NSSize size = NSMakeSize(width,height);
  [opts setObject:[NSValue valueWithSize:size] forKey:@"size"];
  //set the delay option
  [opts setObject:[NSNumber numberWithFloat:delay] forKey:@"delay"];
  //set the timoeout option
  [opts setObject:[NSNumber numberWithDouble:timeout] forKey:@"timeout"];
  
  return opts;
}

int main(int argc, const char * argv[]) {
  @autoreleasepool {
    NSApplication  *app = [NSApplication sharedApplication];
    NSMutableDictionary *opts = processArgs();
    NSURL *url = (NSURL *)[opts objectForKey:@"url"];
    mm  = [Screenshot takeScreenshot:url options:opts];
    [app run];
  }
  return 0;
}


