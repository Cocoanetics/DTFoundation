//
//  DTLog.h
//  DTFoundation
//
//  Created by Oliver Drobnik on 06.08.13.
//  Copyright (c) 2013 Cocoanetics. All rights reserved.
//

/**
 Bla bla bla
 */

// block signature called for each log statement
typedef void (^DTLogBlock)(NSUInteger logLevel, NSString *fileName, NSUInteger lineNumber, NSString *methodName, NSString *format, ...);


// internal variables needed by macros
extern DTLogBlock DTLogHandler;
extern NSUInteger DTCurrentLogLevel;

/**
 @name name bla
 */

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

/**
 Constants for log levels used by DTLog
 */
typedef NS_ENUM(NSUInteger, DTLogLevel)
{
	/**
	 Log level for *emergency* messages
	 */
	DTLogLevelEmergency = 0,
	
	/**
	 Log level for *alert* messages
	 */
	DTLogLevelAlert     = 1,
	
	/**
	 Log level for *critical* messages
	 */
	DTLogLevelCritical  = 2,
	
	/**
	 Log level for *error* messages
	 */
	DTLogLevelError     = 3,
	
	/**
	 Log level for *warning* messages
	 */
	DTLogLevelWarning   = 4,
	
	/**
	 Log level for *notice* messages
	 */
	DTLogLevelNotice    = 5,
	
	/**
	 Log level for *info* messages. This is the default log level for DTLog.
	 */
	DTLogLevelInfo      = 6,
	
	/**
	 Log level for *debug* messages
	 */
	DTLogLevelDebug     = 7
};

// log macro for error level (0)
#define DTLogEmergency(format, ...) DTLogCallHandlerIfLevel(DTLogLevelEmergency, format, ##__VA_ARGS__);

// log macro for error level (1)
#define DTLogAlert(format, ...) DTLogCallHandlerIfLevel(DTLogLevelAlert, format, ##__VA_ARGS__);

// log macro for error level (2)
#define DTLogCritical(format, ...) DTLogCallHandlerIfLevel(DTLogLevelCritical, format, ##__VA_ARGS__);

// log macro for error level (3)
#define DTLogError(format, ...) DTLogCallHandlerIfLevel(DTLogLevelError, format, ##__VA_ARGS__);

// log macro for error level (4)
#define DTLogWarning(format, ...) DTLogCallHandlerIfLevel(DTLogLevelWarning, format, ##__VA_ARGS__);

// log macro for error level (5)
#define DTLogNotice(format, ...) DTLogCallHandlerIfLevel(DTLogLevelNotice, format, ##__VA_ARGS__);

// log macro for info level (6)
#define DTLogInfo(format, ...) DTLogCallHandlerIfLevel(DTLogLevelInfo, format, ##__VA_ARGS__);

// log macro for debug level (7)
#define DTLogDebug(format, ...) DTLogCallHandlerIfLevel(DTLogLevelDebug, format, ##__VA_ARGS__);

// macro that gets called by individual level macros
#define DTLogCallHandlerIfLevel(logLevel, format, ...) \
if (DTLogHandler && DTCurrentLogLevel>=logLevel) DTLogHandler(logLevel, DTLogSourceFileName, DTLogSourceLineNumber, DTLogSourceMethodName, format, ##__VA_ARGS__);

// helper to get the current source file name as NSString
#define DTLogSourceFileName [[NSString stringWithUTF8String:__FILE__] lastPathComponent]

// helper to get current method name
#define DTLogSourceMethodName NSStringFromSelector(_cmd)

// helper to get current line number
#define DTLogSourceLineNumber __LINE__