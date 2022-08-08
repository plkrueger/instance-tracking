# instance-tracking
 Common Lisp meta-class for tracking instances

Manually tracking class instances using a class-allocated slot is not too difficult, but you cannot just define a super-class "instance-tracking" that does this because then it will have a single slot that contains all the instances for ALL subclasses. To get the desired behavior this implements a :metaclass that can be used when defining a class that adds the necessary class-allocated slot to that each new subclass of that type (classes must declare a metaclass for a class that you want to track-instances:
	(defclass it-class ()
	  ((slot-1 :accessor slot-1))
	  (:metaclass instance-tracking))

Then, to make sure that instance-tracking functions are applicable to instances of the newly defined class, the instance-tracking metaclass will also assure that all new classes also inherit from the class pk-inst-track::inst-track automatically without any user declarations required.