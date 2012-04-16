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
- (void)downloadWillStartUncompressing:(DTDownload *)download;
- (void)download:(DTDownload *)download didFinishWithFiles:(NSArray *)downloadedFiles;


@end



@interface DTDownload : NSObject 
{
	NSURL *_url;
	NSString *internalDownloadFolder;
	NSString *downloadEntityTag;
	NSDate *lastModifiedDate;
	NSString *downloadEntryIdentifier;
	
	NSString *folderForDownloading;
	
	// downloading
	NSURLConnection *urlConnection;
	NSMutableData *receivedData;
	
	NSDate *lastPaketTimestamp;
	float previousSpeed;
	
	long long receivedBytes;
	long long totalBytes;
	
	
	NSString *receivedDataFilePath;
	NSFileHandle *receivedDataFile;
	
	__unsafe_unretained id <DTDownloadDelegate> delegate;
	
	BOOL headOnly;
}

@property (nonatomic, retain) NSURL *url;

@property (nonatomic, retain) NSString *downloadEntityTag;
@property (nonatomic, retain) NSDate *lastModifiedDate;

@property (nonatomic, retain) NSString *downloadEntryIdentifier;
@property (nonatomic, retain) NSString *folderForDownloading;

@property (nonatomic, retain) id context;



@property (nonatomic, assign) id <DTDownloadDelegate> delegate;

- (id)initWithURL:(NSURL *)url;
- (void)startWithResume:(BOOL)shouldResume;
- (void)startHEAD;
- (void)cancel;

+ (NSString *)stringByFormattingBytesAsHumanReadable:(long long)bytes;


@end
