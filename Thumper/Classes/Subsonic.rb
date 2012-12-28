require 'base64'
require 'time'

class Subsonic
    attr_reader :connectivity
    
	def initialize(parent, base_url, username, password)
    @username = username
    @parent = parent
    @password = password
		@base_url = base_url
		@auth_token = Base64.encode64("#{username}:#{password}").strip
		@extra_params = "&f=xml&v=1.7.0&c=Thumper"
	end
	
	#response methods
	def ping_response(xml, options)
		if xml.class == NSXMLDocument && xml.nodesForXPath('subsonic-response', error:nil).first.attributeForName(:status).stringValue == "ok"
            @parent.status_label.stringValue = "Online" 
            NSLog "Online"
            @connectivity = true
            @parent.get_artist_indexes
            @parent.get_playlists
            self.getUser
            self.getMusicFolders
        elsif xml.class == NSXMLDocument
            @parent.status_label.stringValue = "Offline -- #{xml.nodesForXPath('subsonic-response', error:nil).first.nodesForXPath('error', error:nil).first.attributeForName('message').stringValue}"
            connectivity = false
            NSLog "Offline #{@base_url}"
        elsif xml.class == Fixnum
            case xml
                when 401 then @parent.status_label.stringValue = "Offline -- Wrong username or password"
                when 403 then @parent.status_label.stringValue = "Offline -- Access denied"
                when 404 then @parent.status_label.stringValue = "Offline -- Resource not found"
                when 500..600 then @parent.status_label.stringValue = "Offline -- Server error"
            end
		end
		xml = nil
	end
    
    def qp_response(xml, options)
        @qp_albums = []
        if xml.class == NSXMLDocument && xml.nodesForXPath('subsonic-response', error:nil).first.attributeForName(:status).stringValue == "ok"
            albums = xml.nodesForXPath("subsonic-response", error:nil).first.nodesForXPath('albumList', error:nil).first.nodesForXPath('album', error:nil)
            albums.each do |xml_album|
                attributeNames = ["id", "title", "artist", "coverArt", "parent", "isDir"]
                album = {}
                attributeNames.each do |name|
                    album[name.to_sym] = xml_album.attributeForName(name).stringValue unless xml_album.attributeForName(name).nil? 
                end
                album[:cover_art] = Dir.home + "/Library/Thumper/CoverArt/#{album[:coverArt]}.jpg"
                cover_art(album[:coverArt], self, :image_response)
                album[:artist_id] = album[:parent]
                @qp_albums << album if album[:isDir] == "true"
            end
            else
            NSLog "Invalid response from server"
        end
        xml = nil
        #NSLog "Update of QP albums complete. #{@qp_albums.length} albums"
        if @parent.quick_playlists[@parent.quick_playlists_table_view.selectedRow][1] == options[:type]
            selected = @parent.albums_table_view.selectedRow
            options[:append] == true ? @parent.albums += @qp_albums : @parent.albums = @qp_albums
            @parent.reload_albums
            
            @parent.albums_table_view.selectRowIndexes(NSIndexSet.alloc.initWithIndex(selected), byExtendingSelection:false) if selected > -1
        end
        @parent.albums_progress.setHidden(true)
    end
	
	def albums_response(xml, options)
        @albums = []
        @songs = []
        if xml.class == NSXMLDocument && xml.nodesForXPath('subsonic-response', error:nil).first.attributeForName(:status).stringValue == "ok"
            albums = xml.nodesForXPath("subsonic-response", error:nil).first.nodesForXPath('directory', error:nil).first.nodesForXPath('child', error:nil)
            albums.each do |xml_album|
                attributeNames = ["id", "title", "artist", "coverArt", "parent", "isDir", "userRating"]
                album = {}
                attributeNames.each do |name|
                    album[name.to_sym] = xml_album.attributeForName(name).stringValue unless xml_album.attributeForName(name).nil? 
                end
                #NSLog "Album CA #{album[:coverArt]}"
                album[:cover_art] = Dir.home + "/Library/Thumper/CoverArt/#{album[:coverArt]}.jpg"
                album[:artist_id] = album[:parent]
                if album[:userRating]
                    album[:rating] = album[:userRating]
                else
                    album[:rating] = "Unrated"
                end
                
                #NSLog "Album rating: #{album[:rating]}"

                @albums << album if album[:isDir] == "true"
                
                unless File.exists?(album[:cover_art])
                    @parent.get_cover_art(album[:coverArt])
                end
                
                if album[:isDir] == "false"
                    song = parse_song(xml_album)
                    @songs << song
                end
            end
        else
            NSLog "Invalid response from server"
        end
        xml = nil
        #NSLog "Update of artist albums complete. #{@albums.length} albums #{@albums}"
        if @albums.length > 0
            artist_id = @albums.first[:artist_id]
        elsif @songs.length > 0
            artist_id = @songs.first[:parent]
        else
            artist_id = nil
        end
        
        #if @parent.artists[@parent.artist_indexes_table_view.selectedRow][:id] == artist_id
            @parent.albums = @albums
            @parent.songs = @songs
            @parent.reload_albums
            @parent.reload_songs
        #end
        #NSLog "Persisting albums to the DB"
        if @albums.length > 0 && DB[:albums].filter(:artist_id => @albums.first[:artist_id]).all.count < 1
            DB.transaction do
                @albums.each {|a| DB[:albums].insert(:title => a[:title], :id => a[:id], :cover_art => a[:cover_art], :artist_id => a[:artist_id], :rating => a[:rating]) } 
            end
        else
            @parent.db_queue.async do
                @albums.each do |a|
                    return if DB[:albums].filter(:id => a[:id]).all.first 
                    DB[:albums].insert(:title => a[:title], :id => a[:id], :cover_art => a[:cover_art], :artist_id => a[:artist_id])
                    #NSLog "Added Album: #{a[:title]}"
                end
            end
        end
        # NSLog "All Albums presisted to the DB"
        @parent.albums_progress.stopAnimation(nil)
        if @albums.length == 1 && @songs.length < 1
            @parent.get_album_songs(@albums.first[:id]) 
            range = NSMakeRange(0, 1)
            indexes = NSIndexSet.alloc.initWithIndexesInRange(range)
            @parent.albums_table_view.selectRowIndexes(indexes, byExtendingSelection:true)
            @parent.main_window.makeFirstResponder(@parent.albums_table_view)
        end
	end
	
	def songs_response(xml, options)
        @songs = []
        if xml.class == NSXMLDocument && xml.nodesForXPath('subsonic-response', error:nil).first.attributeForName(:status).stringValue == "ok"
            songs = xml.nodesForXPath("subsonic-response", error:nil).first.nodesForXPath('directory', error:nil).first.nodesForXPath('child', error:nil)
            
            songs.each do |xml_song|
                song = parse_song(xml_song)
                @songs << song if song[:isDir] == "false"
            end
        else
            NSLog "Invalid response from server"
        end
        #NSLog "Update of ablum songs complete. #{@songs.length} songs"
        xml = nil
        if @songs.length > 0 && @parent.albums.length > 0 && @parent.albums[@parent.albums_table_view.selectedRow][:id] == @songs.first[:album_id]
            @parent.songs = @songs
            @parent.reload_songs
            @parent.songs_table_view.enabled = true
        end
        @parent.songs_progress.stopAnimation(nil)
        #NSLog "All songs presisted to the DB"
	end
	
	def artists_response(xml, options)
        @artists = []
		if xml.class == NSXMLDocument && xml.nodesForXPath('subsonic-response', error:nil).first.attributeForName(:status).stringValue == "ok"
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
        @parent.all_artists = @artists
        @parent.artists.count != 1 ? word = " Artists" : word = " Artist"
        @parent.artist_count_label.stringValue = @artists.count.to_s + word
        @parent.artist_indexes_table_view.reloadData
        #NSLog "Persisting Aritsts to the DB"
        if DB[:artists].all.count < 1
            DB.transaction do
                @artists.each {|a| DB[:artists].insert(:name => a[:name], :id => a[:id]) } 
            end
        else
            @parent.db_queue.async do
                @artists.each do |a|
                    return if DB[:artists].filter(:id => a[:id]).all.first 
                    DB[:artists].insert(:id => a[:id], :name => a[:name])
                    #NSLog "Added Artist: #{a[:name]}"
                end
            end
        end
        @parent.artists_progress.stopAnimation(nil)
        #NSLog "All Artists presisted to the DB #{@parent.artists.length}"
	end

    def playlists_response(xml, options)
        @playlists = []
        if xml.class == NSXMLDocument && xml.nodesForXPath('subsonic-response', error:nil).first.attributeForName(:status).stringValue == "ok"
            playlists = xml.nodesForXPath("subsonic-response", error:nil).first.nodesForXPath('playlists', error:nil).first.nodesForXPath('playlist', error:nil)
            playlists.each do |playlist|
                @playlists << {:name => playlist.attributeForName("name").stringValue, :id => playlist.attributeForName("id").stringValue}
            end
        end
        #NSLog "Got playlists from server"
        @parent.playlists = @playlists
        @parent.reload_playlists
        @parent.playlists_progress.stopAnimation(nil)
    end
    
    def playlist_response(xml, options)
        @playlist_songs = []
        if xml.class == NSXMLDocument && xml.nodesForXPath('subsonic-response', error:nil).first.attributeForName(:status).stringValue == "ok"
            playlist_id = xml.nodesForXPath("subsonic-response", error:nil).first.nodesForXPath('playlist', error:nil).first.attributeForName("id").stringValue
            playlist_name = xml.nodesForXPath("subsonic-response", error:nil).first.nodesForXPath('playlist', error:nil).first.attributeForName("name").stringValue
            playlist_songs = xml.nodesForXPath("subsonic-response", error:nil).first.nodesForXPath('playlist', error:nil).first.nodesForXPath('entry', error:nil)
            playlist_songs.each do |xml_song|
                song = parse_song(xml_song)
                @playlist_songs << song if song[:isDir] == "false"
            end 
        end
        @parent.playlist_songs = @playlist_songs if @parent.playlists[@parent.playlists_table_view.selectedRow][:id] == playlist_id
        @parent.db_queue.async do
            DB[:playlist_songs].filter(:playlist_id => playlist_id).delete
            @playlist_songs.each do |s|
                DB[:playlist_songs].insert(:playlist_id => playlist_id, :name => playlist_name, :song_id => s[:id])
            end
        end
        @parent.reload_playlist_songs
        @parent.playlist_songs_progress.stopAnimation(nil)
    end
    
    def smart_playlist_response(xml, options)
        @playlist_songs = []
        if xml.class == NSXMLDocument && xml.nodesForXPath('subsonic-response', error:nil).first.attributeForName(:status).stringValue == "ok"
            playlist_songs = xml.nodesForXPath("subsonic-response", error:nil).first.nodesForXPath('randomSongs', error:nil).first.nodesForXPath('song', error:nil)
            
            playlist_songs.each do |xml_song|
                song = parse_song(xml_song)
                @playlist_songs << song if song[:isDir] == "false"
            end 
        end
        @parent.playlist_songs = @playlist_songs
        @parent.reload_playlist_songs
        @parent.playlist_songs_progress.stopAnimation(nil)
    end
    
    def now_playing_response(xml, options)
        if xml.class == NSXMLDocument && xml.nodesForXPath('subsonic-response', error:nil).first.attributeForName(:status).stringValue == "ok"
            now_playing_songs = xml.nodesForXPath("subsonic-response", error:nil).first.nodesForXPath('nowPlaying', error:nil).first.nodesForXPath('entry', error:nil)
            attributeNames = ["title", "artist", "username", "album", "coverArt", "playerName", "minutesAgo"]
            now_playing_songs.each do |xml_song|
                song = {}
                attributeNames.each do |name|
                    song[name.to_sym] = xml_song.attributeForName(name).stringValue unless xml_song.attributeForName(name).nil? 
                end
                song[:added_time] = Time.now
                found = false
                @parent.now_playing.each do |np|
                    if np[:username] == song[:username] && song[:playerName] == song[:playerName] && np[:title] == song[:title] && np[:artist] == song[:artist]
                        index = @parent.now_playing.find_index(np)
                        @parent.now_playing[index] =  song
                        found = true
                    elsif np[:username] == song[:username] && np[:playerName] == song[:playerName] && np[:title] != song[:title] && np[:artist] != song[:artist]
                        @parent.now_playing.delete(np)
                    end
                    @parent.now_playing.delete(np) if np[:added_time] < (Time.now - 3600)
                end
                if found == false
                    @parent.now_playing << song
                    growl_now_playing(song) unless [song[:playerName], song[:username]] == ["Thumper", @parent.username] 
                end
            end 
        end
    end
    
    def show_all_now_playing
        @parent.now_playing.sort! {|a, b| a[:minutesAgo].to_i <=> b[:minutesAgo].to_i}
        @parent.now_playing.each {|song| growl_now_playing(song)} 
    end
        
    def growl_now_playing(song)
        @parent.db_queue.sync do
            path = Dir.home + "/Library/Thumper/CoverArt/#{song[:coverArt]}.jpg"
            if !File.exists?(path)
                request = build_request("/rest/getCoverArt.view", {:id => song[:coverArt]})
                data = NSURLConnection.sendSynchronousRequest(request, returningResponse:nil, error:nil)
                data.writeToFile(path, atomically:true)
            end
            
            img = NSImage.alloc.initWithContentsOfFile(path)
            
            #g = Growl.new("Thumper", ["notification"], img)
            if song[:minutesAgo] == '0' 
                time_ago = 'Just now'
            elsif song[:minutesAgo] == '1' 
                time_ago = song[:minutesAgo] + ' Miniute ago'
            else
                time_ago = song[:minutesAgo] + ' Miniutes ago'
            end
            @parent.change_notification_text("#{song[:username]} is listening to #{song[:title]} by #{song[:artist]}")
            #@parent.notification_queue.add_notification({:title => "#{song[:username]} is listening to...", :message => "Title: #{song[:title]}\nArtist: #{song[:artist]}\nAlbum: #{song[:album]}\nClient: #{song[:playerName].nil? ? 'Web Interface' : song[:playerName]} #{time_ago}", :image => img})
            #g.notify("notification", "#{song[:username]} is listening to...", "Title: #{song[:title]}\nArtist: #{song[:artist]}\nAlbum: #{song[:album]}\nClient: #{song[:playerName].nil? ? 'Web Interface' : song[:playerName]} #{time_ago}") 
        end
    end
    
    def image_response(data, path, id)
        #puts "got album #{id}, #{path}"
        response = data.writeToFile(path, atomically:true)
        @parent.albums_table_view.reloadData
        @parent.set_playing_cover_art
    end
    
    def download_media_response(data, path, id)
        path_step = "/"
        split_path = path.split('/')
        split_path.delete_at(0)
        split_path.delete_at(split_path.length - 1)
        split_path.each do |dir|
            path_step << dir
            if !File.exists?(path_step)
                Dir.mkdir(path_step)
            end
            path_step << '/'
        end
        response = data.writeToFile(path, atomically:true)
        #NSLog "Saved downloaded file to #{path}"
    end
	
    def scrobble_response(xml, options)
        #NSLog "Successfully scrobbled song" if xml.class == NSXMLDocument 
        @parent.subsonic.get_now_playing(@parent.subsonic, :now_playing_response)
    end
    
    def share_response(xml, options)
        if xml.class == NSXMLDocument && xml.nodesForXPath('subsonic-response', error:nil).first.attributeForName(:status).stringValue == "ok"
            share = xml.nodesForXPath("subsonic-response", error:nil).first.nodesForXPath('shares', error:nil).first.nodesForXPath('share', error:nil).first
            unless share.attributeForName("url").nil?
                url = share.attributeForName("url").stringValue
                @parent.share_link_text_field.stringValue = url
                modal = SimpleModal.new(@parent.main_window, @parent.share_link_window)
                modal.add_outlet(@parent.share_link_close_button) do
                    pb = NSPasteboard.generalPasteboard
                    pb.declareTypes([NSStringPboardType], owner:nil)
                    pb.setString(url, forType:NSStringPboardType)
                end
                modal.show
            end
        end
    end
	
	#Actual data request methods
	def ping(delegate, method)
        request = build_request("/rest/ping.view", {})
        NSURLConnection.connectionWithRequest(request, delegate:XMLResponse.new(delegate, method))
	end
    
    def check_connectivity(timer)
        ping(self, :ping_response)
    end
	
	def getLicense(delegate, method)
        request = build_request('/rest/getLicense.view', {})
        NSURLConnection.connectionWithRequest(request, delegate:XMLResponse.new(delegate, method))
	end
    
    def getUser
        request = build_request('/rest/getUser.view', {:username => @username} ) 
        NSURLConnection.connectionWithRequest(request, delegate:XMLResponse.new(self, :getUserResponse))
    end
    
    def getUserResponse(xml, options)
        if xml.class == NSXMLDocument && xml.nodesForXPath('subsonic-response', error:nil).first.attributeForName(:status).stringValue == "ok"
            user = xml.nodesForXPath("subsonic-response", error:nil).first.nodesForXPath('user', error:nil).first
            #user.attributeForName("scrobblingEnabled").stringValue == "true" ? @parent.scrobbling_enabled = true : @parent.scrobbling_enabled = false
            #user.attributeForName("downloadRole").stringValue == "true" ? @parent.downloading_enabled = true : @parent.downloading_enabled = false
            user.attributeForName("shareRole") && user.attributeForName("shareRole").stringValue == "true" ? @parent.sharing_enabled = true : @parent.sharing_enabled = false
            user.attributeForName("commentRole") && user.attributeForName("commentRole").stringValue == "true" ? @parent.rating_enabled = true : @parent.rating_enabled = false
            NSLog "Sharing is not enabled for #{@username}" unless @parent.sharing_enabled
            #NSLog "Downloading is not enabled for #{@username}" unless @parent.downloading_enabled
            NSLog "Rating and Commenting is not enabled for #{@username}" unless @parent.rating_enabled
            
            #NSLog "Scrobbling is not enabled for #{@username}" unless @parent.scrobbling_enabled
            
            if xml.nodesForXPath('subsonic-response', error:nil).first.attributeForName(:version).stringValue.to_f < 1.7
                NSLog "Transcoding not supported, upgrade your Subsonic instance to at least 4.6. Current API Version: #{xml.nodesForXPath('subsonic-response', error:nil).first.attributeForName(:version).stringValue.to_f}"
                @parent.bitrate = 0
                @parent.bitrate_field.setEnabled(false)
            end
        end
    end
    
    def getMusicFolders
        request = build_request('/rest/getMusicFolders.view', {}) 
        NSURLConnection.connectionWithRequest(request, delegate:XMLResponse.new(self, :getMusicFoldersResponse))
    end
    
    def getMusicFoldersResponse(xml, options)
        if xml.class == NSXMLDocument && xml.nodesForXPath('subsonic-response', error:nil).first.attributeForName(:status).stringValue == "ok"
            folders = xml.nodesForXPath("subsonic-response", error:nil).first.nodesForXPath('musicFolders', error:nil).first.nodesForXPath('musicFolder', error:nil)
            @parent.music_folders = []
            folders.each do |folder|
                @parent.music_folders << {:id => folder.attributeForName("id").stringValue, :name => folder.attributeForName("name").stringValue}
            end
            @parent.build_music_folder_menu
        end
    end
	
	def artists(delegate, method)
        options = {}
        options["musicFolderId"] = @parent.current_music_folder if @parent.current_music_folder
        request = build_request('/rest/getIndexes.view', options)
        NSURLConnection.connectionWithRequest(request, delegate:XMLResponse.new(delegate, method))
	end
    
    def quick_playlists(options, delegate, method)
        options[:size] = 50 
        request = build_request("/rest/getAlbumList.view",  options)
        NSURLConnection.connectionWithRequest(request, delegate:XMLResponse.new(delegate, method, options))
    end
	
	def albums(id, delegate, method)
        #NSLog "Getting album #{id}"
        request = build_request('/rest/getMusicDirectory.view', {:id => id})
        NSURLConnection.connectionWithRequest(request, delegate:XMLResponse.new(delegate, method))
	end
	
	def songs(id, delegate, method)
        request = build_request('/rest/getMusicDirectory.view', {:id => id})
        NSURLConnection.connectionWithRequest(request, delegate:XMLResponse.new(delegate, method))
	end
    
    def cover_art(id, delegate, method)
        request = build_request('/rest/getCoverArt.view', {:id => id})
        path = Dir.home + "/Library/Thumper/CoverArt/#{id}.jpg"
        connection = NSURLConnection.connectionWithRequest(request, delegate:DownloadResponse.new(path, id, delegate, method))
    end
    
    def playlists(delegate, method)
        request = build_request('/rest/getPlaylists.view', {})
        NSURLConnection.connectionWithRequest(request, delegate:XMLResponse.new(delegate, method))
    end
    
    def playlist(id, delegate, method)
        request = build_request('/rest/getPlaylist.view', {:id => id})
        NSURLConnection.connectionWithRequest(request, delegate:XMLResponse.new(delegate, method))
    end
    
    def smart_playlist(options, delegate, method)
        request = build_request('/rest/getRandomSongs.view', options)
        NSURLConnection.connectionWithRequest(request, delegate:XMLResponse.new(delegate, method, options))
    end
    
    def delete_playlist(id, delegate, method)
        request = build_request('/rest/deletePlaylist.view', {:id => id})
        NSURLConnection.connectionWithRequest(request, delegate:XMLResponse.new(delegate, method))
    end
    
    def search(query, delegate, method)
        request = build_request('/rest/search.view', {:any => query, :count => 100})
        NSURLConnection.connectionWithRequest(request, delegate:XMLResponse.new(delegate, method))
    end
    
    def create_playlist(name, song_ids, delegate, method)
        request = build_request('/rest/createPlaylist.view', {})
        request.HTTPMethod = "POST"
        body = "name=#{name}"
        song_ids.each {|id| body << "&songId=#{id}" }
        request.HTTPBody = body.dataUsingEncoding(NSUTF8StringEncoding)
        NSURLConnection.connectionWithRequest(request, delegate:XMLResponse.new(delegate, method))
    end
    
    def download_media(path, id, delegate, method)
        @parent.downloading_song.cancel if @parent.downloading_song
        #NSLog "Attempting to download #{id}"
        request = build_request('/rest/stream.view', {:id => id})
        @parent.downloading_song = NSURLConnection.connectionWithRequest(request, delegate:DownloadResponse.new(path, id, delegate, method))
    end
    
    def scrobble(id, delegate, method)
        #NSLog "Attempting to scrobble now playing"
        scrobble_request = build_request('/rest/scrobble.view', {:id => id})
        NSURLConnection.connectionWithRequest(scrobble_request, delegate:XMLResponse.new(delegate, method))
        now_playing_request = build_request('/rest/stream.view', {:id => id})
        @conn = NSURLConnection.connectionWithRequest(now_playing_request, delegate:self)
    end
    
    def share(object, delegate, method)
        #NSLog "Attempting to scrobble now playing"
        share_request = build_request('/rest/createShare.view', {:id => object[:id], :expires => (Time.now + object[:expiration]).to_i * 1000 })
        NSURLConnection.connectionWithRequest(share_request, delegate:XMLResponse.new(delegate, method))
    end
    
    def rate(object)
        rate_request = build_request('/rest/setRating.view', {:id => object[:id], :rating => object[:rating].to_i})
        NSURLConnection.connectionWithRequest(rate_request, delegate:XMLResponse.new(self, :rating_response, object))
    end
    
    def rating_response(xml, object)
        
    end
    
    def get_now_playing(delegate, method)
        request = build_request("/rest/getNowPlaying.view", {})
        NSURLConnection.connectionWithRequest(request, delegate:XMLResponse.new(delegate, method))
    end
    
    def connection(connection, didReceiveResponse:response)
        case response.statusCode
        when 200..300
            @conn.cancel
            #NSLog "Canceled KilledResposne"
        else
            #NSLog "There was an error with the request: #{response.statusCode}"
        end
    end
	
	private
    
    def parse_song(xml_song)
        return if xml_song.nil?
        attributeNames = ["id", "title", "artist", "coverArt", "parent", "isDir", "duration", "bitRate", "track", "year", "genre", "size", "suffix",
        "album", "path", "size", "userRating", "isVideo"]
        song = {}
        attributeNames.each do |name|
            song[name.to_sym] = xml_song.attributeForName(name).stringValue unless xml_song.attributeForName(name).nil? 
        end
        song[:cover_art] = Dir.home + "/Library/Thumper/CoverArt/#{song[:coverArt]}.jpg"
        song[:album_id] = song[:parent]
        song[:bitrate] = song[:bitRate]
        song[:duration] = @parent.format_time(song[:duration].to_i)
      #NSLog "#{song[:path]}"
        song[:cache_path] = Dir.home + '/Music/Thumper/' + song[:path].gsub(/\.[^.]+$/, '.mp3') unless song[:isDir] == "true"
      #NSLog "#{song[:cache_path]}"
        #xml_song.attributes.each {|attr| p attr.name}
        if xml_song.attributeForName("userRating").nil?
            song[:rating] = "Unrated"
        else
            song[:rating] = xml_song.attributeForName("userRating").stringValue
        end
        
        @parent.db_queue.sync do
            unless DB[:songs].filter(:id => song[:id]).all.first 
                DB[:songs].insert(:id => song[:id], :title => song[:title], :artist => song[:artist], :duration => song[:duration], 
                                  :bitrate => song[:bitrate], :track => song[:track], :year => song[:year], :genre => song[:genre],
                                  :size => song[:size], :suffix => song[:suffix], :album => song[:album], :album_id => song[:album_id],
                                  :cover_art => song[:cover_art], :path => song[:path], :cache_path => song[:cache_path], :rating => song[:rating], 
                                  :isVideo => song[:isVideo])
            else
                DB[:songs].filter(:id => song[:id]).all.first.update(:title => song[:title], :artist => song[:artist], :duration => song[:duration], 
                                  :bitrate => song[:bitrate], :track => song[:track], :year => song[:year], :genre => song[:genre],
                                  :size => song[:size], :suffix => song[:suffix], :album => song[:album], :album_id => song[:album_id],
                                  :cover_art => song[:cover_art], :path => song[:path], :cache_path => song[:cache_path], :rating => song[:rating],
                                  :isVideo => song[:isVideo])
            end 
        end
      
        return song
    end
	
	def build_request(resource, options)
        options_string = options.collect do |key, value| 
            if value.class != Array
                "#{key}=#{value}"   
            else
                value.collect {|array_value| "#{key}=#{array_value}"}.join("&")
            end
        end
        url = NSURL.URLWithString(@base_url + resource + "?" + options_string.join("&") + @extra_params + "&u=#{@username}&p=#{@password}")
        NSLog "#{url.absoluteString}"
        request = NSMutableURLRequest.requestWithURL(url, cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData, timeoutInterval:5.0)
        request.setValue("Basic #{@auth_token}", forHTTPHeaderField:"Authorization")
        return request
	end
    
end

class XMLResponse
    
    def initialize(delegate, method, options={})
        @delegate = delegate
        @method = method
        @options = options
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
            #NSLog NSString.alloc.initWithData(@downloadData, encoding:NSUTF8StringEncoding)
            #NSLog @responseBody
            if xml
                #NSLog "Methods: #{@delegate.class.class}"
                @delegate.method(@method).call(xml, @options)
            end
        else
            NSLog "ERROR! #{@response.statusCode}, #{@options}"
            NSLog NSString.alloc.initWithData(@downloadData, encoding:NSUTF8StringEncoding)
            @delegate.method(@method).call(@response.statusCode, nil)
        end
    end        
end

class DownloadResponse
    
    def initialize(path, id, delegate, method)
        @delegate = delegate
        @method = method
        @path = path
        @id = id
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
            @delegate.method(@method).call(@downloadData, @path, @id)
        else
            NSLog "Image response: #{@response.statusCode}"
        end
    end
    
end