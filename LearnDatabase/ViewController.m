//
//  ViewController.m
//  LearnDatabase
//
//  Created by loyinglin on 2019/6/28.
//  Copyright © 2019 Loying. All rights reserved.
//

#import "ViewController.h"
#import <sqlite3.h>
#import <FMDB.h>
#import <Security/Security.h>
#import "KeychainWrapper.h"
#import "KeychainConfiguration.h"
#import <CoreData/CoreData.h>
#import "CDUser+CoreDataProperties.h"
#import "CDUser+CoreDataClass.h"
#import "YYUser.h"

@interface ViewController ()

@property (nonatomic, strong) NSString *account;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self testSandBox];
    [self testSqlite];
    [self testFMDB];
    [self testKeychain];
    [self testCoreData];
    [self testFileManager];
    [self testUserDefault];
    [self testYYModel];
}

#pragma mark - NSUserDefault

- (void)testUserDefault {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    if ([userDefaults objectForKey:@"key_for_test"]) {
        NSLog(@"value for key_for_test: %@" ,[userDefaults objectForKey:@"key_for_test"]);
    }
    else {
        NSLog(@"empty value for key_for_test");
        [userDefaults setObject:@"test_value" forKey:@"key_for_test"];
    }
}

#pragma mark - NSFileManager & NSBundle
- (void)testFileManager {
    NSBundle * mainBundle = [NSBundle mainBundle];
    NSString *plistPath =[mainBundle pathForResource:@"Info" ofType:@"plist"];
    NSLog(@"plist path: %@", plistPath);
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error;
    [fileManager copyItemAtPath:plistPath toPath:[NSHomeDirectory() stringByAppendingPathComponent:@"sandbox.plist"] error:&error];
    NSLog(@"copy error: %@", error); // 应用目录copy数据到沙盒中
}

#pragma mark - sandbox

- (void)testSandBox {
    // 获取沙盒根目录路径
    NSString *homeDir = NSHomeDirectory();
    NSLog(@"homeDir: %@", homeDir);
    // 获取Documents目录路径
    NSString *docDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask,YES) firstObject];
    NSLog(@"docDir: %@", docDir);
    //获取Library的目录路径
    NSString *libDir = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory,NSUserDomainMask,YES) lastObject];
    NSLog(@"libDir: %@", libDir);
    // 获取cache目录路径
    NSString *cachesDir = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory,NSUserDomainMask,YES) firstObject];
    NSLog(@"cachesDir: %@", cachesDir);
    // 获取tmp目录路径
    NSString *tmpDir =NSTemporaryDirectory();
    NSLog(@"tmpDir: %@", tmpDir);
}

- (void)testKeychain {
    KeychainWrapper *wrapper = [[KeychainWrapper alloc] initWithSevice:kKeychainService account:self.account accessGroup:kKeychainAccessGroup];
    NSString *saveStr = [wrapper readPassword];
    if (!saveStr) {
        [wrapper savePassword:@"test_password"];
    }
    NSLog(@"saveStr:%@", saveStr);
}

#pragma mark - sqlite 3
- (void)testSqlite {
    NSString *path = [NSHomeDirectory() stringByAppendingPathComponent:@"test_sqlite3.sqlite"];
    sqlite3 *database;
    sqlite3_open([path UTF8String], &database);
    NSLog(@"%@", path);
    
    const char *createSQL = "create table if not exists test_table_name(id integer primary key autoincrement,test_name_key char)";
    char *error;
    sqlite3_exec(database, createSQL, NULL, NULL, &error);
    NSLog(@"%s", error);
    
    // 具体过程
    sqlite3_stmt *stmt;
    const char *insertSQL = "insert into test_table_name(test_name_key) values('anyname')";
    int insertResult = sqlite3_prepare_v2(database, insertSQL, -1, &stmt, nil);
    if (insertResult == SQLITE_OK) {
        sqlite3_step(stmt);
    }
    
    // stmt是中间创建的结果，需要销毁
    sqlite3_finalize(stmt);
    // 关闭数据库，释放文件句柄等资源
    sqlite3_close(database);
}

#pragma mark - FMDB

- (void)testFMDB {
    NSString *path = [NSHomeDirectory() stringByAppendingPathComponent:@"test_fmdb.sqlite"];
    FMDatabase *db = [FMDatabase databaseWithPath:path]; // create
    [db open]; // open
    
    NSString *createSqlStr = @"create table if not exists test_table_name(id integer primary key autoincrement,test_name_key char)";
    [db executeUpdate:createSqlStr];
    
    NSString *insertSqlStr = @"insert into test_table_name(test_name_key) values('anyname')";
    [db executeUpdate:insertSqlStr];
    
    NSString *insertSqlStr2 = @"insert into test_table_name(test_name_key) values(?)";
    [db executeUpdate:insertSqlStr2, @"another_name"];
    
    FMDatabaseQueue *sqlQueue = [FMDatabaseQueue databaseQueueWithPath:path];
    [sqlQueue inDatabase:^(FMDatabase * _Nonnull db) {
        NSString *selectSqlStr = @"select id, test_name_key FROM test_table_name";
        FMResultSet *result = [db executeQuery:selectSqlStr];
        while ([result next]) {
            int value_id = [result intForColumn:@"id"];
            NSString *value_name = [result stringForColumn:@"test_name_key"];
            NSLog(@"id:%d, name:%@", value_id, value_name);
        }
    }];
    
}

#pragma mark - CoreData
- (void)testCoreData {
    //从本地加载对象模型
    NSString *path = [[NSBundle mainBundle] pathForResource:@"LearnCoreData" ofType:@"momd"];
    NSManagedObjectModel *model = [[NSManagedObjectModel alloc] initWithContentsOfURL:[NSURL fileURLWithPath:path]];
    NSLog(@"path:  %@", NSHomeDirectory());
    // 创建本地数据库
    NSPersistentStoreCoordinator* coord = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:model];
    path = [NSHomeDirectory() stringByAppendingPathComponent:@"database.sqlite"];
    [coord addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:[NSURL fileURLWithPath:path] options:nil error:nil];
    // 数据库关联缓存
    NSManagedObjectContext* objContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    objContext.persistentStoreCoordinator = coord;
    
    // 数据插入
    CDUser *user = [NSEntityDescription insertNewObjectForEntityForName:@"CDUser" inManagedObjectContext:objContext];
    user.name = [NSString stringWithFormat:@"name_%d", arc4random_uniform(100)];
    user.gender = arc4random_uniform(2);
    NSError *error;
    [objContext save:&error];
    
    NSFetchRequest *fetch = [[NSFetchRequest alloc] initWithEntityName:@"CDUser"];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"gender=1"]; //查询条件
    fetch.predicate = predicate;
    NSArray *results = [objContext executeFetchRequest:fetch error:nil];
    for (int i = 0; i < results.count; ++i) {
        CDUser *selectedUser = results[i];
        NSLog(@"name…:%@", selectedUser.name);
    }
}

#pragma mark - YYModel
- (void)testYYModel {
    NSDictionary *dic = @{
                          @"gender":@1,
                          @"userName": @"test_name",
                          };
    YYUser *user = (YYUser *)[YYUser yy_modelWithDictionary:dic];
    NSLog(@"user: %@", user);
    
    NSString *jsonStr = [user yy_modelToJSONString];
    NSLog(@"jsonStr: %@", jsonStr);
}

@end
