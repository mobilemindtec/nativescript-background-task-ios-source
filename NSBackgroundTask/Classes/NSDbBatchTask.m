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

-(void) setDebug:(BOOL)debug{
    _debug = debug;
}

-(void) addQuery:(NSQuery *)query{
    [_queries addObject:query];
}

-(void) runTask{
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        if(_debug)
            NSLog(@"use db path %@", _dbPath);
        
        sqlite3 *sqlitedb;
        sqlite3_stmt *stmt;

        @try {
            
            if(sqlite3_open([_dbPath UTF8String], &sqlitedb) != SQLITE_OK){
                [self.delegate onError: [NSString stringWithFormat:@"error open database %s", sqlite3_errmsg(sqlitedb)]];
                return;
            }
            
            if(_debug)
                NSLog(@"database open successful");
            
            sqlite3_exec(sqlitedb, "BEGIN EXCLUSIVE TRANSACTION", 0, 0, 0);
            
            if(_debug)
                NSLog(@"database begin transcation successful");
            
            for (NSQuery *q in _queries) {
                
                int index = 1;
                
                if(q.query){
                    
                    if(_debug)
                        NSLog(@"execute normal query");
                    
                    if(sqlite3_prepare(sqlitedb, [q.query UTF8String], -1, &stmt, NULL) != SQLITE_OK){
                        [self.delegate onError: [NSString stringWithFormat:@"error prepare stmt %@ - %s", q.query, sqlite3_errmsg(sqlitedb)]];
                        return;
                     
                    }
                    
                    if(_debug)
                        NSLog(@"database prepate stmt successful");
                    
                    for (NSString *value in q.params) {
                        sqlite3_bind_text(stmt, index++, [value UTF8String], -1, SQLITE_STATIC);
                    }
                    
                    if(_debug)
                        NSLog(@"database bind text successful");
                    
                    if(sqlite3_step(stmt) != SQLITE_DONE){
                        NSLog(@"error run query %@: %s", q.query, sqlite3_errmsg(sqlitedb));
                        [self.delegate onError: [NSString stringWithFormat:@"error run query %@ - %s", q.query, sqlite3_errmsg(sqlitedb)]];
                        return;
                    }
                    
                    if(_debug)
                        NSLog(@"database execute stmt successful");
                    
                    sqlite3_reset(stmt);
                    
                }else {
                    
                    
                    NSString *sql = [NSString stringWithFormat:@"select id from %@ where %@ = ?", q.tableName, q.updateKey];
                    
                    if(_debug)
                        NSLog(@"execute insert or update query: %@", sql);
                    
                    if(sqlite3_prepare(sqlitedb, [sql UTF8String], -1, &stmt, NULL) != SQLITE_OK){
                        [self.delegate onError: [NSString stringWithFormat:@"error prepare stmt %@ - %s", q.query, sqlite3_errmsg(sqlitedb)]];
                        return;
                        
                    }
                    
                    if(!q.updateKeyDataType || [@"text" isEqualToString:q.updateKeyDataType]){
                        if(_debug)
                            NSLog(@"use text update key data type");
                        sqlite3_bind_text(stmt, 1, [q.updateKeyValue UTF8String], -1, SQLITE_STATIC);
                    }else if([@"int" isEqualToString:q.updateKeyDataType]){
                        if(_debug)
                            NSLog(@"use int update key data type");
                        sqlite3_bind_int(stmt, 1, [q.updateKeyValue integerValue]);
                    }else if([@"doble" isEqualToString:q.updateKeyDataType]){
                        if(_debug)
                            NSLog(@"use double update key data type");
                        sqlite3_bind_double(stmt, 1, [q.updateKeyValue doubleValue]);
                    }

                    NSNumber *rowid = 0;
                    
                    if(sqlite3_step(stmt) == SQLITE_ROW){
                        rowid = [NSNumber numberWithInt:sqlite3_column_int(stmt, 0)];
                        if(_debug)
                            NSLog(@"select rowid %d", rowid);
                    }else{
                        if(_debug)
                            NSLog(@"no rows in select");
                    }
                    
                    sqlite3_reset(stmt);
                    
                    if(rowid > 0){
                    
                        if(_debug)
                            NSLog(@"execute update id %@", [rowid stringValue]);
                        
                        NSMutableArray *params = [NSMutableArray array];
                        
                        for(NSString *it in q.params){
                            [params addObject:it];
                        }
                        
                        [params addObject: [rowid stringValue]];
                        
                        if(sqlite3_prepare(sqlitedb, [q.updateQuery UTF8String], -1, &stmt, NULL) != SQLITE_OK){
                            [self.delegate onError: [NSString stringWithFormat:@"error prepare stmt %@ - %s", q.updateQuery, sqlite3_errmsg(sqlitedb)]];
                            return;
                            
                        }
                        
                        for (NSString *value in params) {
                            sqlite3_bind_text(stmt, index++, [value UTF8String], -1, SQLITE_STATIC);
                        }
                        
                        
                    }else {
                        if(_debug)
                            NSLog(@"execute insert");
                        
                        if(sqlite3_prepare(sqlitedb, [q.insertQuery UTF8String], -1, &stmt, NULL) != SQLITE_OK){
                            [self.delegate onError: [NSString stringWithFormat:@"error prepare stmt %@ - %s", q.insertQuery, sqlite3_errmsg(sqlitedb)]];
                            return;
                            
                        }
                        
                        for (NSString *value in q.params) {
                            sqlite3_bind_text(stmt, index++, [value UTF8String], -1, SQLITE_STATIC);
                        }
                        
                    }
                    
                    if(sqlite3_step(stmt) != SQLITE_DONE){
                        [self.delegate onError: [NSString stringWithFormat:@"error run query %@ - %s", q.insertQuery, sqlite3_errmsg(sqlitedb)]];
                        return;
                    }

                    sqlite3_reset(stmt);
                }
                
            }
            
            if (sqlite3_exec(sqlitedb, "COMMIT TRANSACTION", 0, 0, 0) != SQLITE_OK){
                [self.delegate onError: [NSString stringWithFormat:@"error commit transaction %s", sqlite3_errmsg(sqlitedb)]];
                return;

            }
            
            if(_debug)
                NSLog(@"database commit transcation successful");
            
            [self.delegate onComplete:nil];
            
        } @catch (NSException *exception) {
            [self.delegate onError: [exception reason]];
        } @finally {
            
            if(stmt)
                sqlite3_finalize(stmt);
            
            if(sqlitedb)
                sqlite3_close(sqlitedb);
        }
        
        
    });
}


@end
