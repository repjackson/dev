if Meteor.isClient
    Template.reddit_posts.onCreated ->
        Session.setDefault('current_search', null)
        Session.setDefault('picked_subreddit', null)
        Session.setDefault('porn', false)
        Session.setDefault('dummy', false)
        Session.setDefault('is_loading', false)
        @autorun => @subscribe 'doc_by_id', Session.get('full_doc_id'), ->
        @autorun => @subscribe 'agg_emotions',
            picked_tags.array()
            Session.get('dummy')
        @autorun => @subscribe 'reddit_post_tag_results',
            picked_tags.array()
            Session.get('picked_subreddit')
            Session.get('porn')
            Session.get('dummy')
            
    Template.reddit_doc_results.onCreated ->
        @autorun => @subscribe 'reddit_doc_results',
            picked_tags.array()
            Session.get('picked_subreddit')
            Session.get('porn')
            # Session.get('dummy')
    
    Template.emotion_vote.events
        'click .vote_emotion':->
            parent = Template.parentData()
            Docs.update parent._id, 
                $inc:
                    "#{@name}_votes":1
                    
    Template.emotion_vote.helpers 
        emotion_count: ->
            parent = Template.parentData()
            parent["#{@name}_votes"]
    
    Template.reddit_posts.onCreated ->
        @autorun => Meteor.subscribe 'model_counter',('reddit'), ->
    Template.reddit_posts.helpers
        total_reddit_post_count: -> Counts.get('model_counter') 


    Template.reddit_post_view.onCreated ->
        @autorun => @subscribe 'doc_by_id', Meteor.user()._model, ->
    Template.reddit_post_view.onRendered ->
        found_doc = Docs.findOne Meteor.user()._model
        if found_doc 
            unless found_doc.watson
                Meteor.call 'call_watson',Meteor.user()._model,'rd.selftext', ->


    Template.agg_tag.onCreated ->
        @autorun => @subscribe 'tag_image', @data.name, Session.get('porn'),->
    Template.agg_tag.helpers
        term: ->
            found = Docs.findOne {
                model:'reddit'
                tags:$in:[Template.currentData().name]
                # "watson.metadata.image":$exists:true
            }, sort:ups:-1
            found
    Template.unpick_tag.onCreated ->
        @autorun => @subscribe 'tag_image', @data, Session.get('porn'),->
    Template.unpick_tag.helpers
        flat_term_image: ->
            found = Docs.findOne {
                model:'reddit'
                tags:$in:[Template.currentData()]
                "watson.metadata.image":$exists:true
            }, sort:ups:-1
            found.watson.metadata.image
    Template.agg_tag.events
        'click .result': (e,t)->
            # Meteor.call 'log_term', @title, ->
            picked_tags.push @name
            $('#search').val('')
            Session.set('full_doc_id', null)
            
            Session.set('current_search', null)
            Session.set('searching', true)
            Session.set('is_loading', true)
            # Meteor.call 'call_wiki', @name, ->
    
            Meteor.call 'search_reddit', picked_tags.array(),Session.get('porn'), ->
                Session.set('is_loading', false)
                Session.set('searching', false)
            Meteor.setTimeout ->
                Session.set('dummy',!Session.get('dummy'))
            , 5000
            
    
    Template.session_icon_button.helpers 
        session_set_class: ->
            if Session.equals(@key,@value)
                'active'
            else 
                'basic'
    Template.session_icon_button.events
        'click .set_session': ->
            Session.set(@key,@value)
    Template.reddit_posts.events
        'click .toggle_porn': ->
            Session.set('porn',!Session.get('porn'))
        'click .select_search': ->
            picked_tags.push @name
            Session.set('full_doc_id', null)
    
            Meteor.call 'search_reddit', picked_tags.array(),Session.get('porn'), ->
            $('#search').val('')
            Session.set('current_search', null)
    
    Template.reddit_post_card.helpers
        five_cleaned_tags: ->
            if picked_tags.array().length
                _.difference(@tags[..10],picked_tags.array())
            #     @tags[..5] not in picked_tags.array()
            else 
                @tags[..5]
    Template.flat_tag_picker.events
        'click .remove_tag': ->
            parent = Template.parentData()
            # if confirm "remove #{@valueOf()} tag?"
            Docs.update parent._id,
                $pull:
                    tags:@valueOf()
        'click .pick_flat_tag': -> 
            picked_tags.push @valueOf()
            Session.set('full_doc_id', null)
    
            Session.set('loading',true)
            Meteor.call 'search_reddit', picked_tags.array(),Session.get('porn'), ->
                Session.set('loading',false)
    Template.reddit_post_card_big.events
        'click .minimize': ->
            Session.set('full_doc_id', null)
    Template.reddit_post_card.events
        'click .vote_up': (e)->
            $(e.currentTarget).closest('.card').transition('jiggle', 500)
            Docs.update @_id,
                $inc:
                    points:1
                    upvotes:1
            # Session.set('dummy', !Session.get('dummy'))

            
        'click .vote_down': (e)->
            $(e.currentTarget).closest('.card').transition('shake', 500)
            Docs.update @_id,
                $inc:
                    points:-1
                $inc:
                    downvotes:1
            # Session.set('dummy', !Session.get('dummy'))

        'click .expand': ->
            Session.set('full_doc_id', @_id)
            Session.set('dummy', !Session.get('dummy'))
    
        'click .pick_flat_tag': (e)-> 
            picked_tags.push @valueOf()
            Session.set('full_doc_id', null)
            $(e.currentTarget).closest('.pick_flat_tag').transition('fly up', 500)
    
            Session.set('loading',true)
            Meteor.call 'search_reddit', picked_tags.array(), Session.get('porn'),->
                Session.set('loading',false)
        # 'click .pick_subreddit': -> Session.set('subreddit',@subreddit)
        # 'click .pick_domain': -> Session.set('domain',@domain)
        'click .autotag': (e)->
            $(e.currentTarget).closest('.button').transition('fade', 500)
            
            # if @rd and @rd.selftext_html
            #     dom = document.createElement('textarea')
            #     # dom.innerHTML = doc.body
            #     dom.innerHTML = @rd.selftext_html
            #     # return dom.value
            #     Docs.update @_id,
            #         $set:
            #             parsed_selftext_html:dom.value
            Meteor.call 'get_reddit_post', @_id, (err,res)->
    
            # doc = Template.parentData()
            # doc = Docs.findOne Template.parentData()._id
            # Meteor.call 'call_watson', Template.parentData()._id, parent.key, @mode, ->
            # if doc 
            $('body').toast({
                title: "breaking down emotions"
                # message: 'Please see desk staff for key.'
                class : 'black'
                showIcon:'chess loading'
                # showProgress:'bottom'
                position:'bottom right'
                # className:
                #     toast: 'ui massive message'
                # displayTime: 5000
                transition:
                  showMethod   : 'zoom',
                  showDuration : 250,
                  hideMethod   : 'fade',
                  hideDuration : 250
                })
            
            Meteor.call 'call_watson', @_id, 'rd.selftext', 'html', (err,res)->
                # $(e.currentTarget).closest('.button').transition('scale', 500)
                $('body').toast({
                    title: "emotions brokedown"
                    # message: 'Please see desk staff for key.'
                    class : 'black'
                    showIcon:'smile'
                    # showProgress:'bottom'
                    position:'bottom right'
                    # className:
                    #     toast: 'ui massive message'
                    # displayTime: 5000
                    transition:
                      showMethod   : 'zoom',
                      showDuration : 250,
                      hideMethod   : 'fade',
                      hideDuration : 250
                    })
                Session.set('dummy', !Session.get('dummy'))
            # Meteor.call 'call_watson', doc._id, @key, @mode, ->
    Template.unpick_tag.events
        'click .unpick_tag': ->
            picked_tags.remove @valueOf()
            if picked_tags.array().length > 0
                Session.set('is_loading', true)
                Meteor.call 'search_reddit', picked_tags.array(),Session.get('porn'), =>
                    Session.set('is_loading', false)
                Meteor.setTimeout ->
                    Session.set('dummy', !Session.get('dummy'))
                , 5000
            
    
    
    Template.reddit_posts.events
        'click .print_me': ->
    
        # # 'keyup #search': _.throttle((e,t)->
        'click #search': (e,t)->
            if picked_tags.array().length > 0
                Session.set('dummy', !Session.get('dummy'))
        'keydown #search': (e,t)->
            # query = $('#search').val()
            search = $('#search').val().trim().toLowerCase()
            # if query.length > 0
            Session.set('current_search', search)
            if search.length > 0
                if e.which is 13
                    if search.length > 0
                        # Session.set('searching', true)
                        picked_tags.push search
                        Session.set('full_doc_id',null)
                        Session.set('is_loading', true)
                        Meteor.call 'search_reddit', picked_tags.array(),Session.get('porn'), ->
                            Session.set('is_loading', false)
                            # Session.set('searching', false)
                        # Meteor.setTimeout ->
                        #     Session.set('dummy', !Session.get('dummy'))
                        # , 5000
                        $('#search').val('')
                        $('#search').blur()
                        Session.set('current_search', null)
        # , 200)
    
        # 'keydown #search': _.throttle((e,t)->
        #     if e.which is 8
        #         search = $('#search').val()
        #         if search.length is 0
        #             last_val = picked_tags.array().slice(-1)
        #             $('#search').val(last_val)
        #             picked_tags.pop()
        #             Meteor.call 'search_reddit', picked_tags.array(), ->
        # , 1000)
    
        'click .reconnect': -> Meteor.reconnect()
    
        'click .toggle_tag': (e,t)-> picked_tags.push @valueOf()
        'click .pick_subreddit': -> Session.set('subreddit',@name)
        'click .unpick_subreddit': -> Session.set('subreddit',null)
        'click .pick_domain': -> Session.set('domain',@name)
        'click .unpick_domain': -> Session.set('domain',null)
        'click .print_me': (e,t)->
            
    Template.reddit_post_card.helpers
        unescaped: -> 
            txt = document.createElement("textarea")
            txt.innerHTML = @rd.selftext_html
            return txt.value
    
            # html.unescape(@rd.selftext_html)
        unescaped_content: -> 
            txt = document.createElement("textarea")
            txt.innerHTML = @rd.media_embed.content
            return txt.value
    
            # html.unescape(@rd.selftext_html)
    Template.reddit_post_view.events 
        'click .get_comments':->
            Meteor.call 'get_comments', Meteor.user()._model, ->
                
    Template.reddit_post_view.helpers
        comment_docs: ->
            Docs.find 
                model:'comment'
                parent_id:Meteor.user()._model
    Template.reddit_posts.helpers
        porn_class: ->
            if Session.get('porn') then 'large red' else 'compact'
        full_doc_id: ->
            Session.get('full_doc_id')
        full_doc: ->
            Docs.findOne Session.get('full_doc_id')
        current_bg:->
            found = Docs.findOne {
                model:'reddit'
                tags:$in:picked_tags.array()
                "watson.metadata.image":$exists:true
                # thumbnail:$nin:['default','self']
            },sort:ups:-1
            if found
                found.watson.metadata.image
            # else 
    
        emotion_avg_result: ->
            Results.findOne 
                model:'emotion_avg'
        # in_dev: -> Meteor.isDevelopment()
        not_searching: ->
            picked_tags.array().length is 0 and Session.equals('current_search',null)
            
        search_class: ->
            if Session.get('current_search')
                'massive active' 
            else
                if picked_tags.array().length is 0
                    'big'
                else 
                    'big' 
              
        # domain_results: ->
        #     Results.find 
        #         model:'domain'
        # picked_subreddit: -> Session.get('subreddit')
        # picked_domain: -> Session.get('domain')
        # subreddit_results: ->
        #     Results.find 
        #         model:'subreddit'
                    
        curent_date_setting: -> Session.get('date_setting')
    
        term_icon: ->
        is_loading: -> Session.get('is_loading')
    
        tag_result_class: ->
            # ec = omega.emotion_color
            total_doc_result_count = Docs.find({}).count()
            percent = @count/total_doc_result_count
            whole = parseInt(percent*10)+1
    
            # if whole is 0 then "#{ec} f5"
            if whole is 0 then "f5"
            else if whole is 1 then "f11"
            else if whole is 2 then "f12"
            else if whole is 3 then "f13"
            else if whole is 4 then "f14"
            else if whole is 5 then "f15"
            else if whole is 6 then "f16"
            else if whole is 7 then "f17"
            else if whole is 8 then "f18"
            else if whole is 9 then "f19"
            else if whole is 10 then "f20"
    
        connection: ->
            Meteor.status()
        connected: -> Meteor.status().connected
    
        unpicked_tags: ->
            # # doc_count = Docs.find().count()
            # # if doc_count < 3
            # #     Tags.find({count: $lt: doc_count})
            # # else
            # unless Session.get('searching')
            #     unless Session.get('current_search').length > 0
            Results.find({model:'tag'})
    
        result_class: ->
            if Template.instance().subscriptionsReady()
                ''
            else
                'disabled'
    
        picked_tags: -> picked_tags.array()
    
        picked_tags_plural: -> picked_tags.array().length > 1
    
        searching: ->
            Session.get('searching')
    
        one_reddit_post: -> Docs.find(model:'reddit').count() is 1
    
        two_reddit_posts: -> Docs.find(model:'reddit').count() is 2
        three_reddit_posts: -> Docs.find(model:'reddit').count() is 3
        four_reddit_posts: -> Docs.find(model:'reddit').count() is 4
        more_than_four: -> Docs.find(model:'reddit').count() > 4
        one_result: ->
            Docs.find(model:'reddit').count() is 1
    
        docs: ->
            # if picked_tags.array().length > 0
            cursor =
                Docs.find {
                    model:'reddit'
                },
                    sort:
                        "#{Session.get('sort_key')}":Session.get('sort_direction')
            cursor
    
    
        home_subs_ready: ->
            Template.instance().subscriptionsReady()
            
        #     @autorun => Meteor.subscribe 'current_doc', Meteor.user()._model
        # Template.array_view.events
        #     'click .toggle_reddit_post_filter': ->
        #         value = @valueOf()
        #         current = Template.currentData()
                # match = Session.get('match')
                # key_array = match["#{current.key}"]
                # if key_array
                #     if value in key_array
                #         key_array = _.without(key_array, value)
                #         match["#{current.key}"] = key_array
                #         picked_tags.remove value
                #         Session.set('match', match)
                #     else
                #         key_array.push value
                #         picked_tags.push value
                #         Session.set('match', match)
                #         Meteor.call 'search_reddit', picked_tags.array(), ->
                #         # Meteor.call 'agg_idea', value, current.key, 'entity', ->
                #         # match["#{current.key}"] = ["#{value}"]
                # else
                # if value in picked_tags.array()
                #     picked_tags.remove value
                # else
                #     # match["#{current.key}"] = ["#{value}"]
                #     picked_tags.push value
                # # Session.set('match', match)
                # if picked_tags.array().length > 0
                #     Meteor.call 'search_reddit', picked_tags.array(), ->
    
        # Template.array_view.helpers
        #     values: ->
        #         Template.parentData()["#{@key}"]
        #
        #     reddit_post_label_class: ->
        #         match = Session.get('match')
        #         key = Template.parentData().key
        #         doc = Template.parentData(2)
        #         if @valueOf() in picked_tags.array()
        #             'active'
        #         else
        #             'basic'
        #         # if match["#{key}"]
        #         #     if @valueOf() in match["#{key}"]
        #         #         'active'
        #         #     else
        #         #         'basic'
        #         # else
        #         #     'basic'
        #
        
        
    Template.reddit_posts.helpers
        unpicked_subreddits: ->
            Results.find 
                model:'subreddit'
                
    Template.reddit_doc_results.helpers
        doc_results: ->
            current_docs = Docs.find()
            # if Session.get('selected_doc_id') in current_docs.fetch()
            # Docs.findOne Session.get('selected_doc_id')
            doc_count = Docs.find().count()
            # if doc_count is 1
            Docs.find({model:'reddit'}, 
                limit:20
                sort:
                    points:-1
                    ups:-1
                    # "#{Session.get('sort_key')}":Session.get('sort_direction')
            )
    


  
if Meteor.isClient
    Template.reddit_post_view.onCreated ->
        @autorun => @subscribe 'related_group',Meteor.user()._model, ->
    Template.reddit_post_view.onCreated ->
        @autorun => @subscribe 'reddit_post_tips',Meteor.user()._model, ->
    Template.reddit_post_view.events 
        'click .pick_flat_tag': (e)-> 
            picked_tags.push @valueOf()
            # Session.set('full_doc_id', null)
            $(e.currentTarget).closest('.pick_flat_tag').transition('fly up', 500)
    
            Session.set('loading',true)
            Meteor.call 'search_reddit', picked_tags.array(), ->
                Session.set('loading',false)
            gstate_set "/reddit_posts"
        'click .goto_subreddit': ->
            Meteor.call 'find_tribe', @subreddit, (err,res)->
                gstate_set "/group/#{res}"
        'click .get_comments': ->
            Meteor.call 'get_reddit_comments', (Meteor.user()._model), ->
                
                
if Meteor.isServer 
    Meteor.methods 
        find_tribe: (tribe_slug)->
            found = Docs.findOne 
                model:'tribe'
                slug:tribe_slug
            
            if found 
                return found._id
            else
                new_id = 
                    Docs.insert 
                        model:'tribe'
                        source:'reddit'
                        title:tribe_slug
                        slug:tribe_slug
                return new_id
                    
if Meteor.isServer
    get_reddit_post: (doc_id, reddit_id, root)->
        doc = Docs.findOne doc_id
        if doc.reddit_id
        else
            
        HTTP.get "http://reddit.com/by_id/t3_#{doc.reddit_id}.json", (err,res)->
            if err 
                console.log err
            else
                rd = res.data.data.children[0].data
                result =
                    Docs.update doc_id,
                        $set:
                            rd: rd
                # if rd.is_video
                #     Meteor.call 'call_watson', doc_id, 'url', 'video', ->
                # else if rd.is_image
                #     Meteor.call 'call_watson', doc_id, 'url', 'image', ->
                # else
                #     Meteor.call 'call_watson', doc_id, 'url', 'url', ->
                #     Meteor.call 'call_watson', doc_id, 'url', 'image', ->
                #     # Meteor.call 'call_visual', doc_id, ->
                # if rd.selftext
                #     unless rd.is_video
                #         # if Meteor.isDevelopment
                #         Docs.update doc_id, {
                #             $set:
                #                 body: rd.selftext
                #         }, ->
                #         #     Meteor.call 'pull_site', doc_id, url
                # if rd.selftext_html
                #     unless rd.is_video
                #         Docs.update doc_id, {
                #             $set:
                #                 html: rd.selftext_html
                #         }, ->
                #             # Meteor.call 'pull_site', doc_id, url
                # if rd.url
                #     unless rd.is_video
                #         url = rd.url
                #         # if Meteor.isDevelopment
                #         Docs.update doc_id, {
                #             $set:
                #                 reddit_url: url
                #                 url: url
                #         }, ->
                #             # Meteor.call 'call_watson', doc_id, 'url', 'url', ->
                # # update_ob = {}

                Docs.update doc_id,
                    $set:
                        rd: rd
                        url: rd.url
                        thumbnail: rd.thumbnail
                        subreddit: rd.subreddit
                        author: rd.author
                        is_video: rd.is_video
                        ups: rd.ups
                        # downs: rd.downs
                        over_18: rd.over_18
                    # $addToSet:
                    #     tags: $each: [rd.subreddit.toLowerCase()]

    get_reddit_comments: (reddit_post_id)->
        reddit_post =
            Docs.findOne reddit_post_id
        # response = HTTP.get("http://reddit.com/search.json?q=#{query}")
        # HTTP.get "http://reddit.com/search.json?q=#{query}+nsfw:0+sort:top",(err,response)=>
        # HTTP.get "http://reddit.com/search.json?q=#{query}",(err,response)=>
        link = "http://reddit.com/comments/#{reddit_post.reddit_id}?depth=1"
        HTTP.get link,(err,response)=>
            # if response.data.data.dist > 1
            #     _.each(response.data.data.children, (item)=>
                    # unless item.domain is "OneWordBan"
                    #     data = item.data

    
    Meteor.publish 'reddit_post_tag_results', (
        picked_tags=null
        picked_subreddit=null
        picked_author=null
        # query
        porn=false
        # searching
        dummy
        )->
    
        self = @
        match = {}
    
        # match.model = $in: ['reddit','wikipedia']
        match.model = 'reddit'
        # if query
        # if view_nsfw
        match.over_18 = porn
        if picked_tags and picked_tags.length > 0
            match.tags = $all: picked_tags
            if picked_subreddit
                match.subreddit = picked_subreddit
            limit = 20
            # else
            #     limit = 10
            #     match._timestamp = $gt:moment().subtract(1, 'days')
            # else /
                # match.tags = $all: picked_tags
            agg_doc_count = Docs.find(match).count()
            tag_cloud = Docs.aggregate [
                { $match: match }
                { $project: "tags": 1 }
                { $unwind: "$tags" }
                { $group: _id: "$tags", count: $sum: 1 }
                { $match: _id: $nin: picked_tags }
                { $match: count: $lt: agg_doc_count }
                # { $match: _id: {$regex:"#{current_query}", $options: 'i'} }
                { $sort: count: -1, _id: 1 }
                { $limit: 11 }
                { $project: _id: 0, name: '$_id', count: 1 }
            ], {
                allowDiskUse: true
            }
        
            tag_cloud.forEach (tag, i) =>
                self.added 'results', Random.id(),
                    name: tag.name
                    count: tag.count
                    model:'tag'
                    # index: i
            subreddit_cloud = Docs.aggregate [
                { $match: match }
                { $project: "subreddit": 1 }
                # { $unwind: "$tags" }
                { $group: _id: "$subreddit", count: $sum: 1 }
                { $match: _id: $ne: picked_subreddit }
                { $match: count: $lt: agg_doc_count }
                # { $match: _id: {$regex:"#{current_query}", $options: 'i'} }
                { $sort: count: -1, _id: 1 }
                { $limit: 11 }
                { $project: _id: 0, name: '$_id', count: 1 }
            ], {
                allowDiskUse: true
            }
        
            subreddit_cloud.forEach (sub, i) =>
                self.added 'results', Random.id(),
                    name: sub.name
                    count: sub.count
                    model:'subreddit'
                    # index: i
            
            self.ready()
            # else []
    Meteor.publish 'reddit_doc_results', (
        picked_tags=null
        picked_subreddit=null
        porn=false
        sort_key='_timestamp'
        sort_direction=-1
        # dummy
        # current_query
        # date_setting
        )->
        # else
        self = @
        # match = {model:$in:['reddit','wikipedia']}
        match = {model:'reddit'}
        # match.over_18 = $ne:true
        #         yesterday = now-day
        #         match._timestamp = $gt:yesterday
        # if picked_subreddit
        #     match.subreddit = picked_subreddit
        # if porn
        match.over_18 = porn
        # if picked_tags.length > 0
        #     # if picked_tags.length is 1
        #     #     found_doc = Docs.findOne(title:picked_tags[0])
        #     #
        #     #     match.title = picked_tags[0]
        #     # else
        if picked_tags and picked_tags.length > 0
            match.tags = $all: picked_tags
        else 
            match._timestamp = $gt:moment().subtract(1, 'days')
        Docs.find match,
            sort:
                "#{sort_key}":sort_direction
                points:-1
                ups:-1
            limit:42
            fields:
                # youtube_id:1
                "rd.media_embed":1
                "rd.url":1
                "rd.thumbnail":1
                "rd.analyzed_text":1
                subreddit:1
                thumbnail:1
                doc_sentiment_label:1
                doc_sentiment_score:1
                joy_percent:1
                sadness_percent:1
                fear_percent:1
                disgust_percent:1
                anger_percent:1
                happy_votes:1
                sad_votes:1
                angry_votes:1
                fearful_votes:1
                disgust_votes:1
                funny_votes:1
                over_18:1
                points:1
                upvoter_ids:1
                downvoter_ids:1
                url:1
                ups:1
                "watson.metadata":1
                "watson.analyzed_text":1
                title:1
                model:1
                num_comments:1
                tags:1
                _timestamp:1
                domain:1
        # else 
        #     Docs.find match,
        #         sort:_timestamp:-1
        #         limit:10
    
    
    
    Meteor.methods
        search_reddit: (query,porn=false)->
            # response = HTTP.get("http://reddit.com/search.json?q=#{query}")
            # HTTP.get "http://reddit.com/search.json?q=#{query}+nsfw:0+sort:top",(err,response)=>
            # HTTP.get "http://reddit.com/search.json?q=#{query}",(err,response)=>
            if porn 
                link = "http://reddit.com/search.json?q=#{query}&nsfw=1&include_over_18=on"
            else
                link = "http://reddit.com/search.json?q=#{query}&nsfw=0&include_over_18=off"
            HTTP.get link,(err,response)=>
                if response.data.data.dist > 1
                    _.each(response.data.data.children, (item)=>
                        unless item.domain is "OneWordBan"
                            data = item.data
                            len = 200
                            # added_tags = [query]
                            # added_tags.push data.domain.toLowerCase()
                            # added_tags.push data.author.toLowerCase()
                            # added_tags = _.flatten(added_tags)
                            reddit_post =
                                reddit_id: data.id
                                url: data.url
                                domain: data.domain
                                comment_count: data.num_comments
                                permalink: data.permalink
                                title: data.title
                                # root: query
                                ups:data.ups
                                num_comments:data.num_comments
                                # selftext: false
                                points:0
                                over_18:data.over_18
                                thumbnail: data.thumbnail
                                tags: query
                                model:'reddit'
                            existing_doc = Docs.findOne url:data.url
                            if existing_doc
                                # if Meteor.isDevelopment
                                if typeof(existing_doc.tags) is 'string'
                                    Docs.update existing_doc._id,
                                        $unset: tags: 1
                                Docs.update existing_doc._id,
                                    $addToSet: tags: $each: query
                                    $set:
                                        title:data.title
                                        ups:data.ups
                                        num_comments:data.num_comments
                                        over_18:data.over_18
                                        thumbnail:data.thumbnail
                                        permalink:data.permalink
                                # Meteor.call 'get_reddit_post', existing_doc._id, data.id, (err,res)->
                                # Meteor.call 'call_watson', new_reddit_post_id, data.id, (err,res)->
                            unless existing_doc
                                new_reddit_post_id = Docs.insert reddit_post
                                # Meteor.call 'get_reddit_post', new_reddit_post_id, data.id, (err,res)->
                                # Meteor.call 'call_watson', new_reddit_post_id, data.id, (err,res)->
                            return true
                    )
