//
//  StoryMapDatabase.m
//  StoryMap1
//
//  Created by Frank on 8/29/13.
//  Copyright (c) 2013 Esri. All rights reserved.
//

#import <sqlite3.h> // Import the SQLite database framework
#import "StoryMapDatabase.h"
#import "TileServiceInfo.h"
#import "TrackInfo.h"
#import "StoryMapUtil.h"

#define STORYMAPDATABASENAME @"storymaps.sqlite"

@implementation StoryMapDatabase

// we use the singleton approach, one collection for the entire application
static StoryMapDatabase *sharedStoryMapDatabaseInstance = nil;

+ (StoryMapDatabase*)sharedStoryMapDatabase
{
    @synchronized(self) {
        static dispatch_once_t pred;
        dispatch_once(&pred, ^{ sharedStoryMapDatabaseInstance = [[self alloc] init]; });
    }
    return sharedStoryMapDatabaseInstance;
}

+ (id)allocWithZone:(NSZone *)zone {
    @synchronized(self) {
        if (sharedStoryMapDatabaseInstance == nil) {
            sharedStoryMapDatabaseInstance = [super allocWithZone:zone];
            return sharedStoryMapDatabaseInstance;  // assignment and return on first allocation
        }
    }
    return nil; //on subsequent allocation attempts return nil
}

- (id)copyWithZone:(NSZone *)zone {
    return self;
}

// setup the data collection
- init {
	if (self = [super init]) {
		[self setupStoryMapDatabase];
	}
	return self;
}

- (NSString*)getStoryMapDatabasePath
{
    NSString *rootPath = [StoryMapUtil getCacheRootPath];
    NSString *storyDatabasePath = [NSString stringWithFormat:@"%@/%@",rootPath, STORYMAPDATABASENAME];
    return storyDatabasePath;
}

-(void)setupStoryMapDatabase
{
    NSString *storyDatabasePathInDocuments = [self getStoryMapDatabasePath];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:storyDatabasePathInDocuments]) {
        NSError *err;
        NSString *storyDatabasePathInBundle = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:STORYMAPDATABASENAME];
        [[NSFileManager defaultManager] copyItemAtPath:storyDatabasePathInBundle toPath:storyDatabasePathInDocuments error:&err];
        if (err) {
            NSLog(@"%@", err);
        }
    }
    self.storyMapInfos = nil;
    self.tileServiceInfos = nil;
    [self readStoryMapInfoFromDatabase];
    [self readTileServiceInfoFromDatabase];
    [self readStoryMapTrackInfoFromDatabase];
}

- (void)readStoryMapTrackInfoFromDatabase {
    //
    // read story map info from database
    //
    NSString *storyDatabasePath = [self getStoryMapDatabasePath];
    
    NSMutableArray *tmpArray = [[NSMutableArray alloc] initWithCapacity:5];
    // Setup the database object
	sqlite3 *storyDatabase;
    
    int rowId = 0;
    // Open the database from the users filessytem
	if(sqlite3_open([storyDatabasePath UTF8String], &storyDatabase) == SQLITE_OK) {
		// Setup the SQL Statement and compile it for faster access
		const char *sqlStatement = "SELECT * FROM STORY_TRACKS";
		sqlite3_stmt *compiledStatement;
		if(sqlite3_prepare_v2(storyDatabase, sqlStatement, -1, &compiledStatement, NULL) == SQLITE_OK) {
			// Loop through the results and add them to the feeds array
			while(sqlite3_step(compiledStatement) == SQLITE_ROW) {
				// Read the data from the result row
                NSString *name = [NSString stringWithUTF8String:(char *)sqlite3_column_text(compiledStatement, 0)];
                NSString *storyName= [NSString stringWithUTF8String:(char *)sqlite3_column_text(compiledStatement, 1)];
				NSString *layerDesc = [NSString stringWithUTF8String:(char *)sqlite3_column_text(compiledStatement, 2)];
                NSString *layerFeatures = [NSString stringWithUTF8String:(char *)sqlite3_column_text(compiledStatement, 3)];
                
                TrackInfo *info = [[TrackInfo alloc] init];
                info.name = name;
                info.storyName = storyName;
                info.layerDesc = layerDesc;
                info.layerFeatures = layerFeatures;
                
                [tmpArray addObject:info];
                rowId++;
			}
		}
		// Release the compiled statement from memory
		sqlite3_finalize(compiledStatement);
        sqlite3_close(storyDatabase);
	}else{
        NSLog(@"failed to open the story map database");
    }
	
    NSLog(@"Total story map track infos=%d", rowId);
    NSSortDescriptor *sortDescriptor;
    sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"storyName" ascending:YES];
    NSArray *sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
    self.storyMapTrackInfos = [tmpArray sortedArrayUsingDescriptors:sortDescriptors];
    NSLog(@"# of tmps=%d, # of track infos=%d", [tmpArray count], [self.storyMapTrackInfos count]);
}

- (void)readStoryMapInfoFromDatabase {
    //
    // read story map info from database
    //
    NSString *storyDatabasePath = [self getStoryMapDatabasePath];

    NSMutableArray *tmpArray = [[NSMutableArray alloc] initWithCapacity:10];
    // Setup the database object
	sqlite3 *storyDatabase;
    
    int rowId = 0;
    // Open the database from the users filessytem
	if(sqlite3_open([storyDatabasePath UTF8String], &storyDatabase) == SQLITE_OK) {
		// Setup the SQL Statement and compile it for faster access
		const char *sqlStatement = "SELECT * FROM STORY_MAPS";
		sqlite3_stmt *compiledStatement;
		if(sqlite3_prepare_v2(storyDatabase, sqlStatement, -1, &compiledStatement, NULL) == SQLITE_OK) {
			// Loop through the results and add them to the feeds array
			while(sqlite3_step(compiledStatement) == SQLITE_ROW) {
				// Read the data from the result row
                NSString *title = [NSString stringWithUTF8String:(char *)sqlite3_column_text(compiledStatement, 0)];
                NSString *url = [NSString stringWithUTF8String:(char *)sqlite3_column_text(compiledStatement, 1)];
				NSString *webmapId = [NSString stringWithUTF8String:(char *)sqlite3_column_text(compiledStatement, 2)];
                NSString *description = [NSString stringWithUTF8String:(char *)sqlite3_column_text(compiledStatement, 3)];
                NSString *poiTable = [NSString stringWithUTF8String:(char *)sqlite3_column_text(compiledStatement, 4)];
                NSString *folderName = [NSString stringWithUTF8String:(char *)sqlite3_column_text(compiledStatement, 5)];
                
                StoryMapInfo *info = [[StoryMapInfo alloc] init];
                info.title = title;
                info.url = url;
                info.webmapId = webmapId;
                info.description = description;
                info.poiTableName = poiTable;
                info.folderName = folderName;
                                
                char* tmp = (char *)sqlite3_column_text(compiledStatement, 6);
                if(tmp){
                    NSString *urlstring = [NSString stringWithUTF8String:tmp];
                    info.tileServiceUrl1 = urlstring;
                }
                
                tmp = (char *)sqlite3_column_text(compiledStatement, 7);
                if(tmp){
                    NSString *urlstring = [NSString stringWithUTF8String:tmp];
                    info.tileServiceUrl2 = urlstring;
                }
                
                tmp = (char *)sqlite3_column_text(compiledStatement, 8);
                if(tmp){
                    NSString *urlstring = [NSString stringWithUTF8String:tmp];
                    info.tileServiceUrl3 = urlstring;
                }
                
                tmp = (char *)sqlite3_column_text(compiledStatement, 9);
                if(tmp){
                    NSString *urlstring = [NSString stringWithUTF8String:tmp];
                    info.tileServiceUrl4 = urlstring;
                }
                
                tmp = (char *)sqlite3_column_text(compiledStatement, 10);
                if(tmp){
                    NSString *urlstring = [NSString stringWithUTF8String:tmp];
                    info.envelope = urlstring;
                }
                
                [tmpArray addObject:info];
                rowId++;
			}
		}
		// Release the compiled statement from memory
		sqlite3_finalize(compiledStatement);
        sqlite3_close(storyDatabase);
	}else{
        NSLog(@"failed to open the story map database");
    }
	
    NSLog(@"Total story map infos=%d", rowId);
    NSSortDescriptor *sortDescriptor;
    sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"title" ascending:YES];
    NSArray *sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
    self.storyMapInfos = [tmpArray sortedArrayUsingDescriptors:sortDescriptors];
    NSLog(@"# of tmps=%d, # of infos=%d", [tmpArray count], [self.storyMapInfos count]);
}


- (BOOL) addStoryMap:(StoryMapInfo*)storyMapInfo {
    NSString *storyDatabasePath = [self getStoryMapDatabasePath];
  
    // Setup the database object
	sqlite3 *storyDatabase;
    BOOL success = NO;
    // Open the database from the users filessytem
	if(sqlite3_open([storyDatabasePath UTF8String], &storyDatabase) == SQLITE_OK) {
		sqlite3_stmt *compiledStatement;
        NSString *insertSQL = [NSString stringWithFormat: @"INSERT INTO STORY_MAPS (Title, URL, WebMapID, DESCRIPTION, POITable, FolderName, TileServiceUrl1, TileServiceUrl2, TileServiceUrl3,TileServiceUrl4, InitEnvelope) VALUES ('%@', '%@', '%@', '%@', '%@', '%@', '%@', '%@', '%@', '%@', '%@')", storyMapInfo.title, storyMapInfo.url, storyMapInfo.webmapId, storyMapInfo.description, storyMapInfo.poiTableName, storyMapInfo.folderName, storyMapInfo.tileServiceUrl1, storyMapInfo.tileServiceUrl2, storyMapInfo.tileServiceUrl3, storyMapInfo.tileServiceUrl4, storyMapInfo.envelope];
        NSLog(@"%@", insertSQL);
        const char *insert_stmt = [insertSQL UTF8String];
        sqlite3_prepare_v2(storyDatabase, insert_stmt, -1, &compiledStatement, NULL);
        if (sqlite3_step(compiledStatement) == SQLITE_DONE)
        {
            NSLog(@"Insert story map succeed!");
            success = YES;
        } else {
            NSLog(@"Insert story map failed!");
            success = NO;
        }
        
        sqlite3_finalize(compiledStatement);
        sqlite3_close(storyDatabase);
    }else {
        NSLog(@"failed to open the story map database");        
    }
    
    
    if (success) {
        success = [self createStoryMapTable:storyMapInfo.poiTableName];
        [self readStoryMapInfoFromDatabase];
    }
    
    return success;
}

- (BOOL) updateStoryMapInfo:(StoryMapInfo*)storyMapInfo withEnvelope:(NSString*)envelopeJson
{
    NSString *storyDatabasePath = [self getStoryMapDatabasePath];
    
    // Setup the database object
	sqlite3 *storyDatabase;
    BOOL success = NO;
    // Open the database from the users filessytem
	if(sqlite3_open([storyDatabasePath UTF8String], &storyDatabase) == SQLITE_OK) {
		sqlite3_stmt *compiledStatement;
        NSString *updateSQL = [NSString stringWithFormat: @"UPDATE STORY_MAPS SET InitEnvelope = '%@' WHERE URL = '%@'", envelopeJson, storyMapInfo.url];
        
        NSLog(@"Update SQL=>%@", updateSQL);
        const char *insert_stmt = [updateSQL UTF8String];
        sqlite3_prepare_v2(storyDatabase, insert_stmt, -1, &compiledStatement, NULL);
        if (sqlite3_step(compiledStatement) == SQLITE_DONE)
        {
            NSLog(@"Update story map envelope succeed!");
            success = YES;
        } else {
            NSLog(@"Update story map envelope failed!");
            success = NO;
        }
        
        sqlite3_finalize(compiledStatement);
        sqlite3_close(storyDatabase);
    }else {
        NSLog(@"failed to open the story map database");
    }
    
    if (success) {
        [self readStoryMapInfoFromDatabase];
    }
    
    return success;
}

- (BOOL) updateStoryMapInfo:(StoryMapInfo*)storyMapInfo withBaseMapIndex:(int)index {
    NSString *storyDatabasePath = [self getStoryMapDatabasePath];
    
    // Setup the database object
	sqlite3 *storyDatabase;
    BOOL success = NO;
    // Open the database from the users filessytem
	if(sqlite3_open([storyDatabasePath UTF8String], &storyDatabase) == SQLITE_OK) {
		sqlite3_stmt *compiledStatement;
        NSString *insertSQL = [NSString stringWithFormat: @"UPDATE STORY_MAPS SET TileServiceUrl1 = '%@' WHERE URL = '%@'", storyMapInfo.tileServiceUrl1,  storyMapInfo.url];
        if (index==2) {
            insertSQL = [NSString stringWithFormat: @"UPDATE STORY_MAPS SET TileServiceUrl2 = '%@' WHERE URL = '%@'", storyMapInfo.tileServiceUrl2, storyMapInfo.url];
        }else if (index==3) {
            insertSQL = [NSString stringWithFormat: @"UPDATE STORY_MAPS SET TileServiceUrl3 = '%@' WHERE URL = '%@'", storyMapInfo.tileServiceUrl3, storyMapInfo.url];
        }else if (index==4) {
            insertSQL = [NSString stringWithFormat: @"UPDATE STORY_MAPS SET TileServiceUrl4 = '%@' WHERE URL = '%@'", storyMapInfo.tileServiceUrl4, storyMapInfo.url];
        }
            
        NSLog(@"Update SQL=>%@", insertSQL);
        const char *insert_stmt = [insertSQL UTF8String];
        sqlite3_prepare_v2(storyDatabase, insert_stmt, -1, &compiledStatement, NULL);
        if (sqlite3_step(compiledStatement) == SQLITE_DONE)
        {
            NSLog(@"Update story map succeed!");
            success = YES;
        } else {
            NSLog(@"Update story map failed!");
            success = NO;
        }
        
        sqlite3_finalize(compiledStatement);
        sqlite3_close(storyDatabase);
    }else {
        NSLog(@"failed to open the story map database");
    }
    
    if(success) {
        [self readStoryMapInfoFromDatabase];
    }
    
    return success;
}

- (BOOL) updateStoryMapInfo:(StoryMapInfo*)storyMapInfo withTile:(NSString*)title andDescription:(NSString*)description
{
    NSString *storyDatabasePath = [self getStoryMapDatabasePath];
    
    // Setup the database object
	sqlite3 *storyDatabase;
    BOOL success = NO;
    // Open the database from the users filessytem
	if(sqlite3_open([storyDatabasePath UTF8String], &storyDatabase) == SQLITE_OK) {
		sqlite3_stmt *compiledStatement;
        NSString *updateSQL = [NSString stringWithFormat: @"UPDATE STORY_MAPS SET Title = '%@', Description = '%@' WHERE URL = '%@'", title, description, storyMapInfo.url];
        
        NSLog(@"Update SQL=>%@", updateSQL);
        const char *insert_stmt = [updateSQL UTF8String];
        sqlite3_prepare_v2(storyDatabase, insert_stmt, -1, &compiledStatement, NULL);
        if (sqlite3_step(compiledStatement) == SQLITE_DONE)
        {
            NSLog(@"Update story map title succeed!");
            success = YES;
        } else {
            NSLog(@"Update story map title failed!");
            success = NO;
        }
        
        sqlite3_finalize(compiledStatement);
        sqlite3_close(storyDatabase);
    }else {
        NSLog(@"failed to open the story map database");
    }
    
    if (success) {
        [self readStoryMapInfoFromDatabase];
    }
    
    return success;
}

- (BOOL) removeStoryMap:(NSString*)storyMapUrl andStoryTable:(NSString*)name {
    NSString *storyDatabasePath = [self getStoryMapDatabasePath];
    
    // Setup the database object
	sqlite3 *storyDatabase;
    BOOL success = NO;
    
    // Open the database from the users filessytem
	if(sqlite3_open([storyDatabasePath UTF8String], &storyDatabase) == SQLITE_OK) {
		sqlite3_stmt *compiledStatement;
        NSString *sql_stmt_string = [NSString stringWithFormat:@"DELETE FROM STORY_MAPS WHERE URL = '%@'", storyMapUrl];
        const char *sql_stmt = [sql_stmt_string cStringUsingEncoding:NSUTF8StringEncoding];
        sqlite3_prepare_v2(storyDatabase, sql_stmt, -1, &compiledStatement, NULL);
        if (sqlite3_step(compiledStatement) == SQLITE_DONE)
        {
            NSLog(@"Delete story map succeed!");
            success = YES;
        } else {
            NSLog(@"Delete story map failed!");
            success = NO;
        }
        sqlite3_finalize(compiledStatement);
        sqlite3_close(storyDatabase);
	}else{
        NSLog(@"failed to open the story map database");
    }
    
    // drop story map table
    if(success){
        success = [self dropStoryMapTable:name];
        [self readStoryMapInfoFromDatabase];
    }
    
    return success;
}

- (BOOL) createStoryMapTable:(NSString*)name {
    NSString *storyDatabasePath = [self getStoryMapDatabasePath];
    
    // Setup the database object
	sqlite3 *storyDatabase;
    BOOL success = NO;
    
    // Open the database from the users filessytem
	if(sqlite3_open([storyDatabasePath UTF8String], &storyDatabase) == SQLITE_OK) {
        char *errMsg;
        NSString *create_stmt = [NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS %@ (\"ID\" INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, \"INDEX\" INTEGER,  \"NAME\" TEXT, \"DESCRIPTION\" TEXT, \"LAT\" DOUBLE, \"LON\" DOUBLE, \"URL\" TEXT, \"URL_LOCAL\" TEXT, \"THUMBNAIL_URL\" TEXT, \"THUMBNAIL_URL_LOCAL\" TEXT, \"ICON_COLOR\" TEXT)", name];
        const char *sql_stmt = [create_stmt cStringUsingEncoding:NSUTF8StringEncoding];
        
        if (sqlite3_exec(storyDatabase, sql_stmt, NULL, NULL, &errMsg) != SQLITE_OK)
        {
            NSLog(@"Failed to create POI table: %@", name);
        }else {
            success = YES;
            NSLog(@"Created POI table: %@", name);
        }
        sqlite3_close(storyDatabase);
    }
    else{
        NSLog(@"failed to open the story map database");
    }
    
    return success;
}

- (BOOL) dropStoryMapTable:(NSString*)name {
    NSString *storyDatabasePath = [self getStoryMapDatabasePath];
    
    // Setup the database object
	sqlite3 *storyDatabase;
    BOOL success = NO;
    // Open the database from the users filessytem
	if(sqlite3_open([storyDatabasePath UTF8String], &storyDatabase) == SQLITE_OK) {
        char *errMsg;
        NSString *create_stmt = [NSString stringWithFormat:@"DROP TABLE %@", name];
        const char *sql_stmt = [create_stmt cStringUsingEncoding:NSUTF8StringEncoding];
        
        if (sqlite3_exec(storyDatabase, sql_stmt, NULL, NULL, &errMsg) != SQLITE_OK)
        {
            NSLog(@"Failed to drop POI table");
        }else{
            success = YES;
        }
        sqlite3_close(storyDatabase);
    }
    else{
        NSLog(@"failed to open the story map database");
    }
    
    return success;
}

- (BOOL) addPOI:(POIInfo*)poiInfo toTable:(NSString*)name {
    NSString *storyDatabasePath = [self getStoryMapDatabasePath];
    
    // Setup the database object
	sqlite3 *storyDatabase;
    BOOL success = NO;
    
    @synchronized (self) {
    
    // Open the database from the users filessytem
	if(sqlite3_open([storyDatabasePath UTF8String], &storyDatabase) == SQLITE_OK) {
		sqlite3_stmt *compiledStatement;
        
        NSString *insertSQL = [NSString stringWithFormat: @"INSERT INTO %@ (\"INDEX\", NAME, DESCRIPTION, LAT, LON, URL, URL_LOCAL, THUMBNAIL_URL, THUMBNAIL_URL_LOCAL, ICON_COLOR) VALUES (%d, '%@', '%@', %f, %f, '%@', '%@', '%@', '%@', '%@')", name, poiInfo.index, poiInfo.name, poiInfo.description, poiInfo.lat, poiInfo.lon, poiInfo.url, poiInfo.url_local, poiInfo.thumbnail_url, poiInfo.thumbnail_url_local, poiInfo.icon_color];
        NSLog(@"%@", insertSQL);
        const char *insert_stmt = [insertSQL UTF8String];
        sqlite3_prepare_v2(storyDatabase, insert_stmt, -1, &compiledStatement, NULL);
        if (sqlite3_step(compiledStatement) == SQLITE_DONE)
        {
            NSLog(@"Insert POI succeed!");
            success = YES;
        } else {
            NSLog(@"Insert POI failed!");
            success = NO;
        }

        sqlite3_finalize(compiledStatement);
        sqlite3_close(storyDatabase);
    }else {
        NSLog(@"failed to open the story map database");
    }
        
    }
    
    return success;
}

- (NSArray*) readPOIInfoFromDatabase:(NSString*)tableName {
    //
    // read story map info from database
    //
    NSString *storyDatabasePath = [self getStoryMapDatabasePath];
    
    NSMutableArray *poiInfos = [[NSMutableArray alloc] initWithCapacity:50];
    
    // Setup the database object
	sqlite3 *storyDatabase;
    
    int rowId = 0;
    // Open the database from the users filessytem
	if(sqlite3_open([storyDatabasePath UTF8String], &storyDatabase) == SQLITE_OK) {
		// Setup the SQL Statement and compile it for faster access
        NSString *selectSQL = [NSString stringWithFormat: @"SELECT * FROM %@", tableName];
		const char *sqlStatement = [selectSQL UTF8String];
        
		sqlite3_stmt *compiledStatement;
		if(sqlite3_prepare_v2(storyDatabase, sqlStatement, -1, &compiledStatement, NULL) == SQLITE_OK) {
			// Loop through the results and add them to the feeds array
			while(sqlite3_step(compiledStatement) == SQLITE_ROW) {
				// Read the data from the result row
                int index = sqlite3_column_int(compiledStatement, 1);
                NSString *name = [NSString stringWithUTF8String:(char *)sqlite3_column_text(compiledStatement, 2)];
				NSString *description = [NSString stringWithUTF8String:(char *)sqlite3_column_text(compiledStatement, 3)];
                double lat = sqlite3_column_double(compiledStatement, 4);
                double lon = sqlite3_column_double(compiledStatement, 5);
                NSString *url = [NSString stringWithUTF8String:(char *)sqlite3_column_text(compiledStatement, 6)];
                NSString *url_local = [NSString stringWithUTF8String:(char *)sqlite3_column_text(compiledStatement, 7)];
                NSString *thumbnailurl = [NSString stringWithUTF8String:(char *)sqlite3_column_text(compiledStatement, 8)];
                NSString *thumbnailurl_local = [NSString stringWithUTF8String:(char *)sqlite3_column_text(compiledStatement, 9)];
                NSString *icon_color = [NSString stringWithUTF8String:(char *)sqlite3_column_text(compiledStatement, 10)];
                
                POIInfo *info = [[POIInfo alloc] init];
                info.index = index;
                info.name = name;
                info.description = description;
                info.lat = lat;
                info.lon = lon;
                info.url_local = url_local;
                info.url = url;
                info.thumbnail_url = thumbnailurl;
                info.thumbnail_url_local = thumbnailurl_local;
                info.icon_color = icon_color;
                
                [poiInfos addObject:info];
                NSLog(@"name=%@, lon=%f, lat=%f", info.name, info.lon, info.lat);
                
                rowId++;
			}
		}
		// Release the compiled statement from memory
		sqlite3_finalize(compiledStatement);
        sqlite3_close(storyDatabase);
	}else{
        NSLog(@"failed to open the story map database");
    }
	
    NSLog(@"Total # of POIs=%d", [poiInfos count]);
    
    return poiInfos;
}

- (void) readTileServiceInfoFromDatabase {
    //
    // read story map info from database
    //
    NSString *storyDatabasePath = [self getStoryMapDatabasePath];
    NSMutableArray *tmpArray = [[NSMutableArray alloc] initWithCapacity:5];
    // Setup the database object
	sqlite3 *storyDatabase;
    
    int rowId = 0;
    // Open the database from the users filessytem
	if(sqlite3_open([storyDatabasePath UTF8String], &storyDatabase) == SQLITE_OK) {
		// Setup the SQL Statement and compile it for faster access
		const char *sqlStatement = "SELECT * FROM TILE_SERVICES";
		sqlite3_stmt *compiledStatement;
		if(sqlite3_prepare_v2(storyDatabase, sqlStatement, -1, &compiledStatement, NULL) == SQLITE_OK) {
			// Loop through the results and add them to the feeds array
			while(sqlite3_step(compiledStatement) == SQLITE_ROW) {
				// Read the data from the result row
                NSString *url = [NSString stringWithUTF8String:(char *)sqlite3_column_text(compiledStatement, 0)];
                NSString *tileInfo = [NSString stringWithUTF8String:(char *)sqlite3_column_text(compiledStatement, 1)];
				NSString *units = [NSString stringWithUTF8String:(char *)sqlite3_column_text(compiledStatement, 2)];
                NSString *initEnvelope = [NSString stringWithUTF8String:(char *)sqlite3_column_text(compiledStatement, 3)];
                NSString *fullEnvelope = [NSString stringWithUTF8String:(char *)sqlite3_column_text(compiledStatement, 4)];
                NSString *url_local = [NSString stringWithUTF8String:(char *)sqlite3_column_text(compiledStatement, 5)];
                NSString *format = [NSString stringWithUTF8String:(char *)sqlite3_column_text(compiledStatement, 6)];
                NSString *type = [NSString stringWithUTF8String:(char *)sqlite3_column_text(compiledStatement, 7)];
                
                TileServiceInfo *info = [[TileServiceInfo alloc] init];
                info.url_local = url_local;
                info.url = url;
                info.units = units;
                info.envelope = initEnvelope;
                info.fullEnvelope = fullEnvelope;
                info.tileInfo = tileInfo;
                info.format = format;
                info.type = type;
                
                [tmpArray addObject:info];
                
                rowId++;
			}
		}
		// Release the compiled statement from memory
		sqlite3_finalize(compiledStatement);
        sqlite3_close(storyDatabase);
	}else{
        NSLog(@"failed to open the story map database");
    }
	
    NSLog(@"Total tile service infos=%d", rowId);
    self.tileServiceInfos = tmpArray;
}

- (BOOL) addTileService:(TileServiceInfo*)tileServiceInfo {
    NSString *storyDatabasePath = [self getStoryMapDatabasePath];
    
    // Setup the database object
	sqlite3 *storyDatabase;
    BOOL success = NO;
    
    @synchronized (self) {
        
        // Open the database from the users filessytem
        if(sqlite3_open([storyDatabasePath UTF8String], &storyDatabase) == SQLITE_OK) {
            sqlite3_stmt *compiledStatement;
            
            NSString *insertSQL = [NSString stringWithFormat: @"INSERT INTO TILE_SERVICES (URL, TILEINFO, UNITS, INIT_ENVELOPE, FULL_ENVELOPE, URL_LOCAL, FORMAT, TYPE) VALUES ('%@', '%@', '%@', '%@', '%@', '%@', '%@', '%@')", tileServiceInfo.url, tileServiceInfo.tileInfo, tileServiceInfo.units, tileServiceInfo.envelope, tileServiceInfo.fullEnvelope, tileServiceInfo.url_local, tileServiceInfo.format, tileServiceInfo.type];
            NSLog(@"%@", insertSQL);
            const char *insert_stmt = [insertSQL UTF8String];
            sqlite3_prepare_v2(storyDatabase, insert_stmt, -1, &compiledStatement, NULL);
            if (sqlite3_step(compiledStatement) == SQLITE_DONE)
            {
                NSLog(@"Insert tile service info succeed!");
                success = YES;
            } else {
                NSLog(@"Insert tile service info failed!");
                success = NO;
            }
            
            sqlite3_finalize(compiledStatement);
            sqlite3_close(storyDatabase);
        }else {
            NSLog(@"failed to open the story map database");
        }
        
    }
    
    if (success) {
        [self readTileServiceInfoFromDatabase];
    }
    
    return success;
}

- (BOOL) removeTileService:(NSString*)serviceUrl {
    NSString *storyDatabasePath = [self getStoryMapDatabasePath];
    
    // Setup the database object
	sqlite3 *storyDatabase;
    BOOL success = NO;
    
    @synchronized (self) {
        // Open the database from the users filessytem
        if(sqlite3_open([storyDatabasePath UTF8String], &storyDatabase) == SQLITE_OK) {
            sqlite3_stmt *compiledStatement;
            NSString *sql_stmt_string = [NSString stringWithFormat:@"DELETE FROM TILE_SERVICES WHERE URL = '%@'", serviceUrl];
            const char *sql_stmt = [sql_stmt_string cStringUsingEncoding:NSUTF8StringEncoding];
            sqlite3_prepare_v2(storyDatabase, sql_stmt, -1, &compiledStatement, NULL);
            if (sqlite3_step(compiledStatement) == SQLITE_DONE)
            {
                NSLog(@"Delete tile service info succeed!");
                success = YES;
            } else {
                NSLog(@"Delete tile service info failed!");
                success = NO;
            }
            sqlite3_finalize(compiledStatement);
            sqlite3_close(storyDatabase);
        }else{
            NSLog(@"failed to open the story map database");
        }
    
    }
    if(success){
        [self readTileServiceInfoFromDatabase];
    }
    
    return success;
}

- (BOOL) addStoryMapTrack:(TrackInfo*)trackInfo {
    NSString *storyDatabasePath = [self getStoryMapDatabasePath];
    
    // Setup the database object
	sqlite3 *storyDatabase;
    BOOL success = NO;
    
    @synchronized (self) {
        
        // Open the database from the users filessytem
        if(sqlite3_open([storyDatabasePath UTF8String], &storyDatabase) == SQLITE_OK) {
            sqlite3_stmt *compiledStatement;
            
            NSString *insertSQL = [NSString stringWithFormat: @"INSERT INTO STORY_TRACKS (NAME, STORYMAP, LAYER_DESC, LAYER_FEATURES) VALUES ('%@', '%@', '%@', '%@')", trackInfo.name, trackInfo.storyName, trackInfo.layerDesc, trackInfo.layerFeatures];
            //NSLog(@"%@", insertSQL);
            const char *insert_stmt = [insertSQL UTF8String];
            sqlite3_prepare_v2(storyDatabase, insert_stmt, -1, &compiledStatement, NULL);
            if (sqlite3_step(compiledStatement) == SQLITE_DONE)
            {
                NSLog(@"Insert track info succeed!");
                success = YES;
            } else {
                NSLog(@"Insert track info failed!");
                success = NO;
            }
            
            sqlite3_finalize(compiledStatement);
            sqlite3_close(storyDatabase);
        }else {
            NSLog(@"failed to open the story map database");
        }
        
    }
    
    if (success) {
        [self readStoryMapTrackInfoFromDatabase];
    }
    
    return success;
}

- (BOOL) removeStoryMapTracks:(NSString*)storyMapName {
    NSString *storyDatabasePath = [self getStoryMapDatabasePath];
    
    // Setup the database object
	sqlite3 *storyDatabase;
    BOOL success = NO;
    
    // Open the database from the users filessytem
	if(sqlite3_open([storyDatabasePath UTF8String], &storyDatabase) == SQLITE_OK) {
		sqlite3_stmt *compiledStatement;
        NSString *sql_stmt_string = [NSString stringWithFormat:@"DELETE FROM STORY_TRACKS WHERE STORYMAP = '%@'", storyMapName];
        const char *sql_stmt = [sql_stmt_string cStringUsingEncoding:NSUTF8StringEncoding];
        sqlite3_prepare_v2(storyDatabase, sql_stmt, -1, &compiledStatement, NULL);
        if (sqlite3_step(compiledStatement) == SQLITE_DONE)
        {
            NSLog(@"Delete tracks for story map succeed!");
            success = YES;
        } else {
            NSLog(@"Delete tracks for story map failed!");
            success = NO;
        }
        sqlite3_finalize(compiledStatement);
        sqlite3_close(storyDatabase);
	}else{
        NSLog(@"failed to open the story map database");
    }
    
    if(success) {
        [self readStoryMapTrackInfoFromDatabase];
    }
    
    return success;
}

@end
