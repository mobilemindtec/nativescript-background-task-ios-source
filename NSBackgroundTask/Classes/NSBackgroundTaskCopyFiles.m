
#import "NSBackgroundTask.h"


@implementation NSBackgroundTaskCopyFiles

@synthesize delegate;

-(void) runTask{
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
	    
	    @try{

	    	NSFileManager *fileManager = [NSFileManager defaultManager];

			NSError *moveError;

			NSLog(@"move file %@ to %@", _fromFile, _toFile);

		    if([fileManager fileExistsAtPath: _toFile ] == YES){
		    	NSLog(@"deleting destination file %@ before download..", _toFile);
		    	NSError *deleteError;
		    	[fileManager removeItemAtPath: _toFile error:&deleteError];

				if(deleteError){
					NSLog(@"error on delete file to %@ -> %@", _toFile, deleteError);
					[self.delegate onError: [deleteError description]];
					return;
				}

		    }

			[fileManager moveItemAtPath: _fromFile toPath: _toFile error: &moveError];

			if(moveError)
				[self.delegate onError: [moveError description]];
			else
                [self.delegate onComplete: nil];

	    }@catch(NSException *exception){
	    	[self.delegate onError: [exception reason]];
	    }	

	});
}


-(id) initWithFromFile:(NSString *) fromFile toFile: (NSString *) toFile{
	self = [super init];	
	_toFile = toFile;
	_fromFile = fromFile;	
	return self;
}

@end
