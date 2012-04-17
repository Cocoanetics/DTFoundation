//
//  CatalogDownloader.h
//  iCatalog
//
//  Created by Oliver Drobnik on 8/6/10.
//  Copyright 2010 Drobnik.com. All rights reserved.
//

#import <Foundation/Foundation.h>

@class DTDownload;

@protocol DTDownloadDelegate <NSObject>

@optional
- (BOOL)shouldResumeDownload:(DTDownload *)download;
- (void)download:(DTDownload *)download downloadedBytes:(long long)downloadedBytes ofTotalBytes:(long long)totalBytes withSpeed:(float)speed;

- (void)downloadDidFinishHEAD:(DTDownload *)download;

- (void)download:(DTDownload *)download didFailWithError:(NSError *)error;
- (void)download:(DTDownload *)download didFinishWithFile:(NSString *)path;

@end



/**
 A Class that represents a download of a file from a remote server.
 */

@interface DTDownload : NSObject 



@property (nonatomic, strong, readonly) NSURL *url;

@property (nonatomic, strong, readonly) NSString *downloadEntityTag;
@property (nonatomic, strong, readonly) NSDate *lastModifiedDate;

@property (nonatomic, strong, readonly) NSString *downloadEntryIdentifier;
@property (nonatomic, strong) NSString *folderForDownloading;

@property (nonatomic, strong) id context;

@property (nonatomic, assign) id <DTDownloadDelegate> delegate;

- (id)initWithURL:(NSURL *)url;
- (void)startWithResume:(BOOL)shouldResume;
- (void)startHEAD;
- (void)cancel;

@end
