CACHE_NAME = "sudokujs-#{VERSION}"
ASSETS = ['./', 'index.html', 'help.html', 'lib/index.js', 'fonts/saxmono.ttf', 'manifest.json']

# Caches the app shell
install = ->
  cache = await caches.open(CACHE_NAME)
  await cache.addAll(ASSETS)
  await self.skipWaiting()
  return

# Removes the caches of other versions
activate = ->
  names = await caches.keys()
  await Promise.all(caches.delete(name) for name in names when name != CACHE_NAME)
  await self.clients.claim()
  return

# Serves from the network, falling back to the cache when offline
respond = (request) ->
  try
    response = await fetch(request)
    if response.ok
      cache = await caches.open(CACHE_NAME)
      await cache.put(request, response.clone())
    return response
  catch
    return caches.match(request, { ignoreSearch: true })

self.addEventListener 'install', (e) ->
  e.waitUntil(install())

self.addEventListener 'activate', (e) ->
  e.waitUntil(activate())

self.addEventListener 'fetch', (e) ->
  e.respondWith(respond(e.request)) if e.request.method == 'GET'
