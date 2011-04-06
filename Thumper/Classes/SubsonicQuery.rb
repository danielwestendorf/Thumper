#
#  SubsonicQuery.rb
#  Thumper
#
#  Created by Daniel Westendorf on 4/2/11.
#  Copyright 2011 Daniel Westendorf. All rights reserved.
#

require 'rubygems'
require 'httparty'
require 'uri'
require 'digest'

class SubsonicQuery
    include HTTParty
    attr_reader :online
    
    def initialize(uri, username, password)
        @query_queue = Dispatch::Queue.new('com.qweef.network_queue')
        @online ||= false
        self.class.basic_auth username, password
        self.class.base_uri uri
        self.class.default_params :f => 'xml', :v => '1.4.0', :c => 'Qweef'
    end
    
    def ping(delegate, successMethod, failureMethod)
        @query_queue.async do
            begin
                response = self.class.get('/rest/ping.view')
                if response.code == 200 && response.parsed_response["subsonic_response"]
                    status = "Online"
                    @online = true
                elsif response.code == 401
                    status = "Authentication Failed"
                    @online = false
                else
                    status = "Server Unavailable"
                    @online = false
                end
                delegate.method(successMethod).call(status)
            rescue
                delegate.method(failureMethod).call("Unable to contact server")
            end
        end
    end
    
    def getLicense(delegate, delegateMethod)
        run_query(delegate, delegateMethod, '/rest/getLicense.view')
    end
    
    def getMusicFolders(delegate, delegateMethod)
        run_query(delegate, delegateMethod, '/rest/getMusicFolders.view')
    end
    
    def getNowPlaying(delegate, delegateMethod)
        run_query(delegate, delegateMethod, '/rest/getNowPlaying.view')
    end
    
    def getIndexes(delegate, delegateMethod, options={})
        run_query(delegate, delegateMethod, '/rest/getIndexes.view', options)
    end
    
    def getMusicDirectory(delegate, delegateMethod, options={})
        run_query(delegate, delegateMethod, '/rest/getMusicDirectory.view', options)
    end
    
    def search(delegate, delegateMethod, options)
        run_query(delegate, delegateMethod, '/rest/search2.view', options)
    end
    
    def getPlaylists(delegate, delegateMethod)
        run_query(delegate, delegateMethod, '/rest/getPlaylists.view')
    end
    
    def getPlaylist(delegate, delegateMethod, options)
        run_query(delegate, delegateMethod, '/rest/getPlaylist.view', options)
    end
    
    def createPlaylist(delegate, delegateMethod, options)
        run_query(delegate, delegateMethod, '/rest/createPlaylist.view', options, :post)
    end
    
    def deletePlaylist(delegate, delegateMethod, options)
        run_query(delegate, delegateMethod, '/rest/deletePlaylist.view', options, :delete)
    end
    
    def getCoverArt(delegate, delegateMethod, options)
        run_query(delegate, delegateMethod, '/rest/getCoverArt.view', options)
    end
    
    def stream(delegate, delegateMethod, options)
        run_query(delegate, delegateMethod, '/rest/stream.view', options)
    end
    
    def download(delegate, delegateMethod, options)
        run_query(delegate, delegateMethod, '/rest/download.view', options)
    end
    
    def getUser(delegate, delegateMethod, options)
        run_query(delegate, delegateMethod, '/rest/getUser.view', options)
    end
    
    def getChatMessages(delegate, delegateMethod, options={})
        run_query(delegate, delegateMethod, '/rest/getChatMessages.view', options)
    end
    
    def addChatMessage(delegate, delegateMethod, options)
        run_query(delegate, delegateMethod, '/rest/addChatMessage.view', options, :post)
    end
    
    def getAlbumList(delegate, delegateMethod, options)
        run_query(delegate, delegateMethod, '/rest/getAlbumList.view', options)
    end
    
    def getRandomSongs(delegate, delegateMethod, options)
        run_query(delegate, delegateMethod, '/rest/getRandomSongs.view', options)
    end
    
    def getLyrics(delegate, delegateMethod, options)
        run_query(delegate, delegateMethod, '/rest/getLyrics.view', options)
    end
    
    private
    
    def run_query(delegate, delegateMethod, uri, options={}, request_type=:get)
        if @online
            @query_queue.async do
                response = self.class.method(request_type).call(uri, :query => options, :timeout => 1000 )
                delegate.method(delegateMethod).call(getContent(response))
            end
        else
            return nil
        end
    end
    
    def getContent(response)
        if response.code == 200
            return response.parsed_response['subsonic_response'].first
        else
            raise RuntimeError, "server did not provide valid response"
        end
    end
    
end
