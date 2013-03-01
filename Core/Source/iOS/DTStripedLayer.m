//
//  DTStripedLayer.m
//  DTFoundation
//
//  Created by Oliver Drobnik on 01.03.13.
//  Copyright (c) 2013 Cocoanetics. All rights reserved.
//

#import "DTStripedLayer.h"
#import "DTStripedLayerTile.h"
#import "UIColor+DTDebug.h"

@interface DTStripedLayer () // private

@property (nonatomic, readonly) NSCache *tileCache;

@end

@implementation DTStripedLayer
{
    BOOL _isObservingSuperlayerBounds;
    NSCache *_tileCache;
    
    CGFloat _stripeHeight;
    CGFloat _currentWidth;
    
    NSMutableSet *_visibleTileKeys;
    
    id _tileDelegate;
}

- (id)init
{
    self = [super init];
    
    if (self)
    {
        _stripeHeight = 512.0f;
        _visibleTileKeys = [[NSMutableSet alloc] init];
    }
    
    return self;
}

- (void)setBounds:(CGRect)bounds
{
    [super setBounds:bounds];

    // store the width for frequent use
    _currentWidth = bounds.size.width;
    
    [self setNeedsLayout];
}

- (NSRange)_rangeOfVisibleStripesInBounds:(CGRect)bounds
{
    NSUInteger firstIndex = floorf(MAX(0, CGRectGetMinY(bounds))/_stripeHeight);
    NSUInteger lastIndex = floorf(MIN(CGRectGetMaxY(bounds), CGRectGetMaxY(self.bounds))/_stripeHeight);
    
    NSRange range = NSMakeRange(firstIndex, lastIndex - firstIndex + 1);
    
    return range;
}

- (CGRect)_frameOfStripeAtIndex:(NSUInteger)index
{
    CGRect frame = CGRectMake(0, index*_stripeHeight, _currentWidth, _stripeHeight);
    
    // need to crop by total bounds, last item not full height
    frame = CGRectIntersection(self.bounds, frame);
    
    return frame;
}

- (void)layoutSublayers
{
    if (!_isObservingSuperlayerBounds)
    {
        // observe superlayer bounds
        [self.superlayer addObserver:self forKeyPath:@"bounds" options:NSKeyValueObservingOptionNew context:NULL];
        
        _isObservingSuperlayerBounds = YES;
    }
    
    CGRect visibleBounds = [self convertRect:self.superlayer.bounds fromLayer:self.superlayer];
    NSRange visibleStripeRange = [self _rangeOfVisibleStripesInBounds:visibleBounds];
    
    // remove invisible tiles
    
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    
    NSMutableSet *indexesAlreadyPresent = [NSMutableSet set];
    
    for (DTStripedLayerTile *oneSubLayer in [self.sublayers copy])
    {
        if (![oneSubLayer isKindOfClass:[DTStripedLayerTile class]])
        {
            // not our business
            continue;
        }
        
        if (oneSubLayer.bounds.size.width != _currentWidth || !NSLocationInRange(oneSubLayer.index, visibleStripeRange))
        {
            [oneSubLayer removeFromSuperlayer];
        }
        else
        {
            // check frame, might have changed, especially last stripes if bounds has changed
            CGRect tileFrame = [self _frameOfStripeAtIndex:oneSubLayer.index];
            
            if (CGRectEqualToRect(tileFrame, oneSubLayer.frame))
            {
                // store in set so that we know that we already have that
                NSNumber *indexNumber = [NSNumber numberWithUnsignedInteger:oneSubLayer.index];
                [indexesAlreadyPresent addObject:indexNumber];
            }
            else
            {
                [oneSubLayer removeFromSuperlayer];
            }
        }
    }
    
    // add the ones that are not already visible
    
    for (NSUInteger index=visibleStripeRange.location; index<NSMaxRange(visibleStripeRange); index++)
    {
        NSNumber *indexNumber = [NSNumber numberWithUnsignedInteger:index];
        
        if ([indexesAlreadyPresent containsObject:indexNumber])
        {
            // already got that
            continue;
        }
        
        NSString *tileKey = [NSString stringWithFormat:@"%f-%ld", _currentWidth, (unsigned long)index];
        
        DTStripedLayerTile *cachedTile = [self.tileCache objectForKey:tileKey];
        
        CGRect tileFrame = [self _frameOfStripeAtIndex:index];
        
        if (cachedTile)
        {
            cachedTile.anchorPoint = CGPointZero;
            cachedTile.bounds = tileFrame;
            cachedTile.position = tileFrame.origin;
            cachedTile.frame = tileFrame;
            
            [self insertSublayer:cachedTile atIndex:0];
            [cachedTile setNeedsDisplay];
            
            NSLog(@"cached %@", cachedTile);
        }
        else
        {
            // need new tile
            DTStripedLayerTile *newTile = [[DTStripedLayerTile alloc] init];
            newTile.contentsScale = self.contentsScale;
            newTile.rasterizationScale = self.rasterizationScale;
            newTile.index = index;
            
            newTile.anchorPoint = CGPointZero;
            newTile.bounds = tileFrame;
            newTile.position = tileFrame.origin;
            newTile.frame = tileFrame;
            
            newTile.needsDisplayOnBoundsChange = YES;
            [self insertSublayer:newTile atIndex:0];
            newTile.delegate = self;
            [newTile setNeedsDisplay];
            
            // cost in cache is number of pixels
           [self.tileCache setObject:newTile forKey:tileKey cost:tileFrame.size.width * tileFrame.size.height];
        }
    }

    [CATransaction commit];
    
    [super layoutSublayers];
}

- (void)removeFromSuperlayer
{
    if (_isObservingSuperlayerBounds)
    {
        [self.superlayer removeObserver:self forKeyPath:@"bounds" context:NULL];
        _isObservingSuperlayerBounds = NO;
        
        [_tileCache removeAllObjects];
    }
}


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    [self setNeedsLayout];
}

- (void)setDelegate:(id)delegate
{
    [super setDelegate:delegate];
    
    _tileDelegate = delegate;
}

- (void)setContents:(id)contents
{
    // ignore setContents so that the layer itself stays empty
}

- (NSArray *)_visibleTiles
{
    NSMutableArray *tmpArray = [NSMutableArray array];
    
    for (DTStripedLayerTile *oneSubLayer in self.sublayers)
    {
        if (![oneSubLayer isKindOfClass:[DTStripedLayerTile class]])
        {
            // not our business
            continue;
        }
        
        [tmpArray addObject:oneSubLayer];
    }
    
    return tmpArray;
}

- (void)_resetTiles
{
    for (DTStripedLayerTile *oneTile in [self.sublayers copy])
    {
        [oneTile removeFromSuperlayer];
    }
    
    [_tileCache removeAllObjects];
}

- (void)setNeedsDisplay
{
    for (DTStripedLayerTile *oneTile in [self _visibleTiles])
    {
        [oneTile setNeedsDisplay];
    }
}

- (void)setNeedsDisplayInRect:(CGRect)rect
{
    for (DTStripedLayerTile *oneTile in [self _visibleTiles])
    {
        // only inform tiles that are affected by this rect
        if (CGRectIntersectsRect(rect, oneTile.frame))
        {
            [oneTile setNeedsDisplayInRect:rect];
        }
    }
}

- (void)drawLayer:(CALayer *)layer inContext:(CGContextRef)ctx
{
    [_tileDelegate drawLayer:layer inContext:ctx];
}

#pragma mark - Properties

- (void)setStripeHeight:(CGFloat)stripeHeight
{
    if (_stripeHeight != stripeHeight)
    {
        _stripeHeight = stripeHeight;
        
        [self _resetTiles];
        [self setNeedsLayout];
    }
}

- (NSCache *)tileCache
{
    if (!_tileCache)
    {
        _tileCache = [[NSCache alloc] init];
    }
    
    return _tileCache;
}

@synthesize tileCache = _tileCache;

@end
