
// ** NSBackgroundTaskCompleteCallback

@protocol NSBackgroundTaskCompleteCallback

-(void) onComplete:(NSObject *) result;
-(void) onError:(NSString *) message;

@end

@interface NSCallback : NSObject<NSBackgroundTaskCompleteCallback>
    
@end


// ** NSBackgroundTaskCopyFiles

@interface NSBackgroundTaskCopyFiles : NSObject{

  NSString *_toFile;
  NSString *_fromFile;

}

@property (nonatomic, retain) id<NSBackgroundTaskCompleteCallback> delegate;

-(void) runTask;

-(id) initWithFromFile:(NSString *) fromFile toFile: (NSString *) toFile;

@end


// ** NSBackgroundTaskHttpRequestToFile

@interface NSBackgroundTaskHttpRequestToFile : NSObject{

    NSString *_url;
    NSString *_toFile;
    NSString *_identifier;
    NSMutableDictionary *_httpHeaders;
    BOOL _checkPartialDownload;
    int _partBytesSize;
    BOOL _debug;

}

@property (nonatomic, retain) id<NSBackgroundTaskCompleteCallback> delegate;

-(void) runTask;
-(id) initWithUrl:(NSString *) url toFile: (NSString *) toFile identifier: (NSString *) identifier;
-(void) addHeaderWithName: (NSString *) name andValue: (NSString *) value;
-(void) setCheckPartialDownload: (BOOL) checkPartialDownload;
-(void) setPartBytesSize: (int) partBytesSize;
-(void) setDebug: (BOOL) debug;

@end

// ** NSBackgroundTaskUnzipTask

@interface NSBackgroundTaskUnzipTask : NSObject{

  NSString *_toFile;
  NSString *_fromFile;

}

@property (nonatomic, retain) id<NSBackgroundTaskCompleteCallback> delegate;

-(void) runTask;

-(id) initWithFromFile:(NSString *) fromFile toFile: (NSString *) toFile;

@end


// ** NSHttpPostData

@interface NSHttpPostFile : NSObject{

}

@property (nonatomic, retain) NSString *identifier;
@property (nonatomic, retain) NSString *fileSrc;
@property (nonatomic, retain) NSString *jsonKey;
@property (nonatomic, retain) NSString *result;
@property (nonatomic, retain) NSMutableDictionary *json;
@property (nonatomic, retain) NSMutableDictionary *responseHeaders;

-(id) initWithFileSrc:(NSString*) fileSrc jsonKey:(NSString *) jsonKey;

-(void) addJsonKey:(NSString*) key value:(NSString *) value;

-(NSMutableArray *) getHeadersNames;

-(NSString *) getHeaderValue:(NSString *) name;

-(NSMutableDictionary *) getHeaders;

@end

// ** NSSplitFile

@interface NSSplitFile : NSObject{
    
}
    
    @property (nonatomic, retain) NSString *fileSrc;
    @property (nonatomic, retain) NSString *filePartPath;
    @property (nonatomic, retain) NSString *filePartName;
    @property (nonatomic, retain) NSString *filePartSufix;
    @property (nonatomic, retain) NSMutableArray *fileParts;
    @property int filePartMaxSize;
    @property int filePartCount;

    -(id) init;
    
@end

// ** NSSplitFilesTask

@interface NSSplitFileTask : NSObject{
    NSMutableArray* _splitFiles;
}
    
@property (nonatomic, retain) id<NSBackgroundTaskCompleteCallback> delegate;
    
-(id) init;
-(void) addSplitFile: (NSSplitFile *) splitFile;
-(void) runTask;

@end

// ** NSLargeFile

@interface NSLargeFile : NSObject

@property (nonatomic, retain) UIImage *image;
@property (nonatomic, retain) NSString *fileDst;
@property (nonatomic, retain) NSString *fileSrc;
@property int quality;

@end

// ** NSLargeFilePersiserTask

@interface NSLargeFilePersisterTask : NSObject{
    NSMutableArray *_largeFiles;
}

@property (nonatomic, retain) id<NSBackgroundTaskCompleteCallback> delegate;

-(id) init;
-(void) addLargeFile: (NSLargeFile *) largeFile;
-(void) runTask;

@end


// ** HttpPostDataTask

@interface NSHttpPostFileTask : NSObject{
    NSMutableArray *_postFiles;
    BOOL _userGzip;
    BOOL _useFormData;
    NSString *_url;
    NSMutableDictionary *_httpHeaders;
    int _index;
    int _debug;
}

@property (nonatomic, retain) id<NSBackgroundTaskCompleteCallback> delegate;

-(id) initWithUrl: (NSString *) url;
-(void) setUseGzip: (BOOL) useGzip;
-(void) setDebug: (BOOL) debug;
-(void) setUseFormData: (BOOL) useFormData;
-(void) addPostFile: (NSHttpPostFile *) postFile;
-(void) addHeaderWithName: (NSString *) name andValue: (NSString *) value;
-(void) runTask;

@end



// ** NSQuery

@interface NSQuery : NSObject{
    
}

@property (nonatomic, retain) NSString *query;
@property (nonatomic, retain) NSString *insertQuery;
@property (nonatomic, retain) NSString *updateQuery;
@property (nonatomic, retain) NSMutableArray *params;
@property (nonatomic, retain) NSString *tableName;
@property (nonatomic, retain) NSString *updateKey;
@property (nonatomic, retain) NSString *updateKeyValue;
@property (nonatomic, retain) NSString *updateKeyDataType;

@end

@interface NSDbBatchTask : NSObject{
    NSMutableArray *_queries;
    NSString *_dbPath;
    BOOL _debug;
    BOOL _transactional;
}


@property (nonatomic, retain) id<NSBackgroundTaskCompleteCallback> delegate;

-(id) initWithDbPath:(NSString *) dbPath;
-(void) setDebug: (BOOL) debug;
-(void) setTransactional:(BOOL) transactional;
-(void) addQuery: (NSQuery *) query;
-(void) runTask;

@end

@interface NSRestException : NSException

@property (nonatomic, retain) NSString *content;
@property (nonatomic, retain) NSString *message;
@property int statusCode;

@end
