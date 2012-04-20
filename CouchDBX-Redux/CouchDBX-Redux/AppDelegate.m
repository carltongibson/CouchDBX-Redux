//
//  AppDelegate.m
//  CouchDBX-Redux
//
//  Created by Carlton Gibson on 20/04/2012.
//  Copyright (c) 2012 Noumenal Software Ltd. All rights reserved.
//

#import "AppDelegate.h"

@interface AppDelegate () <NSWindowDelegate>
- (void)startCouchDBTask;
- (void)stopCouchDBTask;

- (void)appendData:(NSData *)d;
- (void)dataReady:(NSNotification *)n;
-(void)taskTerminated:(NSNotification *)note;

- (NSImage *)defaultBrowserIcon;
@end


@implementation AppDelegate {
    NSTask *_couchDBTask;
    NSPipe *_inPipe, *_outPipe;
}

@synthesize startStopButton;
@synthesize browseButton;
@synthesize outputTextView = _outputTextView;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application
    self.browseButton.image = [self defaultBrowserIcon];
}

#pragma mark - IBActions

- (IBAction)startStop:(id)sender {
    if([_couchDBTask isRunning]) {
      [self stopCouchDBTask];
      return;
    }

    [self startCouchDBTask];
}

- (IBAction)browse:(id)sender {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://127.0.0.1:5984/_utils/"]];
}

#pragma mark - CouchDB Task

- (void)startCouchDBTask
{
    // Hardcoding for Homebrew install for now.
	NSString *launchPath = @"/usr/local/bin/couchdb";

    [self.startStopButton setImage:[NSImage imageNamed:@"stop.png"]];
    [self.startStopButton setLabel:@"Stop CouchDB"];
    
	_inPipe = [[NSPipe alloc] init];
	_outPipe = [[NSPipe alloc] init];
	_couchDBTask = [[NSTask alloc] init];
    
	[_couchDBTask setLaunchPath:launchPath];
	NSArray *args = [[NSArray alloc] initWithObjects:@"-i", nil];
	[_couchDBTask setArguments:args];
	[_couchDBTask setStandardInput:_inPipe];
	[_couchDBTask setStandardOutput:_outPipe];
    
	NSFileHandle *fh = [_outPipe fileHandleForReading];
	NSNotificationCenter *nc;
	nc = [NSNotificationCenter defaultCenter];
    
	[nc addObserver:self
           selector:@selector(dataReady:)
               name:NSFileHandleReadCompletionNotification
             object:fh];
	
	[nc addObserver:self
           selector:@selector(taskTerminated:)
               name:NSTaskDidTerminateNotification
             object:_couchDBTask];
    
  	[_couchDBTask launch];
  	[self.outputTextView setString:@"Starting CouchDB...\n"];
  	[fh readInBackgroundAndNotify];
	sleep(1);
	[self browse:nil];
    
}

- (void)stopCouchDBTask
{
    NSFileHandle *writer;
    writer = [_inPipe fileHandleForWriting];
    [writer writeData:[@"q().\n" dataUsingEncoding:NSASCIIStringEncoding]];
    [writer closeFile];
    
    [self.startStopButton setImage:[NSImage imageNamed:@"start.png"]];
    [self.startStopButton setLabel:@"Start CouchDB"];
}

#pragma mark - Notification Handlers

- (void)windowWillClose:(NSNotification *)aNotification 
{
    NSLog(@"%@", NSStringFromSelector(_cmd));
    [self stopCouchDBTask];
}


- (void)appendData:(NSData *)d
{
    NSString *s = [[NSString alloc] initWithData: d
                                        encoding: NSUTF8StringEncoding];
    NSTextStorage *ts = [self.outputTextView textStorage];
    [ts replaceCharactersInRange:NSMakeRange([ts length], 0) withString:s];
    [self.outputTextView scrollRangeToVisible:NSMakeRange([ts length], 0)];
}

- (void)dataReady:(NSNotification *)n
{
    NSData *d;
    d = [[n userInfo] valueForKey:NSFileHandleNotificationDataItem];
    if ([d length]) {
        [self appendData:d];
    }
    if (_couchDBTask)
        [[_outPipe fileHandleForReading] readInBackgroundAndNotify];
}


-(void)taskTerminated:(NSNotification *)note
{
    _couchDBTask = nil;
    _inPipe = nil;
    _outPipe = nil;
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark -
- (NSImage *)defaultBrowserIcon
{
    // Determine the path to the user's chosen default browser
    CFURLRef appURLRef = nil;
    OSStatus err;
    NSString *appPath;
    NSImage *iconImage;
    
    err = LSGetApplicationForURL((__bridge CFURLRef)[NSURL URLWithString:@"http://"], kLSRolesAll, NULL, &appURLRef);
    if (err != noErr) {
        /* Just try Safari */
        appPath = @"/Applications/Safari.app";
    } else {
        /* We found an application, so we fill in the appropriate values. */
        NSURL *appURL = (__bridge NSURL *)appURLRef;
        appPath = [appURL path];
        iconImage = [[NSWorkspace sharedWorkspace] iconForFile:appPath];
    }
    return iconImage;
}


@end
