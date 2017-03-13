//
//  NSDbBatchTask.m
//  Pods
//
//  Created by Ricardo Bocchi on 13/03/17.
//
//

#import "NSBackgroundTask.h"
#import <sqlite3.h>


@implementation NSDbBatchTask

-(id) initWithDbPath:(NSString *) dbPath{
    self = [super init];
    
    _queries = [NSMutableArray array];
    _dbPath = dbPath;
    
    return self;
}


-(void) addQuery:(NSQuery *)query{
    [_queries addObject:query];
}

-(void) runTask{
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        
        @try {
            sqlite3 *sqlitedb;
            sqlite3_stmt *stmt;
            
            if(sqlite3_open([_dbPath UTF8String], &sqlitedb) != SQLITE_OK){
                [self.delegate onError: [NSString stringWithFormat:@"error open database %@", sqlite3_errmsg(sqlitedb)]];
                return;
            }
            
            for (NSQuery *q in _queries) {
                
                int index = 0;
                
                if(q.query){
                    
                    if(!sqlite3_prepare(sqlitedb, [q.query UTF8String], -1, &stmt, NULL) != SQLITE_OK){
                        [self.delegate onError: [NSString stringWithFormat:@"error prepare stmt %@ - %@", q.query, sqlite3_errmsg(sqlitedb)]];
                        return;
                     
                    }
                    
                    for (NSString *value in q.params) {
                        sqlite3_bind_text(stmt, index++, [value UTF8String], -1, SQLITE_STATIC);
                    }
                    
                    if(sqlite3_step(stmt) != SQLITE_DONE){
                        [self.delegate onError: [NSString stringWithFormat:@"error run query %@ - %@", q.query, sqlite3_errmsg(sqlitedb)]];
                        return;
                    }
                    
                    sqlite3_reset(stmt);
                    
                }else {
                    
                    NSString *sql = [NSString stringWithFormat:@"select id from %@ where %@ = ?", q.tableName, q.updateKey];
                    
                    if(!sqlite3_prepare(sqlitedb, [sql UTF8String], -1, &stmt, NULL) != SQLITE_OK){
                        [self.delegate onError: [NSString stringWithFormat:@"error prepare stmt %@ - %@", q.query, sqlite3_errmsg(sqlitedb)]];
                        return;
                        
                    }
                    
                    sqlite3_bind_text(stmt, 0, [q.updateKeyValue UTF8String], -1, SQLITE_STATIC);
                    NSNumber *rowid = 0;
                    
                    if(sqlite3_step(stmt) == SQLITE_ROW){
                        rowid = [NSNumber numberWithInt:sqlite3_column_int(stmt, 0)];
                    }
                    
                    sqlite3_reset(stmt);
                    
                    if(rowid > 0){
                    
                        NSLog(@"execute update id %@", [rowid stringValue]);
                        
                        [q.params addObject: [rowid stringValue]];
                        
                        if(!sqlite3_prepare(sqlitedb, [q.updateQuery UTF8String], -1, &stmt, NULL) != SQLITE_OK){
                            [self.delegate onError: [NSString stringWithFormat:@"error prepare stmt %@ - %@", q.updateQuery, sqlite3_errmsg(sqlitedb)]];
                            return;
                            
                        }
                        
                        for (NSString *value in q.params) {
                            sqlite3_bind_text(stmt, index++, [value UTF8String], -1, SQLITE_STATIC);
                        }
                        
                        
                    }else {
                        NSLog(@"execute insert");
                        
                        if(!sqlite3_prepare(sqlitedb, [q.insertQuery UTF8String], -1, &stmt, NULL) != SQLITE_OK){
                            [self.delegate onError: [NSString stringWithFormat:@"error prepare stmt %@ - %@", q.insertQuery, sqlite3_errmsg(sqlitedb)]];
                            return;
                            
                        }
                        
                        for (NSString *value in q.params) {
                            sqlite3_bind_text(stmt, index++, [value UTF8String], -1, SQLITE_STATIC);
                        }
                        
                    }
                    
                    if(sqlite3_step(stmt) != SQLITE_DONE){
                        [self.delegate onError: [NSString stringWithFormat:@"error run query %@ - %@", q.insertQuery, sqlite3_errmsg(sqlitedb)]];
                        return;
                    }

                    sqlite3_reset(stmt);
                }
                
            }
            
            sqlite3_finalize(stmt);
            sqlite3_close(sqlitedb);
            
            
            [self.delegate onComplete:nil];
            
        } @catch (NSException *exception) {
            [self.delegate onError: [exception reason]];
        }
        
        
    });
}


@end
