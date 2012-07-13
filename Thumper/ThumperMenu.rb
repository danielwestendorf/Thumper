#
#  ThumperMenu.rb
#  Thumper
#
#  Created by Daniel Westendorf on 7/13/12.
#  Copyright 2012 Daniel Westendorf. All rights reserved.
#

class ThumperMenu

    def initialize
        build_menu
    end
    
    def build_menu
        parent = NSApp.delegate
        
        menu = NSMenu.alloc.initWithTitle "Thumper"
        menu.setDelegate self
        
        if parent.playing_song_object && parent.playing_song #is there a song playing? If so, show it's info
            song = parent.current_playlist[parent.playing_song]
            playing_item = NSMenuItem.alloc
            playing_item.setTitle "#{song[:title]} - #{song[:artist]} (#{song[:duration]})"
            menu.addItem playing_item
        end
        
        play_toggle = NSMenuItem.alloc.init
        play_toggle.setTarget(parent)
        play_toggle.setAction("play_toggle_button:")
        if parent.playing_song_object.rate != 0
            play_toggle.setTitle("Pause")
            img = NSImage.imageNamed('Pause').copy
            img.setSize([12,12])
            play_toggle.setImage img
        else
            play_toggle.setTitle("Play")
            img = NSImage.imageNamed('Play').copy
            img.setSize([12,12])
            play_toggle.setImage img
        end
        menu.addItem(play_toggle)
        
        stop_item = NSMenuItem.alloc.init
        stop_item.setTarget(parent)
        stop_item.setAction("stop_button:")
        stop_item.setTitle("Stop")
        img = NSImage.imageNamed('Stop').copy
        img.setSize([12,12])
        stop_item.setImage img
        menu.addItem(stop_item)
        
        play_next = NSMenuItem.alloc.init
        play_next.setTarget(parent)
        play_next.setAction("play_next_button:")
        play_next.setTitle("Next")
        img = NSImage.imageNamed('Next').copy
        img.setSize([12,12])
        play_next.setImage img
        menu.addItem(play_next)
        
        play_previous = NSMenuItem.alloc.init
        play_previous.setTarget(parent)
        play_previous.setAction("play_previous_button:")
        play_previous.setTitle("Previous")
        img = NSImage.imageNamed('Previous').copy
        img.setSize([12,12])
        play_previous.setImage img
        menu.addItem(play_previous)
        
        parent.status_item.setMenu menu
    end

end