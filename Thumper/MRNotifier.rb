#
#  MRNotifier.rb
#  Thumper
#
#  Created by Daniel Westendorf on 12/9/11.
#  Copyright 2011 Daniel Westendorf. All rights reserved.
#


#  MRNotification.rb
#
#  Created by Daniel Westendorf on 12/8/11.
#  MIT Licensed, use as you wish as-is.


framework 'Cocoa'

class MRNotifier
    
    def initialize(d_options={})
        options = {:width => 275, :height => 100, :spacing => 20}
        options.merge!(d_options)
        @panels = []
        @width = options[:width]; @height = options[:height]; @spacing = options[:spacing]
    end
    
    def add_notification(passed_options={})
        default_options = {:title => '', :ttl => 10, :message => ''}
        options = default_options.merge(passed_options)
        
        screen = NSScreen.screens[0]
        
        rect = self.get_rect(screen.visibleFrame)
        
        panel = NSPanel.alloc.initWithContentRect(rect,
                                                  styleMask:NSTitledWindowMask | NSClosableWindowMask | NSUtilityWindowMask |NSHUDWindowMask,
                                                  backing:NSBackingStoreBuffered,
                                                  defer:false,
                                                  screen: screen)
        
        #set the content
        if options[:image]
            options[:image].setSize(NSSize.new(50,50))
            total_frame = panel.contentView.frame
            text_frame = [total_frame.origin.x + 55, total_frame.origin.y, total_frame.size.width - 55, total_frame.size.height - 5]
            img_view = NSImageView.alloc.init.setImage(options[:image])
            
            panel.contentView.addSubview(img_view)
            panel.contentView.subviews[0].setFrame([total_frame.origin.x + 5, total_frame.size.height - 60, 50, 50])
        else
            total_frame = panel.contentView.frame
            text_frame = NSRect.new([total_frame.origin.x, total_frame.origin.y], [total_frame.size.width, total_frame.size.height])
        end
        panel.setTitle(options[:title])
        
        text = NSTextView.alloc.initWithFrame(text_frame)
        text.setDrawsBackground(false)
        text.setTextContainerInset([5, 5])
        text.setFont(NSFont.userFontOfSize(13))
        text.setTextColor(NSColor.lightGrayColor)
        text.setString(options[:message])
        
        panel.contentView.addSubview(text)
        
        #panel settings
        panel.setHidesOnDeactivate(false)
        panel.setReleasedWhenClosed(true)
        panel.orderFrontRegardless
        panel.setMovable(false)
        @panels << panel
        NSTimer.scheduledTimerWithTimeInterval(options[:ttl], target: self, selector:"remove_panel:", userInfo:panel, repeats:false)
        NSNotificationCenter.defaultCenter.addObserver(self, selector:'notification_closed:', name:NSWindowWillCloseNotification, object: panel)
        panel.display
        #NSLog "Actual X: #{panel.frame.origin.x}"
        #NSLog "Actual Y: #{panel.frame.origin.y}"
    end
    
    def notification_closed(notification)
        @panels.delete(notification.object)    
    end
    
    def get_rect(screen)
        #NSLog "Width: #{screen.size.width}"
        #NSLog "Height: #{screen.size.height}"

        
        base_x = screen.size.width - @width - @spacing
        base_y = screen.size.height - @height
        
        x = base_x
        y = base_y
        
        unless @panels.length < 1
            origins = @panels.collect {|panel| [panel.frame.origin.x, panel.frame.origin.y]}
            while origins.include?([x,y])
                if ((y - @height - @spacing * 2) > screen.origin.y)
                    y -= (@height + @spacing * 2)
                else
                    y = base_y
                    x -= (@width + @spacing)
                end
            end
        end
        #NSLog "#{[x, y, @width, @height]}"
        return NSRect.new([x, y], [@width, @height])
        
    end
    
    def remove_panel(timer)
        @panels.delete(timer.userInfo)
        timer.userInfo.close
    end
    
end

