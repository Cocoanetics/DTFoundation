//
//  DTDownloadItem.h
//  DTFoundation
//
//  Created by René Pirringer on 1/8/13.
//  Copyright (c) 2013 Cocoanetics. All rights reserved.
//

/**
 Represents one downloadable item for use with DTDownloadQueue. For using DTDownloadQueue you would instantiate one DTDownloadItem and pass it to downloadItem:completion:progress:.
 */
@interface DTDownloadItem : NSObject

/**
 The URL of the receiver
 */
@property (nonatomic, strong) NSURL *URL;

/**
 The target file path the item is to be downloaded to
 */
@property (nonatomic, strong) NSString *destinationFile;


/**
 Creates a download item
 @param url The URL to download
 @param destinationFile The file path to download to
 */
- (id)initWithURL:(NSURL *)url destinationFile:(NSString *)destinationFile;

@end