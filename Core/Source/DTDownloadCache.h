//
//  DTDownloadCache.h
//  DTFoundation
//
//  Created by Oliver Drobnik on 4/20/12.
//  Copyright (c) 2012 Cocoanetics. All rights reserved.
//

#import "DTDownload.h"

extern NSString *DTDownloadCacheDidCacheFileNotification;


enum {
    DTDownloadCacheOptionNeverLoad = 0,
    DTDownloadCacheOptionLoadIfNotCached,
    DTDownloadCacheOptionReturnCacheAndLoadAlways,
    DTDownloadCacheOptionReturnCacheAndLoadIfChanged,
};
typedef NSUInteger DTDownloadCacheOption;


@interface DTDownloadCache : NSObject <DTDownloadDelegate>

/**
 Access the shared cache.
 @returns the shared instance of the download cache.
 */
+ (DTDownloadCache *)sharedInstance;

/**
 @param URL The URL of the file
 @param option A loading option to specify wheter the file should be loaded if it is already cached.
 @returns The cached image or `nil` if none is cached.
 */
- (NSData *)cachedDataForURL:(NSURL *)URL option:(DTDownloadCacheOption)option;

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
 @param option A loading option to specify wheter the file should be loaded if it is already cached.
 @returns The cached image or `nil` if none is cached.
 */
- (UIImage *)cachedImageForURL:(NSURL *)URL option:(DTDownloadCacheOption)option;

@end
