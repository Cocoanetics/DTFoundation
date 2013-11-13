//
//  DTReachability.h
//  AutoIngest
//
//  Created by Oliver Drobnik on 29.04.13.
//  Copyright (c) 2013 Cocoanetics. All rights reserved.
//

#import <SystemConfiguration/SystemConfiguration.h>

// macro to determine reachability status from connection flags
#define DTReachabilityIsReachableFromFlags(connectionFlags) ((connectionFlags & kSCNetworkFlagsReachable) && !(connectionFlags & kSCNetworkFlagsConnectionRequired))

// observer block
typedef void(^DTReachabilityObserverBlock)(SCNetworkConnectionFlags connectionFlags);

/**
 Block-Based Reachability Observation, using the SystemConfiguration.framework. Based largely on Erica Sadun's [UIDevice Reachability Extension](https://github.com/erica/uidevice-extension/blob/master/UIDevice-Reachability.m). Modified to use `SCNetworkReachabilityCreateWithName` instead based on Nick Lockwoods [FXReachability](http://github.com/nicklockwood/FXReachability) because this approach also takes the DNS resolvability into consideration.
 
 You can use the `DTReachabilityIsReachableFromFlags(connectionFlags)` macro to determine if there's an active internet connection based on the connection flags return in the observation block.
 
 This class assumes that if apple.com is reachable then so is the entire internet.
 */
@interface DTReachability : NSObject


/**
 Returns an initialized DTReachability instance with the default hostname: apple.com

 @returns An initialized DTReachability instance.
 */
- (instancetype)init;

/**
 Returns an initialized DTReachability instance with a given host name
 
 @returns An initialized DTReachability instance.
 */
- (instancetype) initWithHostname:(NSString *)hostname;

/**
 Returns a shared DTReachability instance with the default hostname is apple.com. Generally you should use this because each DTReachability instance maintains its own table of observers.
 
 @returns the default DTReachability instance
 */
+ (DTReachability *)defaultReachability;


/**
 
 Adds a block to observe network reachability. Every time the reachability flags change this block is invoked. Also once right after adding the observer with the current state.
 @warning use -[[DTReachability defaultReachability] addReachabilityObserverWithBlock:]
 @param observer An observation block
 @returns An opaque reference to the observer which you can use to remove it
 */
+ (id)addReachabilityObserverWithBlock:(DTReachabilityObserverBlock)observer __attribute__((deprecated("use -[[DTReachability defaultReachability] addReachabilityObserverWithBlock:]")));


/**
 Removes a reachability observer.
 @warning use -[[DTReachability defaultReachability] removeReachabilityObserver:]
 @param observer The opaque reference to a reachability observer
 */
+ (void)removeReachabilityObserver:(id)observer __attribute__((deprecated("use -[[DTReachability defaultReachability] removeReachabilityObserver:]")));

/**
 
 Adds a block to observe network reachability. Every time the reachability flags change this block is invoked. Also once right after adding the observer with the current state.
 @warning use -[[DTReachability defaultReachability] addReachabilityObserverWithBlock:]
 @param observer An observation block
 @returns An opaque reference to the observer which you can use to remove it
 */
- (id)addReachabilityObserverWithBlock:(DTReachabilityObserverBlock)observer;


/**
 Removes a reachability observer.
 @warning use -[[DTReachability defaultReachability] removeReachabilityObserver:]
 @param observer The opaque reference to a reachability observer
 */
- (void)removeReachabilityObserver:(id)observer;


/**
 Changes the hostname that is monitored for the reachability. All registered observers will be notified on reachability changes for the new hostname
 
 @param hostname The new hostname that is monitored
 */
- (void)setHostname:(NSString *)hostname;


@end
