//
//  DTCompatibility.h
//  DTFoundation
//
//  Created by Rene Pirringer on 30.07.15.
//  Copyright (c) 2015 Cocoanetics. All rights reserved.
//


#if __IPHONE_OS_VERSION_MAX_ALLOWED > __IPHONE_8_4
#define DT_SUPPORTED_INTERFACE_ORIENTATIONS_RETURN_TYPE UIInterfaceOrientationMask
#else
#define DT_SUPPORTED_INTERFACE_ORIENTATIONS_RETURN_TYPE NSUInteger
#endif

