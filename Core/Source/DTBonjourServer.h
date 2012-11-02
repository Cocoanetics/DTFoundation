//
//  DTBonjourServer.h
//  BonjourTest
//
//  Created by Oliver Drobnik on 01.11.12.
//  Copyright (c) 2012 Oliver Drobnik. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DTBonjourServer : NSObject

- (id)initWithBonjourType:(NSString *)bonjourType;

- (void)startListening;

@end
