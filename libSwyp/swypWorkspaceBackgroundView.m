//
//  swypWorkspaceBackgroundView.m
//  swyp
//
//  Created by Alexander List on 8/2/11.
//  Copyright 2011 ExoMachina. All rights reserved.
//

#import "swypWorkspaceBackgroundView.h"


@interface swypPrettyPath : NSObject{
	UIBezierPath*		drawPath;
	UIColor	*			drawColor;
}
@property (nonatomic, retain) UIBezierPath*		drawPath;
@property (nonatomic, retain) UIColor*			drawColor;
@end
@implementation swypPrettyPath
@synthesize drawPath,drawColor;
-(void)dealloc{
	SRELS(drawPath); SRELS(drawColor);
	[super dealloc];
}
@end


@implementation swypWorkspaceBackgroundView
- (id)initWithFrame:(CGRect)frame {
    
    if ((self = [super initWithFrame:frame])) {
		
		_touchToPathCoordinationDictionary =	[[NSMutableDictionary alloc] initWithCapacity:1];
		
        // Initialization code.
		self.backgroundColor		= [UIColor grayColor];
//		self.opaque					= YES;
		self.multipleTouchEnabled	= YES;
    }
    return self;
}

-(void)dealloc{
	SRELS(_touchToPathCoordinationDictionary);
	[super dealloc];
}


-(void)endPathTouchTrackingWithTouch:(UITouch*)touch{		
	//eventually make this pretty with loops
	[_touchToPathCoordinationDictionary removeObjectForKey:[NSValue valueWithNonretainedObject:touch]];	
	[self redisplayPaths];	
	
}

- (swypPrettyPath*)	_newPrettyPath{	
	swypPrettyPath *	prettyPath	= [[swypPrettyPath alloc] init];
	UIBezierPath *		path		= [[[UIBezierPath alloc] init] autorelease];
	[path setLineWidth:20];
	[path  setLineJoinStyle:kCGLineJoinMiter];
	[path setLineCapStyle:kCGLineCapRound];
	[path setMiterLimit:.3];
	[prettyPath setDrawPath:path];
	
	UIColor *			pathColor	= [UIColor colorWithRed:0 green:0 blue:1 alpha:.3];
	[prettyPath setDrawColor:pathColor];
	
	return [prettyPath autorelease];
}

-(void)	redisplayPaths{
	[self setNeedsDisplay];	
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
	[super touchesBegan:touches withEvent:event];
    
	for (UITouch * touch in touches){
		
		swypPrettyPath *newInstantiatedPath =	[self _newPrettyPath];
		
		[_touchToPathCoordinationDictionary setObject:newInstantiatedPath forKey:[NSValue valueWithNonretainedObject:touch]];
		
		//create a dot
		[[newInstantiatedPath drawPath] moveToPoint:[touch locationInView:self]];
		CGPoint dotPoint = [touch locationInView:self];
		dotPoint.y += 1;
		[[newInstantiatedPath drawPath] addLineToPoint:dotPoint];
		//update only necessary locations on path
		CGRect refreshRect = CGRectMake([touch locationInView:self].x, [touch locationInView:self].y, 0,0);		  
		refreshRect.size.width += 40;
		refreshRect.size.height += 40;		
		refreshRect.origin.y -= 20;
		refreshRect.origin.x -= 20;
		[self setNeedsDisplayInRect:refreshRect];		
	}
	
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event{
	[super touchesCancelled:touches withEvent:event];
	
	for (UITouch * touch in touches){
		[self endPathTouchTrackingWithTouch:touch];
	}
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event{
	[super touchesEnded:touches withEvent:event];
	
	for (UITouch * touch in touches){
		[self endPathTouchTrackingWithTouch:touch];
	}
}


- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event{
	for (UITouch * touch in touches){
		swypPrettyPath *movedInstantiatedPath = [_touchToPathCoordinationDictionary objectForKey:[NSValue valueWithNonretainedObject:touch]];
		
		if (movedInstantiatedPath != nil){
			
			[[movedInstantiatedPath drawPath] addLineToPoint:[touch locationInView:self]];			
			
			//update only necessary locations on path
			CGRect refreshRect = CGRectMake([touch previousLocationInView:self].x , [touch previousLocationInView:self].y, [touch locationInView:self].x -  [touch previousLocationInView:self].x, [touch locationInView:self].y - [touch previousLocationInView:self].y);
			if (refreshRect.size.height < 0){
				refreshRect.size.height *= -1;
				refreshRect.origin.y -= refreshRect.size.height;
			}
			
			if (refreshRect.size.width < 0){
				refreshRect.size.width *= -1;
				refreshRect.origin.x -= refreshRect.size.width;
			}
			
			refreshRect.size.width += 40;
			refreshRect.size.height += 40;
			
			refreshRect.origin.y -= 20;
			refreshRect.origin.x -= 20;
			
			[self setNeedsDisplayInRect:refreshRect];
			
		}
		
	}
}


- (void)drawRect:(CGRect)rect {
    // Drawing code.	
	
	NSArray *instantiatedPaths = [_touchToPathCoordinationDictionary allValues];
	
	if (ArrayHasItems(instantiatedPaths)){
		
		CGContextRef cRef =  UIGraphicsGetCurrentContext();		
		CGContextSaveGState(cRef);
		
		CGContextClipToRect(cRef, rect);
		
		//Setup default drawing styles
		
		for (NSInteger layerIndex = 0; layerIndex < [instantiatedPaths count]; layerIndex ++) {
			
			swypPrettyPath *layerInstantiatedPath = [instantiatedPaths objectAtIndex:layerIndex];
			
			[[layerInstantiatedPath drawColor] setStroke];
			
			CGColorRef shadowColor = CGColorCreateCopyWithAlpha([[layerInstantiatedPath drawColor] CGColor], .8);
			CGContextSetShadowWithColor (cRef, CGSizeMake(2, 2), 3,shadowColor);
			CGColorRelease(shadowColor);
			
			[[layerInstantiatedPath drawPath] stroke];
			
		}
		
		CGContextRestoreGState(cRef);
	}
	
}


@end
