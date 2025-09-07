enum CacheControl {
  noCache,
  onlyCache,
  cacheFirstOrNetworkPut, // Use cache first. If not, request new data, and If not, request for data, and save into cache.没有缓存进行网络请求再存入缓存
  onlyNetworkPutCache, // Only use request, but also save into cache.
}
