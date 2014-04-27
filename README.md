HackathonCLT-hive-R
===================

My entry into the 2014 Hackathon CLT Hadoop Data Analysis competition at Tresata in Packard Place

===================

Overview from <a href="http://www.hackathonclt.org/faq.html">HackathonCLT</a>:  A hackathon is social coding event where programmers, designers and developers collaborate to solve a problem and compete for cash prizes. It's one part party, one part work-your-butt-off overnight battle against the clock. 


Arun Natva and I placed 2nd in the competition.

General Flow:
 - Use HQL to do subsetting and summarize data
 - Use R for additional munging and exploratory graph building


After running the HQL trying to read it into R, we stumbled upon a strange delimiter, ^A or \001, and need to change it in order to properly read the data into R.  Here is the bash we ran to change the delimiter to a pipe and save the results in catsales_fmtd.dat.

    cat catsales.dat | tr "\001" "|" > catsales_fmtd.dat
