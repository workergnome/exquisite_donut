## OpenFrameworks Reference Example

This is a basic example of a OpenFrameworks project that implements all of the rules for the Exquisite Donut project.

The **DonutCop** class holds the rules and the OSC signalling functionality.

The **Sprinkle** class is a basic particle, and could be extended with more sophisticated rules and other hidden variables.

### Possible Improvements

* It would be nice if there wasn't quite as much coupling between the Sprinkle class and the DonutCop class.  Might have to implement an interface, or a copy constructor for subclasses of Sprinkle.
* It really should have an interface where you can set the ID.  
* It really should persist the ID on boot.