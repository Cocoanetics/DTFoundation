//
//  DTDownloadCache.h
//  DTFoundation
//
//  Created by Oliver Drobnik on 4/20/12.
//  Copyright (c) 2012 Cocoanetics. All rights reserved.
//

#import "DTDownload.h"

extern NSString *DTDownloadCacheDidCacheFileNotification;

@interface DTDownloadCache : NSObject <DTDownloadDelegate>

/**
 Access the shared cache.
 @returns the shared instance of the download cache.
 */
+ (DTDownloadCache *)sharedInstance;

/**
 @param URL The URL of the file
 @param shouldLoad If the data should be loaded from the web in case it is not cached already.
 @returns The cached image or `nil` if none is cached.
 */
- (NSData *)cachedDataForURL:(NSURL *)URL shouldLoad:(BOOL)shouldLoad;

/**
 current sum of cached files in Bytes
 */
- (NSUInteger)currentDiskUsage;

/**
 The number of downloads that can go on at the same time.
 */
@property (nonatomic, assign) NSUInteger maxNumberOfConcurrentDownloads;

/**
 The maximum disk space used for caching files. The default value is 20 MB.
 */
@property (nonatomic, assign) NSUInteger diskCapacity;

@end


/**
 Specialized methods for dealing with images. An NSCache holds on to UIImage references after they have been retrieved once since that speeds up subsequent drawing.
 */
@interface DTDownloadCache (Images)


/**
 Specialized method for retrieving cached images.
 @param URL The URL of the image
 @param shouldLoad If the image should be loaded from the web in case it is not cached already.
 @returns The cached image or `nil` if none is cached.
 */
- (UIImage *)cachedImageForURL:(NSURL *)URL shouldLoad:(BOOL)shouldLoad;

@end
