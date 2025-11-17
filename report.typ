#import "../../template.typ": *

#show: project.with(
  theme: "project",
  course: "Advanced Data Structures",
  title: "Projects 4: Red-black Tree",
  date: "2025/11/17",
  semester: "2025-2026 Fall & Winter",
)

= *Chapter 1*: Introduction

== Problem Description

After we learned Red Black Tree in ADS course, we are curious about how to count RBTrees for a given N. This project aims to find multiple methods to count RBTrees for a given internal node number N.
For each algorithm, we analyze its complexity in theory and test it with a full gradient of cases.


#pagebreak()

= *Chapter 2*: Algorithm Specification

We propose 3 methods to solve this problem. From Brute Force Enumerate, to Dynamic Programming, then optimize it with Generating Function. Details are as follows.

== Brute Force Enumerate

...(specify the algorithm, words + pseudo code)

== Dynamic Programming


== Generating Function



#pagebreak()

= *Chapter 3*: Testing and Evaluation
This chapter tests the speed of the program when N = 5 10 20 50 100 1000 5000 10000 50000 100000

== Testing Result

...

#figure(
  image("../../../../images/testing_result.png"),
  caption: [Red-black Tree: Testing],
)

== Evaluation
...

#pagebreak()

= *Chapter 4*: Analysis and Comments

== Time Complexity Analysis

Define the following variables :
- ...

=== Brute Force Enumerate

...(analysis + conclusion)

=== Dynamic Programming

=== Generating Function

== Space Complexity

=== Brute Force Enumerate

...(analysis + conclusion)

=== Classic DP

=== Generating Function


#pagebreak()

= *Chapter 5*: Conclusion and Future Work

== Conclusion
This project successfully ...

In the future, we aim to ...

#pagebreak()

= *Appendix*: Source Code (in C++)

This appendix provides a complete list of the core source files developed for the project.

#codex(read("../code/Mini_Search_Engine/src/BF.cpp"), lang: "cpp")
#codex(read("../code/Mini_Search_Engine/src/DP.cpp"), lang: "cpp")
#codex(read("../code/Mini_Search_Engine/src/GF.cpp"), lang: "cpp")


= *Declaration*

I hereby declare that all the work done in this project is of our group's independent effort.

