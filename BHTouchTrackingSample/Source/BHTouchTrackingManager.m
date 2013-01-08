/*
 * Copyright (c) 2013 Benedikt Hirmer - HIRMER.me
 *
 * Permission is hereby granted, free of charge, to any person obtaining
 * a copy of this software and associated documentation files (the
 * "Software"), to deal in the Software without restriction, including
 * without limitation the rights to use, copy, modify, merge, publish,
 * distribute, sublicense, and/or sell copies of the Software, and to
 * permit persons to whom the Software is furnished to do so, subject to
 * the following conditions:
 *
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 * NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
 * LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
 * OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
 * WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

#import "BHTouchTrackingManager.h"
#import "BHTouchTracker.h"

@interface BHTouchTrackingManager ()

@property (nonatomic, strong) NSMutableArray *touchTracks;

@end

@implementation BHTouchTrackingManager

- (id)init
{
    self = [super init];
    if (self) {
        self.touchTracks = [NSMutableArray array];
    }
    return self;
}


#pragma mark - Touch Tracking

- (void)trackEvent:(UIEvent *)event
		 forWindow:(UIWindow *)window
{
	if (self.trackingIsActive == NO) {
		return;
	}
	
	NSArray *trackableTouches;
	BOOL shouldCreateNewEvent;
	BOOL shouldFinalizeEvent;
	
	trackableTouches = [self validTouchesForTouches:[[event touchesForWindow:window] allObjects]
							   shouldCreateNewEvent:&shouldCreateNewEvent
								shouldFinalizeEvent:&shouldFinalizeEvent];
	
	if (shouldCreateNewEvent == YES)
	{
		NSLog(@"create new event");
	}
	
	for (UITouch *touch in trackableTouches)
	{
		[self trackTouch:touch];
	}
	
	if (shouldFinalizeEvent == YES)
	{
		NSLog(@"event ended");
	}
}

- (NSArray *)validTouchesForTouches:(NSArray *)touches
			   shouldCreateNewEvent:(BOOL *)shouldCreateNewEvent
			   shouldFinalizeEvent:(BOOL *)shouldFinalizeEvent
{
	NSMutableArray *allTouches;
	NSMutableArray *nonValidTouches;
	
	*shouldCreateNewEvent = YES;
	*shouldFinalizeEvent = YES;
	
	allTouches = [NSMutableArray arrayWithArray:touches];
	nonValidTouches = [NSMutableArray array];
	
	for (UITouch *touch in allTouches)
	{
		if (touch.phase != UITouchPhaseBegan) {
			*shouldCreateNewEvent = NO;
		}
		else
		{
			//when we are in touchPhaseBegan and the touch is NOT inside our trackingView we should not track that touch
			BOOL shouldStopTracking;
			CGPoint location;
			
			location = [touch locationInView:nil];
			shouldStopTracking = !CGRectContainsPoint(self.trackingView.frame, location);
			
			if (shouldStopTracking == YES)
			{
				[nonValidTouches addObject:touch];
				*shouldCreateNewEvent = NO; //non valid touches don't have any effect on events
			}
			
		}
		
		if (NO == ((touch.phase == UITouchPhaseCancelled) ||
				   (touch.phase == UITouchPhaseEnded))) {
			*shouldFinalizeEvent = NO;
		}
	}
	
	[allTouches removeObjectsInArray:nonValidTouches];
	return allTouches;
}

- (void)trackTouch:(UITouch *)touch
{
	BHTouchTracker *touchTracker;
	touchTracker = [self touchTrackerForTouch:touch];
	
	if (touch.phase == UITouchPhaseBegan)
	{
		NSLog(@"touch began");
		[self.touchTracks addObject:[BHTouchTracker touchTrackWithTouch:touch]];
	}
	
	else if (touch.phase == UITouchPhaseMoved ||
			 touch.phase == UITouchPhaseStationary)
	{
		if (touchTracker != nil)
		{
			NSLog(@"mapped touch %p",touch);
		}
		else
		{
			NSLog(@"creating new touch %p",touch);
			[self.touchTracks addObject:[BHTouchTracker touchTrackWithTouch:touch]];
		}
	}
	
	else if (touch.phase == UITouchPhaseEnded ||
			 touch.phase == UITouchPhaseCancelled)
	{
		NSLog(@"touch ended");
		if (touchTracker != nil) {
			[self.touchTracks removeObject:touchTracker];
		}
	}
}

#pragma mark - TouchTrack

- (BHTouchTracker *)touchTrackerForTouch:(UITouch *)touch
{
	for (BHTouchTracker *track in self.touchTracks)
	{
		if (track.touch == touch) {
			return track;
		}
	}
	
	return nil;
}


#pragma mark - Singleton overrides

static BHTouchTrackingManager *sharedManager = nil;


+ (BHTouchTrackingManager *)sharedManager {
    DEFINE_SHARED_INSTANCE_USING_BLOCK(^
									   {
										   sharedManager = [[self alloc] init];
										   return sharedManager;
									   }
									   );
}

+ (id)allocWithZone:(NSZone *)zone {
	@synchronized(self) {
        if (sharedManager == nil) {
            return [super allocWithZone:zone];
        }
    }
    return nil; // On subsequent allocation attempts return nil
}

- (id)copyWithZone:(NSZone *)zone {
    return self;
}


@end
