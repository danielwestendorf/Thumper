class SimpleModal
    
    attr_accessor :window, :modal, :parent, :outlets

    def initialize(window, modal)
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
    
    def add_outlet(sending_object, exit_on_finish=true,  &block)
        @outlets << ModalOutlet.new(self, sending_object, exit_on_finish, &block)
    end
        
    def close(sender)
        NSApp.endSheet(@modal)
        @modal.orderOut(sender)
    end
    
end

class ModalOutlet

    def initialize(simple_modal, sending_object, exit_on_finish, &block)
        @sending_object = sending_object
        @sending_object.setTarget(self)
        @sending_object.setAction("fire:")
        @block = block
        @simple_modal = simple_modal
        @exit_on_finish = exit_on_finish
    end
    
    def fire(sender)
        @block.call
        if @exit_on_finish
            NSApp.endSheet(@simple_modal.modal)
            @simple_modal.modal.orderOut(sender)
        end
    end
end