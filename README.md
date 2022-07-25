# 18-decimal Natural Exponential Function in Cairo

To use, simply import the `exp` function inside `exp.cairo` into your project. 

The `exp` function accepts 18-decimal numbers (fixed point numbers scaled by `10**18`), both positive and negative (well, Cairo's version of negative), that are in the range [-40, 40] (inclusive). 

This implementation comes with a property-based test-suite. The number of examples is set to 100 for each test so 
that it doesn't take too long to run, but I encourage you to play around with both the number of examples and other 
features of hypothesis like targeting in order to help find any potential bugs. 
