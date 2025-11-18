#include <iostream>
#include <vector>
#include <assert.h>

using namespace std;

// The problem's modulo
const int MOD = 1e9 + 7;

void reduce(int &x) {x = (x >= MOD ? x - MOD : x);}

void add(vector<int> &A, vector<int> &B, int shift = 0, int mul = 1) { 
    // Ensure A is large enough to hold the result
    A.resize(max(A.size(), B.size() + shift));
    for (int i = 0; i < B.size(); ++ i) {
        // Add or subtract (using MOD - B[i] for subtraction) the coefficient
        reduce(A[i + shift] += (mul == 1 ? B[i] : MOD - B[i]));
    }
}

vector<int> mul(vector<int> &A, vector<int> &B) {
    // The result will have degree (A.size - 1) + (B.size - 1)
    vector<int> re(A.size() + B.size() - 1);

    // Base Case: For small polynomials, use O(N^2) naive multiplication.
    // This is a crucial optimization for divide-and-conquer.
    if(A.size() <= 32) {
        for (int i = 0; i < A.size(); ++ i)
            for (int j = 0; j < B.size(); ++ j)
                reduce(re[i + j] += 1ll * A[i] * B[j] % MOD);
        return re;
    }

    // Karatsuba Recursive Step:
    // A(x) = AL(x) + AR(x) * x^(n/2)
    // B(x) = BL(x) + BR(x) * x^(n/2)
    // A*B = (AL*BL) + [(AL+AR)*(BL+BR) - (AL*BL) - (AR*BR)] * x^(n/2) + (AR*BR) * x^n
    
    // Split A into low-degree (AL) and high-degree (AR) parts
    vector<int> AL, AR, BL, BR, mulL, mulR, mulminus;
    int midA = A.size() >> 1; // A.size() / 2
    int midB = B.size() >> 1; // B.size() / 2

    for (int i = 0; i < midA; ++ i) AL.push_back(A[i]);
    for (int i = midA; i < A.size(); ++ i) AR.push_back(A[i]);
    for (int i = 0; i < midB; ++ i) BL.push_back(B[i]);
    for (int i = midB; i < B.size(); ++ i) BR.push_back(B[i]);

    // 1. Calculate (AL * BL)
    mulL = mul(AL, BL);
    // 2. Calculate (AR * BR)
    mulR = mul(AR, BR);

    // 3. Add (AL*BL) to the result (at x^0)
    add(re, mulL);
    // 4. Add (AR*BR) to the result (at x^(midA+midB))
    add(re, mulR, midA + midB);

    // 5. Calculate (AL + AR) and (BL + BR)
    // We re-use AR and BL vectors to save memory
    // AR = (AL + AR)
    // BL = (BL + BR)
    add(AR, AL, 0, 1); // Note: mul is 1, so this is addition
    add(BL, BR, 0, 1); // Note: mul is 1, so this is addition

    // 6. Calculate (AL+AR)*(BL+BR)
    mulminus = mul(AR, BL);

    // 7. Calculate (AL+AR)*(BL+BR) - (AL*BL) - (AR*BR)
    add(mulminus, mulL, 0, -1); // Subtract mulL
    add(mulminus, mulR, 0, -1); // Subtract mulR

    // 8. Add the middle term to the result (at x^(midA))
    // Note: The problem uses midA, which is correct if A.size() == B.size().
    // For different sizes, midA is used as the shift.
    add(re, mulminus, midA);

    return re;
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
    // We start with B_0(x)
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
        mul1 = mul(F, F);

        // 2. mul2 = (1 + x * B_h(x))
        mul2.push_back(1); // Start with 1
        add(mul2, F, 1);   // Add F, shifted by 1 (which is x * F)

        // 3. mul3 = (1 + x * B_h(x))^2
        mul3 = mul(mul2, mul2);

        // Resize to N to keep polynomial sizes consistent
        mul1.resize(N);
        mul3.resize(N);

        // 4. F = (B_h(x))^2 * (1 + x * B_h(x))^2
        F = mul(mul1, mul3);
        
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