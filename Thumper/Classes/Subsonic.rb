require 'base64'

module Subsonic
    attr_reader :albums, :songs, :artists
    
	def initialize(parent, base_url, username, password)
        @parent = parent
		@base_url = base_url
		@auth_token = Base64.encode64("#{username}:#{password}").strip
		@extra_params = "&f=xml&v=1.4.0&c=Thumper"
	end
	
	#response methods
	def ping_response(xml)
		if xml.class == NSXMLDocument
            @parent.status_label.stringValue = "Online" 
            NSLog "Online"
        else
            @parent.status_label.stringValue = "Offline"
            NSLog "Offline"
		end
		xml = nil
	end
	
	def albums_response(xml)
        @albums = []
        if xml.class == NSXMLDocument
            albums = xml.nodesForXPath("subsonic-response", error:nil).first.nodesForXPath('directory', error:nil).first.nodesForXPath('child', error:nil)
            albums.each do |album|
                @albums << {:id => album.attributeForName("id").stringValue, :title => album.attributeForName("title").stringValue, :artist => album.attributeForName("artist").stringValue, 
                    :cover_art => album.attributeForName("coverArt").stringValue, :artist_id => album.attributeForName("parent").stringValue} if album.attributeForName("isDir").stringValue == "true"
                @parent.get_cover_art(album.attributeForName("coverArt").stringValue)
            end
        else
            NSLog "Invalid response from server"
        end
        xml = nil
        NSLog "Update of artist albums complete. #{@albums.length} albums"
        if @parent.artists[@parent.artist_indexes_table_view.selectedRow][:id] == @albums.first[:artist_id]
            @parent.albums = @albums

            @parent.albums.count != 1 ? word = " Albums" : word = " Album"
            @parent.album_count_label.stringValue = @parent.albums.count.to_s + word
            @parent.albums_table_view.reloadData
            @parent.albums_table_view.enabled = true
        end
        NSLog "Persisting albums to the DB"
        if DB[:albums].filter(:artist_id => @albums.first[:artist_id]).all.count < 1
            DB.transaction do
                @albums.each {|a| DB[:albums].insert(:title => a[:title], :id => a[:id], :cover_art => a[:cover_art], :artist_id => a[:artist_id]) } 
            end
        else
            Dispatch::Queue.new('com.qweef.db').async do
                @albums.each do |a|
                    return if DB[:albums].filter(:id => a[:id]).all.first 
                    DB[:albums].insert(:title => a[:title], :id => a[:id], :cover_art => a[:cover_art], :artist_id => a[:artist_id])
                    NSLog "Added Album: #{a[:title]}"
                end
            end
        end
        NSLog "All Albums presisted to the DB"
	end
	
	def songs_response(xml)
        @songs = []
        if xml.class == NSXMLDocument
            songs = xml.nodesForXPath("subsonic-response", error:nil).first.nodesForXPath('directory', error:nil).first.nodesForXPath('child', error:nil)
            songs.each do |song|
                @songs << {:id => song.attributeForName("id").stringValue, :title => song.attributeForName("title").stringValue, :artist => song.attributeForName("artist").stringValue, 
                    :cover_art => song.attributeForName("coverArt").stringValue, :album_id => song.attributeForName("parent").stringValue, 
                    :duration => song.attributeForName("duration").stringValue, :bitrate => song.attributeForName("bitRate").stringValue,
                    :track => song.attributeForName("track").stringValue, :year => song.attributeForName("year").stringValue, :genre => song.attributeForName("genre").stringValue,
                    :size => song.attributeForName("size").stringValue, :suffix => song.attributeForName("suffix").stringValue, :album => song.attributeForName("album").stringValue,
                    :path => song.attributeForName("path").stringValue } if song.attributeForName("isDir").stringValue == "false"
            end
            else
            NSLog "Invalid response from server"
        end
        xml = nil
        if @parent.albums[@parent.albums_table_view.selectedRow][:id] == @songs.first[:album_id]
            @parent.songs = @songs
            @parent.songs.count != 1 ? word = " Songs" : word = " Song"
            @parent.songs_count_label.stringValue = @songs.count.to_s + word
            @parent.songs_table_view.reloadData
            @parent.songs_table_view.enabled = true
        else

        end
        NSLog "Persisting songs to the DB"
        if DB[:songs].filter(:album_id => @songs.first[:album_id]).all.count < 1
            DB.transaction do
                @songs.each {|s| DB[:songs].insert(:id => s[:id], :title => s[:title], :artist => s[:artist], :duration => s[:duration], 
                                                   :bitrate => s[:bitrate], :track => s[:track], :year => s[:year], :genre => s[:genre],
                                                   :size => s[:size], :suffix => s[:suffix], :album => s[:album], :album_id => s[:album_id],
                                                   :cover_art => s[:cover_art], :path => s[:path]) } 
            end
        else
            Dispatch::Queue.new('com.qweef.db').async do
                @albums.each do |a|
                    return if DB[:albums].filter(:id => a[:id]).all.first 
                    DB[:albums].insert(:id => s[:id], :title => s[:title], :artist => s[:artist], :duration => s[:duration], 
                                       :bitrate => s[:bitrate], :track => s[:track], :year => s[:year], :genre => s[:genre],
                                       :size => s[:size], :suffix => s[:suffix], :album => s[:album], :album_id => s[:album_id],
                                       :cover_art => s[:cover_art], :path => s[:path])
                    NSLog "Added Album: #{a[:title]}"
                end
            end
        end
        NSLog "All songs presisted to the DB"
	end
	
	def artists_response(xml)
        @artists = []
		if xml.class == NSXMLDocument
            indexes = xml.nodesForXPath("subsonic-response", error:nil).first.nodesForXPath('indexes', error:nil).first.nodesForXPath('index', error:nil)
            indexes.each do |index|
                artists = index.nodesForXPath('artist', error:nil)
                artists.each {|a| @artists << {:name => a.attributeForName("name").stringValue, :id => a.attributeForName("id").stringValue} }
            end
            else
            NSLog "Invalid response from server"
		end
		xml = nil
        @parent.artists = @artists 
        @parent.artists.count != 1 ? word = " Artists" : word = " Artist"
        @parent.artist_count_label.stringValue = @artists.count.to_s + word
        @parent.artist_indexes_table_view.reloadData
        NSLog "Persisting Aritsts to the DB"
        if DB[:artists].all.count < 1
            DB.transaction do
                @artists.each {|a| DB[:artists].insert(:name => a[:name], :id => a[:id]) } 
            end
            else
            Dispatch::Queue.new('com.qweef.db').async do
                @artists.each do |a|
                    return if DB[:artists].filter(:id => a[:id]).all.first 
                    DB[:artists].insert(:id => a[:id], :name => a[:name])
                    NSLog "Added Artist: #{a[:name]}"
                end
            end
        end
        NSLog "All Artists presisted to the DB"
	end
    
    def image_response(data)
        NSLog "Here is the image data"
    end
	
	
	#Actual data request methods
	def ping(delegate, method)
        request = build_request("/rest/ping.view", {})
        NSURLConnection.connectionWithRequest(request, delegate:Subsonic::XMLResponse.new(delegate, method))
	end
	
	def getLicense(delegate, method)
        request = build_request('/rest/getLicense.view', {})
        NSURLConnection.connectionWithRequest(request, delegate:Subsonic::XMLResponse.new(delegate, method))
	end
	
	def artists(delegate, method)
        request = build_request('/rest/getIndexes.view', {})
        NSURLConnection.connectionWithRequest(request, delegate:Subsonic::XMLResponse.new(delegate, method))
	end
	
	def albums(id, delegate, method)
        request = build_request('/rest/getMusicDirectory', {:id => id})
        NSURLConnection.connectionWithRequest(request, delegate:Subsonic::XMLResponse.new(delegate, method))
	end
	
	def songs(id, delegate, method)
        request = build_request('/rest/getMusicDirectory', {:id => id})
        NSURLConnection.connectionWithRequest(request, delegate:Subsonic::XMLResponse.new(delegate, method))
	end
    
    def cover_art(id, delegate, method)
        request = build_request('/rest/getCoverArt.view', {:id => id})
        NSURLConnection.connectionWithRequest(request, delegate:Subsonic::ImageResponse.new(delegate, method))
    end
	
	class XMLResponse
        
        def initialize(delegate, method)
            @delegate = delegate
            @method = method
        end
        
        def connection(connection, didReceiveResponse:response)
            @response = response
            @downloadData = NSMutableData.data
        end
        
        def connection(connection, didReceiveData:data)
            @downloadData.appendData(data)
        end
        
        def connectionDidFinishLoading(connection)
            case @response.statusCode
                when 200...300
                xml = NSXMLDocument.alloc.initWithData(@downloadData,
                                                       options:NSXMLDocumentValidate,
                                                       error:nil)
                #@responseBody = NSString.alloc.initWithData(@downloadData, encoding:NSUTF8StringEncoding)
                #NSLog @responseBody
                if xml
                    @delegate.method(@method).call(xml)
                end
                else
                @delegate.method(@method).call(@response.statusCode)
            end
        end
        
        def errorParsingXML
            NSLog "There was an error parsing the response from the server"
        end
        
    end
    
    class ImageResponse
        
        def initialize(delegate, method)
            @delegate = delegate
            @method = method
        end
        
        def connection(connection, didReceiveResponse:response)
            @response = response
            @downloadData = NSMutableData.data
        end
        
        def connection(connection, didReceiveData:data)
            @downloadData.appendData(data)
        end
        
        def connectionDidFinishLoading(connection)
            case @response.statusCode
            when 200...300
                @responseBody = NSString.alloc.initWithData(@downloadData, encoding:NSUTF8StringEncoding)
                NSLog @responseBody
                @delegate.method(@method).call(@downloadData)
            else
                @delegate.method(@method).call(@response.statusCode)
            end
        end
        
        def errorParsingXML
            NSLog "There was an error parsing the response from the server"
        end
        
    end
	
	
	private
	
	def build_request(resource, options)
        options_string = options.collect {|key, value| "#{key}=#{value}"}.join("&")
        url = NSURL.URLWithString(@base_url + resource + "?" + options_string + @extra_params)
        request = NSMutableURLRequest.requestWithURL(url)
        request.setValue("Basic #{@auth_token}", forHTTPHeaderField:"Authorization")
        return request
	end
    
end