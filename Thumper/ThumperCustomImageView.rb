#
#  ThumperCustomImageView.rb
#  Thumper
#
#  Created by Daniel Westendorf on 12/23/11.
#  Copyright 2011 Daniel Westendorf. All rights reserved.
#


class ThumperCustomImageView < NSImageView
    def mouseDown(event)
        NSApp.delegate.show_notification_view
    end
end