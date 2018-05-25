/* All Rights reserved */

#import <GNUstepGUI/GSDisplayServer.h>
#import "Recycler.h"

static RecyclerIcon *recyclerIcon = nil;

// WindowMaker's callback funtion on mouse click
void _recyclerMouseDown(WObjDescriptor *desc, XEvent *event)
{
  fprintf(stderr, "Recycler: mouse down (window: %lu (%lu) subwindow: %lu)!\n",
          event->xbutton.window, event->xbutton.root, event->xbutton.subwindow);
  NSEvent     *theEvent;
  NSPoint     eventLocation = NSMakePoint(event->xbutton.x, event->xbutton.y);
  NSEventType eventType = 0;
      
  // eventLocation = [recyclerIcon convertBaseToScreen:eventLocation];

  if (event->xbutton.button == Button1)
    {
      // eventType = NSLeftMouseDown;
      appIconMouseDown(desc, event);
      // wHandleAppIconMove(desc->parent, event);
    }
  else if (event->xbutton.button == Button3)
    {
      // Window win = (Window)[GSCurrentServer()
      //                          windowDevice:[[NSApp mainWindow] windowNumber]];
      event->xbutton.window = event->xbutton.root;
      XSendEvent(dpy, event->xbutton.root, False, ButtonPressMask, event);
      // eventType = NSRightMouseDown;
    }
  
  if (eventType)
    {
      theEvent =
        [NSEvent mouseEventWithType:eventType
                           location:eventLocation
                      modifierFlags:0
                          timestamp:(NSTimeInterval)event->xbutton.time / 1000.0
                       windowNumber:[recyclerIcon windowNumber]
                            context:[recyclerIcon graphicsContext]
                        eventNumber:event->xbutton.serial
                         clickCount:1
                           pressure:1.0];

      [[recyclerIcon contentView] performSelectorOnMainThread:@selector(mouseDown:)
                                                   withObject:theEvent
                                                waitUntilDone:NO];
    }
}

@implementation	RecyclerIcon

+ (WAppIcon *)createAppIconForDock:(WDock *)dock
{
  WScreen  *scr = dock->screen_ptr;
  WAppIcon *btn = NULL;
  int      rec_pos;
 
  // Search for position in Dock for new Recycler
  for (rec_pos = dock->max_icons-1; rec_pos > 0; rec_pos--)
    {
      if ((btn = dock->icon_array[rec_pos]) == NULL)
        break;
    }

  if (rec_pos > 0) // There is a space in Dock
    {
      btn = wAppIconCreateForDock(scr, "", "Recycler", "GNUstep", TILE_NORMAL);
      btn->yindex = rec_pos;
    }
  else // No space in Dock
    {
      NSLog(@"Recycler: no space in the Dock. Not implemented yet...");
    }

  return btn;
}

+ (WAppIcon *)recyclerAppIconForDock:(WDock *)dock
{
  WScreen  *scr = dock->screen_ptr;
  WAppIcon *btn, *rec_btn = NULL;
 
  btn = scr->app_icon_list;
  while (btn->next)
    {
      if (!strcmp(btn->wm_instance, "Recycler"))
        {
          rec_btn = btn;
          break;
        }
      btn = btn->next;
    }

  if (!rec_btn)
    {
      rec_btn = [RecyclerIcon createAppIconForDock:dock];
      wDockAttachIcon(dock, rec_btn, 0, rec_btn->yindex, NO);
    }
  
  return rec_btn;
}

- initWithDock:(WDock *)dock
{
  XClassHint classhint;
  
  dockIcon = [RecyclerIcon recyclerAppIconForDock:dock];
 
  if (dockIcon == NULL)
    {
      NSLog(@"Recycler Dock icon creation failed!");
      return nil;
    }

  dockIcon->icon->core->descriptor.handle_mousedown = _recyclerMouseDown;

  // recyclerIcon = [super initWithContentRect:NSMakeRect(0,0,64,64)
  //                                 styleMask:NSIconWindowMask
  //                                   backing:NSBackingStoreRetained
  //                                     defer:YES
  //                                    screen:nil];
  // Window iconWin = (Window)[GSCurrentServer()
  //                              windowDevice:[recyclerIcon windowNumber]];
  // dockIcon->icon->core->window = iconWin;
  // dockIcon->icon->icon_win = iconWin;
  
  classhint.res_name = "Recycler";
  classhint.res_class = "GNUstep";
  XSetClassHint(dpy, dockIcon->icon->core->window, &classhint);
  
  recyclerIcon = [super initWithWindowRef:&dockIcon->icon->core->window];
  
  view = [[RecyclerView alloc] initWithFrame:NSMakeRect(0,0,64,64)];
  [view setImage:[NSImage imageNamed:@"recyclerDeposit"]];
  [recyclerIcon setContentView:view];
  [view release];

  return recyclerIcon;
}

- (WAppIcon *)dockIcon
{
  return dockIcon;
}

- (BOOL)canBecomeMainWindow
{
  return NO;
}

- (BOOL)canBecomeKeyWindow
{
  return NO;
}

- (BOOL)worksWhenModal
{
  return YES;
}

- (void)orderWindow:(NSWindowOrderingMode)place relativeTo:(NSInteger)otherWin
{
  [super orderWindow:place relativeTo:otherWin];
}

- (void)_initDefaults
{
  [super _initDefaults];
  
  [self setTitle:@"Recycler"];
  [self setExcludedFromWindowsMenu:YES];
  [self setReleasedWhenClosed:NO];
  
  if ([[NSUserDefaults standardUserDefaults] 
        boolForKey: @"GSAllowWindowsOverIcons"] == YES)
    _windowLevel = NSDockWindowLevel;
}

- (void)rightMouseDown:(NSEvent *)theEvent
{
  Window win = (Window)[GSCurrentServer()
                           windowDevice:[recyclerIcon windowNumber]];
  NSLog(@"Recycler: RMB click! Server: %@ Window: %lu",
        GSCurrentServer(), win);
  [super rightMouseDown:theEvent];
}

- (void)mouseDown:(NSEvent *)theEvent
{
  NSLog(@"Recycler icon: mouse down!");  
}

@end

@implementation RecyclerView

// Class variables
static NSCell *dragCell = nil;
static NSCell *tileCell = nil;

static NSSize scaledIconSizeForSize(NSSize imageSize)
{
  NSSize iconSize, retSize;
  
  // iconSize = GSGetIconSize();
  iconSize = NSMakeSize(64,64);
  retSize.width = imageSize.width * iconSize.width / 64;
  retSize.height = imageSize.height * iconSize.height / 64;
  return retSize;
}

+ (void)initialize
{
  NSImage	*tileImage;
  NSSize	iconSize = NSMakeSize(64,64);

  // iconSize = GSGetIconSize();
  /* _appIconInit will set our image */
  dragCell = [[NSCell alloc] initImageCell:nil];
  [dragCell setBordered:NO];
  
  tileImage = [[GSCurrentServer() iconTileImage] copy];
  [tileImage setScalesWhenResized:YES];
  [tileImage setSize:iconSize];
  tileCell = [[NSCell alloc] initImageCell:tileImage];
  RELEASE(tileImage);
  [tileCell setBordered:NO];
}

- (BOOL)acceptsFirstMouse:(NSEvent*)theEvent
{
  return YES;
}

- (void)concludeDragOperation:(id<NSDraggingInfo>)sender
{
}

- (NSDragOperation)draggingEntered:(id<NSDraggingInfo>)sender
{
  NSLog(@"Recycler: dragging entered!");
  return NSDragOperationGeneric;
}

- (void)draggingExited:(id<NSDraggingInfo>)sender
{
}

- (NSDragOperation)draggingUpdated:(id<NSDraggingInfo>)sender
{
  return NSDragOperationGeneric;
}

- (void)drawRect:(NSRect)rect
{
  NSSize iconSize = NSMakeSize(64,64);
  // NSSize iconSize = GSGetIconSize();
  
  NSLog(@"Recycler: drawRect!");
  
  [tileCell drawWithFrame:NSMakeRect(0, 0, iconSize.width, iconSize.height)
  		   inView:self];
  [dragCell drawWithFrame:NSMakeRect(0, 0, iconSize.width, iconSize.height)
		   inView:self];
  
  if ([NSApp isHidden])
    {
      NSRectEdge mySides[] = {NSMinXEdge, NSMinYEdge, NSMaxXEdge, NSMaxYEdge};
      CGFloat    myGrays[] = {NSBlack, NSWhite, NSWhite, NSBlack};
      NSDrawTiledRects(NSMakeRect(4, 4, 3, 2), rect, mySides, myGrays, 4);
    }
}

- (id)initWithFrame:(NSRect)frame
{
  self = [super initWithFrame:frame];
  [self registerForDraggedTypes:[NSArray arrayWithObjects:
                                           NSFilenamesPboardType, nil]];
  return self;
}

- (void)mouseDown:(NSEvent*)theEvent
{
  NSLog(@"Recycler View: mouse down!");

  if ([theEvent clickCount] >= 2)
    {
      /* if not hidden raise windows which are possibly obscured. */
      if ([NSApp isHidden] == NO)
        {
          NSArray *windows = RETAIN(GSOrderedWindows());
          NSWindow *aWin;
          NSEnumerator *iter = [windows reverseObjectEnumerator];
          
          while ((aWin = [iter nextObject]))
            { 
              if ([aWin isVisible] == YES && [aWin isMiniaturized] == NO
                  && aWin != [NSApp keyWindow] && aWin != [NSApp mainWindow]
                  && aWin != [self window] 
                  && ([aWin styleMask] & NSMiniWindowMask) == 0)
                {
                  [aWin orderFrontRegardless];
                }
            }
	
          if ([NSApp isActive] == YES)
            {
              if ([NSApp keyWindow] != nil)
                {
                  [[NSApp keyWindow] orderFront: self];
                }
              else if ([NSApp mainWindow] != nil)
                {
                  [[NSApp mainWindow] makeKeyAndOrderFront: self];
                }
              else
                {
                  /* We need give input focus to some window otherwise we'll 
                     never get keyboard events. FIXME: doesn't work. */
                  NSWindow *menu_window= [[NSApp mainMenu] window];
                  NSDebugLLog(@"Focus",
                              @"No key on activation - make menu key");
                  [GSServerForWindow(menu_window) setinputfocus:
                                      [menu_window windowNumber]];
                }
            }
	  
          RELEASE(windows);
        }
      [NSApp unhide: self]; // or activate or do nothing.
    }
  else
    {
      NSPoint	lastLocation;
      NSPoint	location;
      NSUInteger eventMask = NSLeftMouseDownMask | NSLeftMouseUpMask
	| NSPeriodicMask | NSOtherMouseUpMask | NSRightMouseUpMask;
      NSDate	*theDistantFuture = [NSDate distantFuture];
      BOOL	done = NO;

      lastLocation = [theEvent locationInWindow];
      [NSEvent startPeriodicEventsAfterDelay: 0.02 withPeriod: 0.02];

      while (!done)
	{
	  theEvent = [NSApp nextEventMatchingMask: eventMask
					untilDate: theDistantFuture
					   inMode: NSEventTrackingRunLoopMode
					  dequeue: YES];
	
	  switch ([theEvent type])
	    {
            case NSRightMouseUp:
            case NSOtherMouseUp:
            case NSLeftMouseUp:
	      /* any mouse up means we're done */
              done = YES;
              break;
            case NSPeriodic:
              location = [_window mouseLocationOutsideOfEventStream];
              if (NSEqualPoints(location, lastLocation) == NO)
                {
                  NSPoint	origin = [_window frame].origin;

                  origin.x += (location.x - lastLocation.x);
                  origin.y += (location.y - lastLocation.y);
                  [_window setFrameOrigin: origin];
                }
              break;

            default:
              break;
	    }
	}
      [NSEvent stopPeriodicEvents];
    }
}                                                        

- (BOOL)prepareForDragOperation:(id<NSDraggingInfo>)sender
{
  return YES;
}

- (BOOL)performDragOperation:(id<NSDraggingInfo>)sender
{
  // NSArray	*types;
  // NSPasteboard	*dragPb;

  // dragPb = [sender draggingPasteboard];
  // types = [dragPb types];
  // if ([types containsObject: NSFilenamesPboardType] == YES)
  //   {
  //     NSArray	*names = [dragPb propertyListForType: NSFilenamesPboardType];
  //     NSUInteger index;

  //     [NSApp activateIgnoringOtherApps: YES];
  //     for (index = 0; index < [names count]; index++)
  //       {
  //         [NSApp _openDocument: [names objectAtIndex: index]];
  //       }
  //     return YES;
  //   }
  return NO;
}

- (void)setImage:(NSImage *)anImage
{
  NSImage *imgCopy = [anImage copy];

  if (imgCopy)
    {
      NSSize imageSize = [imgCopy size];

      [imgCopy setScalesWhenResized: YES];
      [imgCopy setSize: scaledIconSizeForSize(imageSize)];
    }
  [dragCell setImage: imgCopy];
  RELEASE(imgCopy);
  [self setNeedsDisplay: YES];
}

@end