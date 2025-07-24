#import "NetworkDiscovererWrapper.h"
#import "NetworkDiscoverer.h"

@implementation NetworkDiscovererWrapper

+ (NSArray *)discoverWithHops:(NSNumber *)hops error:(NSError **)error {
  if (hops != nil) {
    return [NetworkDiscoverer multicastWithHops:[hops integerValue]
                                          error:error];
  } else {
    return [NetworkDiscoverer localBroadcast:error];
  }
}

+ (NSArray *)localBroadcastWithError:(NSError **)error {
  return [NetworkDiscoverer localBroadcast:error];
}

+ (NSArray *)discoverByLanWithError:(NSError **)error {
  // Giả sử discoverByLan là multicast với hops = 1
  return [NetworkDiscoverer multicastWithHops:1 error:error];
}

+ (NSArray *)discoverByBroadcastWithError:(NSError **)error {
  return [NetworkDiscoverer localBroadcast:error];
}

+ (NSArray *)discoverByHops:(nullable NSNumber *)hops error:(NSError **)error {
  if (hops != nil) {
    return [NetworkDiscoverer multicastWithHops:[hops integerValue]
                                          error:error];
  } else {
    return [NetworkDiscoverer localBroadcast:error];
  }
}

@end
