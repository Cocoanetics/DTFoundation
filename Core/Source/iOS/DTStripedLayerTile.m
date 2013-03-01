//
//  DTStripedLayerTile.m
//  DTFoundation
//
//  Created by Oliver Drobnik on 01.03.13.
//  Copyright (c) 2013 Cocoanetics. All rights reserved.
//

#import "DTStripedLayerTile.h"

@implementation DTStripedLayerTile

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@ index=%d width=%@>", NSStringFromClass([self class]), _index, NSStringFromCGRect(self.frame)];
}

@end
