#include <iostream>
#include <vector>
#include <algorithm>
#include <cassert>
#include <cmath>
using namespace std;
// Use 128-bit integers for CRT calculations to prevent overflow
using ll = __int128;

// The final modulo required by the problem
const int MOD = 1e9 + 7;

// --- NTT and CRT setup ---
// MOD (1e9+7) is not an NTT-friendly prime.
// We must use 3 other NTT-friendly primes and combine the results using the Chinese Remainder Theorem (CRT).
// These primes P are chosen such that (P-1) is a multiple of a large power of 2.
const int MOD1 = 998244353; // (P-1) = 119 * 2^23
const int MOD2 = 1004535809; // (P-1) = 479 * 2^21
const int MOD3 = 1012924417; // (P-1) = 483 * 2^21
// Primitive roots (g) for the respective moduli
const int G1 = 3;
const int G2 = 3;
const int G3 = 5;

/**
 *  Extended Euclidean Algorithm.
 * Finds x, y such that a*x + b*y = gcd(a, b).
 *  gcd(a, b).
 */
ll exgcd(ll a, ll b, ll &x, ll &y) {
    if (b == 0) {
        x = 1, y = 0;
        return a;
    }
    ll g = exgcd(b, a % b, y, x);
    y -= (a / b) * x;
    return g;
}

/** Calculates the modular multiplicative inverse of a (mod m).
 * Finds x such that a*x \equiv 1 (mod m).
 */
ll modinv(ll a, ll m) {
    ll x, y;
    ll g = exgcd(a, m, x, y);
    // Ensure the result is positive
    return (x % m + m) % m;
}

/**
 *  Bit-reversal permutation.
 * Reorders the elements of 'a' into the order required by iterative NTT.
 */
void bit_rev(vector<int> &a, int n) {
    vector<int> rev(n);
    for (int i = 0; i < n; ++ i) {
        rev[i] = rev[i >> 1] >> 1;
        if (i & 1) rev[i] |= n >> 1;
    }
    for (int i = 0; i < n; ++ i) if (i < rev[i]) swap(a[i], a[rev[i]]);
}

/**
 *  Modular exponentiation (Quick Power).
 * Calculates (x^y) % mod.
 */
ll qpow(ll x, ll y, ll mod) {
    ll re = 1;
    for (; y; y >>= 1, x = x * x % mod) if(y & 1) re = re * x % mod;
    return re;
}

/**
 *  Number Theoretic Transform (NTT) main function.
 *  a The polynomial (vector of coefficients) to transform.
 *  mod The NTT-friendly modulus to use.
 *  g The primitive root for that modulus.
 *  inv 0 for forward transform, 1 for inverse transform.
 */
void ntt(vector<int> &a, int mod, int g, int inv) {
    int n = a.size();
    bit_rev(a, n); // Reorder for iterative butterfly operations
    
    // Iterative butterfly loops
    for (int len = 2; len <= n; len <<= 1) { // len = current subarray size
        // Precalculate the root of unity for this length
        int exp = (mod - 1) / len;
        int wlen = qpow(g, exp, mod);
        if (inv) wlen = modinv(wlen, mod); // Use inverse root for inverse NTT
        
        for (int i = 0; i < n; i += len) { // Iterate over all subarrays
            int w = 1; // w = current power of the root of unity
            for (int j = 0; j < len / 2; ++ j) {
                // Butterfly operation
                int u = a[i + j];
                int v = (ll)a[i + j + len / 2] * w % mod;
                a[i + j] = (u + v) % mod;
                a[i + j + len / 2] = (u - v + mod) % mod; // (u - v) can be negative
                w = (ll)w * wlen % mod; // Next power of root
            }
        }
    }
    
    // Scale by 1/n for inverse transform
    if (inv) {
        ll inv_n = modinv(n, mod);
        for (int &x : a) x = (ll)x * inv_n % mod;
    }
}

/**
 *  Polynomial multiplication under a single NTT-friendly modulus.
 * Calculates (a * b) % mod.
 */
vector<int> poly_mult_mod(const vector<int> &a, const vector<int> &b, int mod, int g) {
    vector<int> fa(a.begin(), a.end()), fb(b.begin(), b.end());
    int n = 1;
    int len = a.size() + b.size() - 1; // Resulting polynomial degree
    
    // Pad vectors to the next power of 2
    while (n < len) n <<= 1;
    fa.resize(n, 0);
    fb.resize(n, 0);
    
    // 1. Forward NTT (Coefficient -> Point-value form)
    ntt(fa, mod, g, 0);
    ntt(fb, mod, g, 0);
    
    // 2. Point-wise multiplication (O(N))
    vector<int> fc(n);
    for (int i = 0; i < n; ++i) fc[i] = (ll)fa[i] * fb[i] % mod;
    
    // 3. Inverse NTT (Point-value -> Coefficient form)
    ntt(fc, mod, g, 1);
    
    // 4. Resize to the actual degree
    fc.resize(len);
    return fc;
}

/**
 *  Solves a system of 2 congruences using CRT.
 * Finds x such that:
 * x \equiv a1 (mod m1)
 * x \equiv a2 (mod m2)
 * return {x, lcm(m1, m2)}
 */
pair<ll, ll> crt2(ll a1, ll m1, ll a2, ll m2) {
    ll x, y;
    ll g = exgcd(m1, m2, x, y); // x*m1 + y*m2 = g
    
    ll lcm = (ll)m1 / g * m2;
    // Calculate the result based on the formula derived from exgcd
    x = (x * ((a2 - a1) / g)) % (m2 / g);
    x = (x + (m2 / g)) % (m2 / g); // Ensure positive
    ll res = (a1 + x * m1) % lcm;
    return {res, lcm};
}

/**
 * Solves a system of 3 congruences using CRT.
 * Finds x such that:
 * x \equiv a1 (mod MOD1)
 * x \equiv a2 (mod MOD2)
 * x \equiv a3 (mod MOD3)
 * return The final result x % MOD (our target modulo).
 */
ll crt3(ll a1, ll a2, ll a3) {
    // 1. Solve for (a1, MOD1) and (a2, MOD2) first
    auto [x1, m1] = crt2(a1, MOD1, a2, MOD2);
    // 2. Use that result to solve against (a3, MOD3)
    auto [x2, m2] = crt2(x1, m1, a3, MOD3);
    // 3. Return the final answer modulo the problem's MOD
    return x2 % MOD;
}

/**
 * Polynomial multiplication (A * B) % MOD.
 * Uses 3-Mod NTT + CRT to get the result.
 */
vector<int> poly_mult(const vector<int> &a, const vector<int> &b) {
    // 1. Calculate convolution under 3 different moduli
    vector<int> c1 = poly_mult_mod(a, b, MOD1, G1);
    vector<int> c2 = poly_mult_mod(a, b, MOD2, G2);
    vector<int> c3 = poly_mult_mod(a, b, MOD3, G3);
    
    int len = c1.size();
    vector<int> res(len);
    
    // 2. Combine results for each coefficient using CRT
    for (int i = 0; i < len; ++ i) res[i] = crt3(c1[i], c2[i], c3[i]);
    return res;
}

/**
 *Utility function to keep an integer within the [0, MOD-1] range.
 */
void reduce(int &x) {x = (x >= MOD ? x - MOD : x);}

/**
 *  Polynomial addition/subtraction: A = A + (B * x^shift) * mul.
 * A and B are polynomials represented as vectors.
 */
void add(vector<int> &A, vector<int> &B, int shift = 0, int mul = 1) {
    A.resize(max(A.size(), B.size() + shift));
    for (int i = 0; i < B.size(); ++ i) reduce(A[i + shift] += (mul == 1 ? B[i] : MOD - B[i]));
}

int main() {
    int n;
    cin >> n;
    
    // logn = max possible black-height, h = O(log N)
    int logn = log2(n) + 2;
    int ans = 0;

    // Find the smallest power of 2 >= n, for polynomial size
    int N = 1;
    while(N < n) N <<= 1;

    // F = Generating Function for Black-rooted trees of black-height h
    // F(x) = B_h(x) = sum(B(h, n) * x^n)
    vector<int> F(N, 0);
    // B_0(x) = 1 (representing a single NULL node at n=0, h=0)
    F[0] = 1;

    // Iterate through black-height h (from i=0 to logn-1)
    for (int i = 0; i < logn; ++ i) {
        // At the start of this loop, F = B_h(x) (where h = i)
        // We want to compute B_{h+1}(x)
        
        // The recurrence relation is:
        // B_{h+1}(x) = x * (B_h(x))^2 * (1 + x * B_h(x))^2

        vector<int> mul1, mul2, mul3;

        // 1. mul1 = (B_h(x))^2
        // This multiplication is O(N log N) thanks to NTT
        mul1 = poly_mult(F, F);

        // 2. mul2 = (1 + x * B_h(x))
        mul2.push_back(1); // Start with 1
        add(mul2, F, 1);   // Add F, shifted by 1 (which is x * F)

        // 3. mul3 = (1 + x * B_h(x))^2
        mul3 = poly_mult(mul2, mul2); // O(N log N)

        // Resize to N to keep polynomial sizes consistent
        mul1.resize(N);
        mul3.resize(N);

        // 4. F = (B_h(x))^2 * (1 + x * B_h(x))^2
        F = poly_mult(mul1, mul3); // O(N log N)
        
        // 5. F = x * [ (B_h(x))^2 * (1 + x * B_h(x))^2 ]
        // This is B_{h+1}(x)
        F.insert(F.begin(), 0); // Insert 0 at coeff 0, shifting all others right
        F.resize(N);            // Truncate back to size N

        // The answer is the sum of B(h, N) for all h > 0.
        // F[n] is the coefficient of x^n in B_{h+1}(x), which is B(h+1, N).
        // We add this to our total answer.
        reduce(ans += F[n]);
    }

    cout << ans << "\n";
}