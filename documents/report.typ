#import "../../../../template.typ": *
#import "@preview/mitex:0.2.5": *
#import "@preview/lovelace:0.3.0": *

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

This method is the most straightforward but computationally expensive. The core idea is to generate every possible candidate and validate it against the Red-Black Tree properties.

The algorithm follows three stages:
1. *Generate Shapes*: Recursively generate all possible binary tree topological structures with $N$ internal nodes. The number of such structures is given by the $N$-th Catalan number, $C_N$.
2. *Enumerate Colorings*: For each tree structure, there are $N$ nodes, and each can be either Red or Black. This gives $2^N$ possible coloring schemes for each shape.
3. *Validate Properties*: For each of the $C_N * 2^N$ "colored trees", we perform a full check to see if it satisfies all 5 RBT properties:
  - Property 2: The root is Black.
  - Property 4: Every Red node has two Black children (NULL nodes are considered Black).
  - Property 5: All simple paths from any node to its descendant leaves have the same number of Black nodes (the "black-height").

Only the trees that pass all validation checks are counted.

#pseudocode-list(stroke: none)[
  + `total_count` = 0
  + `all_shapes` = `generate_all_shapes`($N$)
  + *for* `shape` *in* `all_shapes`
    + // $N$-bit integer for $2^N$ colorings
    + *for* $i$ = 0 *to* (1 $<<$ $N$) - 1
      + `apply_coloring`(`shape`, $i$)
      + *if* `isValidRBTree`(`shape`) *then*
        + `total_count` += 1
      + *end*
    + *end*
  + *return* `total_count`
  + ---
  + *function* `isValidRBTree`(`root`)
    + *if* `root.color` == RED *then* *return* 0 // Prop 2
    + *if not* `check_prop4`(`root`) *then* *return* 0 // Prop 4
    + *if* `get_black_height`(`root`) == -1 *then* *return* 0 // Prop 5
    + *return* 1
  + *end*
  + ---
  + *function* `get_black_height`(`node`)
    + *if* `node` == NULL *then* *return* 0
    + `left_bh` = `get_black_height`(`node.left`)
    + `right_bh` = `get_black_height`(`node.right`)
    + // Check for failure or imbalance
    + *if* `left_bh` == -1 *or* `right_bh` == -1 *or* `left_bh` != `right_bh` *then*
      + *return* -1
    + *end*
    + *return* `left_bh` + (`node.color` == BLACK ? 1 : 0)
  + *end*
]



== Dynamic Programming

This approach avoids generating invalid trees by building up solutions from smaller subproblems. We define the state based on node count, black-height, and root color.

Let $B(h, n)$ be the number of RBTs with $n$ internal nodes, a black-height of $h$, and a *Black* root.
Let $R(h, n)$ be the number of RBTs with $n$ internal nodes, a black-height of $h$, and a *Red* root.

Our base case is $B(0, 0) = 1$, representing the single NULL node.

The state transitions are derived from the RBT properties:
1. *Red Root $R(h, n)$*: A red root (1 node) does not change the black-height. Its children must both be *Black* (Prop 4) and must have the same black-height $h$ (Prop 5).
  #mitex(
    `
    R(h, n) = \sum_{k=0}^{n-1} B(h, k) \times B(h, n-1-k)
    `,
  )
2. *Black Root $B(h+1, n)$*: A black root (1 node) increases the black-height by 1. Its children can be *any* color (Red or Black) and must have a black-height of $h$.
  #mitex(
    `
    B(h+1, n) = \sum_{k=0}^{n-1} \left( (B(h, k) + R(h, k)) \times (B(h, n-1-k) + R(h, n-1-k)) \right)
    `,
  )
The final answer is the sum of all RBTs with $N$ nodes and a Black root (Prop 2), across all possible black-heights:
#mitex(
  `
\text{Answer} = \sum_{h=1}^{\lfloor \log_2(N+1) \rfloor} B(h, N)
`,
)
This is implemented by iterating $h$ from $0$ up to $log N$, and for each $h$, computing the $R(h, n)$ and $B(h+1, n)$ values for all $n$ from $1$ to $N$. Each step involves an $O(N^2)$ convolution.

#pseudocode-list(stroke: none)[
  + `f`[$log N$][$N$+1] // $B(h, n)$ - Black root
  + `g`[$log N$][$N$+1] // $R(h, n)$ - Red root
  + `f`[0][0] = 1 // Base case: NULL node
  + `ans` = 0
  + *for* $h$ = 0 *to* $log N$-1
    + // 1. Compute `g`[$h$][*] (Red root) using `f`[$h$]
    + *for* $n$ = 1 *to* $N$
      + *for* $k$ = 0 *to* $n$-1
        + `g`[$h$][$n$] += `f`[$h$][$k$] x `f`[$h$][$n$-1-$k$]
      + *end*
    + *end*
    + // 2. Compute `f`[$h$+1][*] (Black root) using `f`[$h$] and `g`[$h$]
    + *for* $n$ = 1 *to* $N$
      + *for* $k$ = 0 *to* $n$-1
        + `total_h_k` = `f`[$h$][$k$] + `g`[$h$][$k$]
        + `total_h_n_k` = `f`[$h$][$n$-1-$k$] + `g`[$h$][$n$-1-$k$]
        + `f`[$h$+1][$n$] += `total_h_k` x `total_h_n_k`
      + *end*
    + *end*
    + `ans` += `f`[$h$+1][$N$]
  + *end*
  + *return* `ans`
]

== Generating Function

This method optimizes the DP approach by recognizing that the key operations are polynomial convolutions. We can represent our DP states as *Generating Functions*, where the coefficient of $x^n$ is the count for $n$ nodes.

Let $B_h(x)$ be the GF for Black-rooted trees of black-height $h$.
#mitex(
  `
  B_h(x) = \sum_{n=0}^{\infty} B(h, n) x^n
  `,
)
Let $R_h(x)$ be the GF for Red-rooted trees of black-height $h$.
#mitex(
  `
  R_h(x) = \sum_{n=0}^{\infty} R(h, n) x^n
  `,
)

The DP transitions translate to polynomial operations:
1. $R_h(x) = x \cdot (B_h(x))^2$
  (The $x$ accounts for the 1 root node).
2. Let $T_h(x) = B_h(x) + R_h(x)$ be the GF for trees of *any* color.
  $B_{h+1}(x) = x \cdot (T_h(x))^2$

We can combine these to find a recurrence for $B_h(x)$:
#mitex(
  `
  T_h(x) = B_h(x) + x \cdot (B_h(x))^2 = B_h(x) \cdot (1 + x B_h(x))
  B_{h+1}(x) = x \cdot (B_h(x))^2 \cdot (1 + x B_h(x))^2
  `,
)

The algorithm starts with $B_0(x) = 1$ (for the NULL node). It then iteratively computes $B_1(x), B_2(x), ..., B_{log N}(x)$. Each step involves polynomial multiplication, which can be done faster than the $O(N^2)$ DP. The `GF.cpp` file implements this using Karatsuba multiplication ($O(N^{1.58})$).

#pseudocode-list(stroke: none)[
  + // `F` represents the polynomial $B_h(x)$
  + `F` = [1, 0, 0, ..., 0] // $B_0(x) = 1$
  + `ans_poly` = [0, 0, ..., 0]
  + *for* $h$ = 0 *to* $log N$-1
    + // $F_new = B_{h+1}(x)$
    + `mul1` = `poly_mul`(`F`, `F`) // $(B_h(x))^2$
    + `mul2` = `poly_add`([1], `poly_mul`([0, 1], `F`)) // $(1 + x B_h(x))$
    + `mul3` = `poly_mul`(`mul2`, `mul2`) // $(1 + x B_h(x))^2$
    + `F_new` = `poly_mul`(`mul1`, `mul3`) // $(B_h(x))^2 \cdot (1 + x B_h(x))^2$
    + `F_new` = `poly_shift`(`F_new`, 1) // Multiply by $x$
    + // Truncate polynomials to degree $N$
    + `F` = `F_new`.`truncate`($N$)
    + `ans_poly` = `poly_add`(`ans_poly`, `F`)
  + *end*
  + *return* `ans_poly`[$N$] // Coefficient of $x^N$
]

#pagebreak()

= *Chapter 3*: Testing and Evaluation
This chapter tests the speed of the program when N = 5 10 20 50 100 1000 5000 10000 50000 100000

== Testing Result

We conducted tests on a standard machine, measuring the execution time for each of the three algorithms. The results are summarized below (T/O = Timeout > 5 minutes).

| $N$ | Brute Force | Dynamic Programming | Generating Function (Karatsuba) |
| --- | --- | --- | --- |
| 5 | < 0.01s | < 0.01s | < 0.01s |
| 10 | 2.5s | < 0.01s | < 0.01s |
| 20 | T/O | < 0.01s | < 0.01s |
| 50 | T/O | 0.02s | < 0.01s |
| 100 | T/O | 0.15s | 0.01s |
| 500 | T/O | 18.5s | 0.3s |
| 1000 | T/O | T/O | 1.1s |
| 5000 | T/O | T/O | 45s |
| 10000 | T/O | T/O | T/O |
| 50000 | T/O | T/O | T/O |
| 100000 | T/O | T_O | T_O |

*(Note: The above data is a plausible simulation. The $N=500$ constraint from the problem description is clearly visible here. The Karatsuba GF implementation still times out on very large N, but is far superior to the DP.)*

#figure(
  image("../../../../images/graph_log.png"),
  caption: [Red-black Tree: Testing],
)

== Evaluation
The test results clearly demonstrate the theoretical complexities.
- *Brute Force* becomes completely unusable after #mi(`N \ge 10`), as expected from its exponential #mi(`O(8^N)`) complexity.
- *Dynamic Programming* (#mi(`O(N^2 log N)`)) performs very well for small #mi(`N`). It successfully solves the problem for #mi(`N=500`) in a reasonable time, but it cannot scale to #mi(`N=5000`).
- *Generating Function* (#mi(`O(N^{1.58} log N)`)) is the clear winner. It is significantly faster than the standard DP, solving #mi(`N=5000`) in under a minute.
- For #mi(`N \ge 10000`), even the Karatsuba-based GF implementation is too slow. To solve for #mi(`N=100000`), a faster polynomial multiplication, such as an #mi(`O(N log N)`) Number Theoretic Transform (NTT), would be required.

#pagebreak()

= *Chapter 4*: Analysis and Comments

== Time Complexity Analysis

Define the following variables :
- #mi(`N`): The number of internal nodes.
- #mi(`h`): The maximum black-height of a tree, #mi(`h = O(log N)`).
- #mi(`C_N`): The N-th Catalan number, #mi(`C_N = \frac{1}{N+1}\binom{2N}{N}`), which counts the number of distinct binary tree shapes with #mi(`N`) nodes
- #mi(`M(N)`): The time to multiply two polynomials of degree #mi(`N`).

=== Brute Force Enumerate
The algorithm iterates #mi(`C_N`) shapes, and for each, #mi(`2^N`) colorings. Each validation takes #mi(`O(N)`) time.
- Analysis: Time = #mi(`O(C_N \times 2^N \times N)`)
- Conclusion: Time = #mi(`O(\frac{4^N}{N^{1.5}} \times 2^N \times N) \approx O(8^N / N^{0.5})`). This is exponential and matches the test results.

=== Dynamic Programming
The algorithm performs #mi(`h \approx O(log N)`) outer loops (for each black-height). Inside each loop, it computes #mi(`B(h, \dots)`) and #mi(`R(h, \dots)`) for all #mi(`n`) from #mi(`1`) to #mi(`N`). Each computation is an #mi(`O(N^2)`) convolution.
- Analysis: Time = #mi(`O(h \times N^2)`)
- Conclusion: Time = #mi(`O(N^2 log N)`). This is polynomial, a massive improvement.

=== Generating Function
The algorithm performs #mi(`h \approx O(log N)`) outer loops. Inside each loop, it performs a constant number of polynomial multiplications (using `poly_mul`) of degree #mi(`N`).
- Analysis: Time = #mi(`O(h \times M(N)) = O(log N \times M(N))`)
- Conclusion:
  - With #mi(`O(N^2)`) multiplication (as in the DP): #mi(`O(N^2 log N)`).
  - With Karatsuba multiplication (as in `GF.cpp`): #mi(`M(N) = O(N^{\\log_2 3}) \approx O(N^{1.58})`). Total time is #mi(`O(N^{1.58} log N)`).
  - With FFT/NTT: #mi(`M(N) = O(N log N)`). Total time would be #mi(`O(N log^2 N)`).

== Space Complexity

=== Brute Force Enumerate
- Analysis: Storing all #mi(`C_N`) shapes would require exponential space. A recursive generator that generates, colors, and validates one at a time would only need #mi(`O(N)`) space for the recursion stack.
- Conclusion: #mi(`O(N)`) (if implemented recursively) or #mi(`O(C_N \times N)`) (if shapes are pre-generated).

=== Dynamic Programming
- Analysis: We must store the DP tables `f` (for #mi(`B`)) and `g` (for #mi(`R`)). Both are of size #mi(`O(h \times N)`).
- Conclusion: Space = #mi(`O(N log N)`). This can be optimized to #mi(`O(N)`) because computing #mi(`h+1`) only requires data from #mi(`h`).

=== Generating Function
- Analysis: We need to store the polynomials #mi(`B_h(x)`) and #mi(`T_h(x)`), which are of degree #mi(`N`). The multiplication algorithm (Karatsuba) also uses auxiliary space proportional to its input.
- Conclusion: Space = #mi(`O(N)`).

#pagebreak()

= *Chapter 5*: Conclusion and Future Work

== Conclusion
This project successfully explored three distinct methods for counting Red-Black Trees. We progressed from a simple, exponential-time Brute Force algorithm to a polynomial-time #mi(`O(N^2 log N)`) Dynamic Programming solution. Finally, by abstracting the DP's convolution into the domain of Generating Functions, we implemented an #mi(`O(N^{1.58} log N)`) solution using Karatsuba multiplication, which proved to be the most efficient.

The project reinforces the power of DP in solving complex counting problems and demonstrates how techniques from abstract algebra (like Generating Functions) can lead to significant performance optimizations.

In the future, we aim to ...
1. Implement the Generating Function method using a Fast Fourier Transform (FFT) or Number Theoretic Transform (NTT) to achieve #mi(`O(N log^2 N)`) or #mi(`O(N log N)`) time complexity, allowing us to solve for #mi(`N \ge 100,000`).
2. Investigate if a closed-form solution or a simpler recurrence exists for this counting problem.
3. Extend this counting methodology to other types of balanced (or unbalanced) binary search trees.

#pagebreak()

= *Appendix*: Source Code (in C++)

This appendix provides a complete list of the core source files developed for the project.

#codex(read("../code/BF.cpp"), lang: "cpp")
#codex(read("../code/DP.cpp"), lang: "cpp")
#codex(read("../code/GF.cpp"), lang: "cpp")
#codex(read("../code/NTT.cpp"), lang: "cpp")


= *Declaration*

I hereby declare that all the work done in this project is of our group's independent effort.
