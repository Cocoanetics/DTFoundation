//
//  DTLog.h
//  DTFoundation
//
//  Created by Oliver Drobnik on 06.08.13.
//  Copyright (c) 2013 Cocoanetics. All rights reserved.
//

// block signature called for each log statement
typedef void (^DTLogBlock)(NSUInteger level, NSString *fileName, NSString *methodName, NSUInteger lineNumber, NSString *format, ...);


// internal variables needed by macros
extern DTLogBlock DTLogHandler;
extern NSUInteger DTLogLevel;

/**
 Sets the block to be executed for messages with a log level less or equal the currently set log level
 @param logBlock
 */
void DTLogSetLoggerBlock(DTLogBlock handler);

/**
 Modifies the current log level
 @param logLevel The ASL log level (0-7) to set, lower numbers being more important
 */
void DTLogSetLogLevel(NSUInteger logLevel);


/**
 There is a macro for each ASL log level:
 
 - DTLogEmergency (0)
 - DTLogAlert (1)
 - DTLogCritical (2)
 - DTLogError (3)
 - DTLogWarning (4)
 - DTLogNotice (5)
 - DTLogInfo (6)
 - DTLogDebug (7)
 */

// log macro for error level (0)
#define DTLogEmergency(format, ...) DTLogCallHandlerIfLevel(0, format, ##__VA_ARGS__);

// log macro for error level (1)
#define DTLogAlert(format, ...) DTLogCallHandlerIfLevel(1, format, ##__VA_ARGS__);

// log macro for error level (2)
#define DTLogCritical(format, ...) DTLogCallHandlerIfLevel(2, format, ##__VA_ARGS__);

// log macro for error level (3)
#define DTLogError(format, ...) DTLogCallHandlerIfLevel(3, format, ##__VA_ARGS__);

// log macro for error level (4)
#define DTLogWarning(format, ...) DTLogCallHandlerIfLevel(4, format, ##__VA_ARGS__);

// log macro for error level (5)
#define DTLogNotice(format, ...) DTLogCallHandlerIfLevel(5, format, ##__VA_ARGS__);

// log macro for info level (6)
#define DTLogInfo(format, ...) DTLogCallHandlerIfLevel(6, format, ##__VA_ARGS__);

// log macro for debug level (7)
#define DTLogDebug(format, ...) DTLogCallHandlerIfLevel(7, format, ##__VA_ARGS__);

// macro that gets called by individual level macros
#define DTLogCallHandlerIfLevel(minLevel, format, ...) \
	if (DTLogHandler && DTLogLevel>=minLevel) DTLogHandler(7, DTLogSourceFileName, DTLogSourceMethodName, DTLogSourceLineNumber, format, ##__VA_ARGS__);

// helper to get the current source file name as NSString
#define DTLogSourceFileName [[NSString stringWithUTF8String:__FILE__] lastPathComponent]

// helper to get current method name
#define DTLogSourceMethodName NSStringFromSelector(_cmd)

// helper to get current line number
#define DTLogSourceLineNumber __LINE__