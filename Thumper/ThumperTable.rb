class ThumperCMTable < NSTableView
    
    
    def menuForEvent(event)
        
        where = self.convertPoint(event.locationInWindow, fromView:nil)
        row = self.rowAtPoint(where)
        
        if row >= 0
            if self.delegate.represented_objects.length > 0
                menu = NSMenu.alloc.initWithTitle("Thumper")
                object = self.delegate.represented_objects[row]
                if  self.delegate.share_enabled && self.delegate.parent.sharing_enabled
                    share_menu = NSMenuItem.alloc.init
                    share_menu.setTitle("Share")
                    share_sub_menu = NSMenu.alloc.init
                    [
                     {:title => '1 day from now', :expiration => 86400},
                     {:title => '1 week from now', :expiration => 604800}, 
                     {:title => '1 month from now', :expiration => 2419200}, 
                     {:title => '1 year from now', :expiration => 31536000}
                    ].each do |i|
                        menu_item = NSMenuItem.alloc.init
                        menu_item.setTitle("Expires: #{i[:title]}")
                        menu_item.representedObject = object.merge(i)
                        menu_item.setTarget(self.delegate.parent)
                        menu_item.setAction("share_item:")
                        share_sub_menu.addItem(menu_item)
                    end
                    share_menu.setSubmenu(share_sub_menu)
                    menu.addItem(share_menu)
                end
                if self.delegate.rate_enabled && self.delegate.parent.rating_enabled
                    rate_menu = NSMenuItem.alloc.init
                    rate_menu.setTitle("Rate")
                    rate_sub_menu = NSMenu.alloc.init
                    (0..5).each do |i|
                        menu_item = NSMenuItem.alloc.init
                        menu_item.setTitle("#{i} Stars")
                        menu_item.representedObject = object.merge({:rating => i, :row => row})
                        menu_item.setTarget(self.delegate)
                        menu_item.setAction("rate_item:")
                        rate_sub_menu.addItem(menu_item)
                    end
                    rate_menu.setSubmenu(rate_sub_menu)
                    menu.addItem(rate_menu)
                end
                self.selectRowIndexes(NSIndexSet.indexSetWithIndex(row), byExtendingSelection:false) 
            end
            
            return menu
        end
    end
    
end

class ThumperTable < ThumperCMTable
    attr_accessor :delegator

    def keyDown(event)
        characters = event.characters
        character = characters.characterAtIndex(0)
        if character == NSDeleteCharacter
            @delegator.pressed_delete
        elsif character == 97 && (event.modifierFlags & NSCommandKeyMask) == NSCommandKeyMask
            @delegator.select_all
        else
            super(event)
        end
    end
    
    

end