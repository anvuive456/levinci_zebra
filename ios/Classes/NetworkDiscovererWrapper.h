#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NetworkDiscovererWrapper : NSObject

+ (NSArray *)discoverWithHops:(nullable NSNumber *)hops error:(NSError **)error;
+ (NSArray *)localBroadcastWithError:(NSError **)error;
+ (NSArray *)discoverByLanWithError:(NSError **)error;
+ (NSArray *)discoverByBroadcastWithError:(NSError **)error;
+ (NSArray *)discoverByHops:(nullable NSNumber *)hops error:(NSError **)error;

@end

NS_ASSUME_NONNULL_END
