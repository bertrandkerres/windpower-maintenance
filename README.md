# README #

How to use this:

Set up the wind turbine components using the function InitTurbine().

Define the strategies by inheriting from the Technician class, and using an instance of the class as serviceteam.

Run the strategies using Run_Strategies.m

*Known issues:*

- Works only for 1 turbine, not for a farm with several turbines. This is since I started adding the functionality for several turbines, but didn't find the time to do it properly.

- The wind data is generated using random Weibull i.i.d. numbers. This is unrealistic since there is a high auto-correlation at short time scales.