class SimpleModal
    
    attr_accessor :window, :modal, :parent, :outlets

    def initialize(parent, window, modal)
        @window = window
        @modal = modal
        @outlets = []
    end
    
    def show
         NSApp.beginSheet(@modal,
            modalForWindow:@window,
            modalDelegate:self,
            didEndSelector:nil,
            contextInfo:nil)
    end
    
    def add_outlet(sending_object, &block)
        @outlets << ModalOutlet.new(self, sending_object, &block)
    end
        
    def close(sender)
        NSApp.endSheet(@modal)
        @modal.orderOut(sender)
    end
    
end

class ModalOutlet

    def initialize(modal, sending_object, &block)
        @sending_object = sending_object
        @sending_object.setTarget(self)
        @sending_object.setAction("fire:")
        @block = block
        @modal = modal
    end
    
    def fire(sender)
        @block.call
    end
end