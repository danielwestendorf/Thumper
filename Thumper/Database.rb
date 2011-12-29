#
#  Database.rb
#  Thumper
#
#  Created by Daniel Westendorf on 4/8/11.
#  Copyright 2011 Daniel Westendorf. All rights reserved.
#
require 'rubygems'
require 'sqlite3'
require 'sequel'

DB = Sequel.sqlite(Dir.home + "/Library/Thumper/music.db")
class Artist < Sequel::Model
    plugin :schema
    set_schema do
        String  :id, :primary_key => true
        String  :name
    end
    
    create_table unless table_exists?

end

class Album < Sequel::Model
    plugin :schema
    set_schema do
        String :id, :primary_key => true
        String :title
        String :artist
        String :cover_art
        String :artist_id, :index => true
        String :rating
    end

    drop_table if table_exists? && !self.columns.include?(:rating) 
    create_table unless table_exists?

end

class Song < Sequel::Model
    plugin :schema
    set_schema do
        String :id, :primary_key => true
        String :title
        String :artist
        String :duration
        String :bitrate
        String :track
        String :year
        String :genre
        String :size
        String :suffix
        String :album
        String :cover_art
        String :path
        String :cache_path
        String :rating
        String :isVideo
        String :album_id, :index => true
    end
    drop_table if table_exists? && !self.columns.include?(:rating) 
    drop_table if table_exists? && !self.columns.include?(:isVideo) 
    create_table unless table_exists?
end

class PlaylistSong < Sequel::Model
    plugin :schema
    
    set_schema do
        primary_key :id
        String :playlist_id, :index => true
        String :song_id
        String :name, :index => true
    end
    
    create_table unless table_exists?

end

class SmartPlaylist < Sequel::Model
    plugin :schema
    
    set_schema do
        primary_key :id
        String :name
        String :size
        String :genre
        String :fromYear
        String :toYear
    end

create_table unless table_exists?
end

class CachedSong < Sequel::Model
    plugin :schema
    
    set_schema do
        primary_key :id
        String :song_id, :index => true
    end

    create_table unless table_exists?
end