fs = require 'fs'
YAML = require 'yamljs'
moment = require 'moment'
richtypo = require 'richtypo'

docpadConfig = {

    databaseCache: true,
    maxAge: false,
    port: 78880,

    templateData:
        cutTag: '<!-- cut -->'
        site: {}
        pageTitle: -> 
            if @document.title
                "#{@document.title} — #{@site.title}"
            else
                @site.title
        pageDescription: ->
            if @document.description
                "#{@document.description}"
            else
                @site.description
        pageKeywords: ->
            if @document.keywords
                "#{@document.keywords}"
            else
                @site.keywords
        cuttedContent: (content) ->            
            if @hasReadMore content
                cutIdx = content.search @cutTag
                content[0..cutIdx-1]
            else
                content
        hasReadMore: (content) ->
            content and ((content.search @cutTag) isnt -1)
        pubDate: (date) ->
            moment(date).format('LL')  # December 23 2013
        rt: (s) ->
            s and (richtypo.rich s)
        rtt: (s) ->
            s and (richtypo.title s)
        getTagUrl: (tag) ->
            doc = docpad.getFile({tag:tag})
            return doc?.get('url') or ''

    collections:
        posts: (database) ->
            database.findAllLive(
                {relativeOutDirPath: 'blog'}, 
                [date:-1]
            )
        clients: (database) ->
            database.findAllLive(
                {relativeOutDirPath: '4clients'},
                [pageOrder:1]
            )
        pages: (database) ->
            database.findAllLive(
                {inMenu: $exists: true}, 
                [pageOrder:1]
            )

    environments:
        en:
            documentsPaths: ['data/en']
            outPath: 'out/en'
        ru:
            documentsPaths: ['data/ru']
            outPath: 'out/ru'

    plugins:
        highlightjs:
            aliases:
                yaml: 'python'
        jade:
            jadeOptions:
                pretty: true
        partials:
            partialsPath: process.cwd() + '/src/layouts/partials'
        tags:
            extension: '.html.jade'
            injectDocumentHelper: (document) ->
                document.setMeta(
                    layout: 'default'
                    dynamic: true
                    data: """!=partial('tag')"""
                )

    events:
        generateBefore: (opts) ->
            lang = @docpad.config.env
            @docpad.getConfig().templateData.site = (YAML.load "src/lang/#{lang}.yml")
            moment.lang(lang)
            richtypo.lang(lang)
        serverExtended: (opts) ->
            {server} = opts
            docpad = @docpad
            latestConfig = docpad.getConfig()
            oldUrls = latestConfig.templateData.site.oldUrls or []
            newUrl = latestConfig.templateData.site.url

            server.use (req,res,next) ->
                if req.headers.host in oldUrls
                    res.redirect(newUrl+req.url, 301)
                else
                    next()
}

module.exports = docpadConfig
