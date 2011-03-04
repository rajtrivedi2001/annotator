describe "Annotator.Plugin.Store", ->
  store = null

  beforeEach ->
    element = $('<div></div>')[0]
    store = new Annotator.Plugin.Store(element, {autoFetch: false})
    store.annotator = {
      loadAnnotations: jasmine.createSpy('Annotator#loadAnnotations')
    }

  describe "events", ->
    it "should call Store#annotationCreated when the annotationCreated is fired", ->
      spyOn(store, 'annotationCreated')
      store.element.trigger('annotationCreated', ['annotation1'])
      expect(store.annotationCreated).toHaveBeenCalledWith('annotation1')

    it "should call Store#annotationUpdated when the annotationUpdated is fired", ->
      spyOn(store, 'annotationUpdated')
      store.element.trigger('annotationUpdated', ['annotation1'])
      expect(store.annotationUpdated).toHaveBeenCalledWith('annotation1')

    it "should call Store#annotationDeleted when the annotationDeleted is fired", ->
      spyOn(store, 'annotationDeleted')
      store.element.trigger('annotationDeleted', ['annotation1'])
      expect(store.annotationDeleted).toHaveBeenCalledWith('annotation1')

  describe "pluginInit", ->
    it "should call Store#_getAnnotations() if no Auth plugin is loaded", ->
      spyOn(store, '_getAnnotations')
      store.pluginInit()
      expect(store._getAnnotations).toHaveBeenCalled()

    it "should call Auth#withToken() if Auth plugin is loaded", ->
      authMock = {
        withToken: jasmine.createSpy('Auth#withToken()')
      }
      store.element.data('annotator:auth', authMock);

      store.pluginInit()
      expect(authMock.withToken).toHaveBeenCalledWith(store._getAnnotations)

  describe "_getAnnotations", ->
    it "should call Store#loadAnnotations() if @options.loadFromSearch is not present", ->
      spyOn(store, 'loadAnnotations')
      store._getAnnotations()
      expect(store.loadAnnotations).toHaveBeenCalled()

    it "should call Store#loadAnnotationsFromSearch() if @options.loadFromSearch is present", ->
      spyOn(store, 'loadAnnotationsFromSearch')

      store.options.loadFromSearch = {}
      store._getAnnotations()

      expect(store.loadAnnotationsFromSearch).toHaveBeenCalledWith(store.options.loadFromSearch)

  describe "loadAnnotations", ->
    it "should call Store#_apiRequest()", ->
      spyOn(store, '_apiRequest')
      store.loadAnnotations()
      expect(store._apiRequest).toHaveBeenCalledWith('read', null, store._onLoadAnnotations)

  describe "loadAnnotationsFromSearch", ->
    it "should call Store#_apiRequest()", ->
      options = {}

      spyOn(store, '_apiRequest')
      store.loadAnnotationsFromSearch(options)

      expect(store._apiRequest).toHaveBeenCalledWith('search', options, store._onLoadAnnotationsFromSearch)

  describe "_onLoadAnnotations", ->
    it "should set the Store#annotations property with received annotations", ->
      data = [1,2,3];
      store._onLoadAnnotations(data)
      expect(store.annotations).toBe(data)

    it "should default to an empty array if no data is provided", ->
      store._onLoadAnnotations()
      expect(store.annotations).toEqual([])

    it "should call Annotator#loadAnnotations()", ->
      store._onLoadAnnotations()
      expect(store.annotator.loadAnnotations).toHaveBeenCalled()

    it "should call Annotator#loadAnnotations() with clone of provided data", ->
      data = [];
      store._onLoadAnnotations(data)
      expect(store.annotator.loadAnnotations.mostRecentCall.args[0]).not.toBe(data)
      expect(store.annotator.loadAnnotations.mostRecentCall.args[0]).toEqual(data)

  describe "_onLoadAnnotationsFromSearch", ->
    it "should call Store#_onLoadAnnotations() with data.rows", ->
      spyOn(store, '_onLoadAnnotations')
      
      data = {rows: [{}, {}, {}]}
      store._onLoadAnnotationsFromSearch(data)
      expect(store._onLoadAnnotations.mostRecentCall.args[0]).toEqual(data.rows)

    it "should default to an empty array if no data.rows are provided", ->
      spyOn(store, '_onLoadAnnotations')

      store._onLoadAnnotationsFromSearch()
      expect(store._onLoadAnnotations.mostRecentCall.args[0]).toEqual([])


  describe "_urlFor", ->
    it "should generate RESTful URLs by default", ->
      expect(store._urlFor('create')).toEqual('/store/annotations')
      expect(store._urlFor('read')).toEqual('/store/annotations')
      expect(store._urlFor('read', 'foo')).toEqual('/store/annotations/foo')
      expect(store._urlFor('update', 'bar')).toEqual('/store/annotations/bar')
      expect(store._urlFor('destroy', 'baz')).toEqual('/store/annotations/baz')

    it "should generate URLs as specified by its options otherwise", ->
      store.options.prefix = '/some/prefix/'
      store.options.urls.create = 'createMe'
      store.options.urls.read = ':id/readMe'
      store.options.urls.update = ':id/updateMe'
      store.options.urls.destroy = ':id/destroyMe'
      expect(store._urlFor('create')).toEqual('/some/prefix/createMe')
      expect(store._urlFor('read')).toEqual('/some/prefix/readMe')
      expect(store._urlFor('read', 'foo')).toEqual('/some/prefix/foo/readMe')
      expect(store._urlFor('update', 'bar')).toEqual('/some/prefix/bar/updateMe')
      expect(store._urlFor('destroy', 'baz')).toEqual('/some/prefix/baz/destroyMe')

  describe "dumpAnnotations", ->
    it "returns a list of its annotations", ->
      store.annotations = [{text: "Foobar"}, {user: "Bob"}]
      expect(store.dumpAnnotations()).toEqual([{text: "Foobar"}, {user: "Bob"}])

    it "removes the highlights properties from the annotations", ->
      store.annotations = [{highlights: "abc"}, {highlights: [1,2,3]}]
      expect(store.dumpAnnotations()).toEqual([{}, {}])
