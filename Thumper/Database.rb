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
        primary_key  :id
        String  :subsonic_id, :index => true
        String  :name, :index => true
    end
    
    create_table unless table_exists?

end
