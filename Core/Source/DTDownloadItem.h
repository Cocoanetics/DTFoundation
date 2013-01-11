//
// Created by rene on 08.01.13.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import <Foundation/Foundation.h>


@interface DTDownloadItem : NSObject

@property (nonatomic, strong) NSURL *URL;
@property (nonatomic, strong) NSString *destinationFile;


- (id)initWithURL:(NSURL *)url destinationFile:(NSString *)destinationFile;


@end