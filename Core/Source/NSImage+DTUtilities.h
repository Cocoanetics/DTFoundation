//
//  NSImage+DTUtilities.h
//  DTFoundation
//
//  Created by Oliver Drobnik on 03.10.12.
//  Copyright (c) 2012 Cocoanetics. All rights reserved.
//

@interface NSImage (DTUtilities)

- (BOOL)writeJPEGToFile:(NSString *)path withCompressionFactor:(CGFloat)compressionFactor atomically:(BOOL)useAuxiliaryFile;

@end
