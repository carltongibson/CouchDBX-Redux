//
//  AppDelegate.h
//  CouchDBX-Redux
//
//  Created by Carlton Gibson on 20/04/2012.
//  Copyright (c) 2012 Noumenal Software Ltd. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface AppDelegate : NSObject <NSApplicationDelegate>
@property (weak) IBOutlet NSToolbarItem *startStopButton;
@property (weak) IBOutlet NSToolbarItem *browseButton;
@property (unsafe_unretained) IBOutlet NSTextView *outputTextView;

@property (assign) IBOutlet NSWindow *window;


- (IBAction)browse:(id)sender;
- (IBAction)startStop:(id)sender;
@end
