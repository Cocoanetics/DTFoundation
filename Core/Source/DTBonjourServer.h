//
//  DTBonjourServer.h
//  BonjourTest
//
//  Created by Oliver Drobnik on 01.11.12.
//  Copyright (c) 2012 Oliver Drobnik. All rights reserved.
//

#import <Foundation/Foundation.h>


@class DTBonjourServer, DTBonjourDataConnection;

@protocol DTBonjourServerDelegate <NSObject>
@optional
- (void)bonjourServer:(DTBonjourServer *)server didAcceptConnection:(DTBonjourDataConnection *)connection;
@end

@interface DTBonjourServer : NSObject

- (id)initWithBonjourType:(NSString *)bonjourType;

- (BOOL)start;
- (void)stop;

@property (nonatomic, weak) id <DTBonjourServerDelegate> delegate;

@end
