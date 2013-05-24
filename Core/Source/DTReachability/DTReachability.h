//
//  DTReachability.h
//  AutoIngest
//
//  Created by Oliver Drobnik on 29.04.13.
//  Copyright (c) 2013 Cocoanetics. All rights reserved.
//

#import <SystemConfiguration/SystemConfiguration.h>

// observer block
typedef void(^DTReachabilityObserverBlock)(SCNetworkConnectionFlags connectionFlags);

/**
 Block-Based Reachability Observation, using the SystemConfiguration.framework. Based largely on Erica Sadun's [UIDevice Reachability Extension](https://github.com/erica/uidevice-extension/blob/master/UIDevice-Reachability.m)
 */
@interface DTReachability : NSObject

/**
 Adds a block to observe network reachability. Every time the reachability flags change this block is invoked. Also once right after adding the observer with the current state.
 @param observer An observation block
 @returns An opaque reference to the observer which you can use to remove it
 */
+ (id)addReachabilityObserverWithBlock:(DTReachabilityObserverBlock)observer;


/**
 Removes a reachability observer.
 @param observer The opaque reference to a reachability observer
 */
+ (void)removeReachabilityObserver:(id)observer;

@end
