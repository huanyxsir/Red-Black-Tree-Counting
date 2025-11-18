#include <iostream>
#include <vector>
#include <cmath>

using namespace std;

const int MOD = 1e9 + 7;

void reduce(int &x) {x = (x >= MOD ? x - MOD : x);} // x -= MOD

int main() {
    int n;
    cin >> n;

    int logn = log2(n) + 2;

    vector<vector<int> > f(logn, vector<int>(n + 10)), g(logn, vector<int>(n + 10)); 

    f[0][0] = 1;

    int ans = 0;

    for (int i = 0; i < logn - 1; ++ i) {
        for (int j = 1; j <= n; ++ j)
            for (int k = 0; k <= j - 1; ++ k)
                reduce(g[i][j] += 1ll * f[i][k] * f[i][j - 1 - k] % MOD); // g[i][j] = f[i][j] = sum_{k=0}^{j-1} f[i][k] * f[i][j-1-k]
        for (int j = 1; j <= n; ++ j)
            for (int k = 0; k <= j - 1; ++ k)
                reduce(f[i + 1][j] += 1ll * (f[i][k] + g[i][k]) * (f[i][j - 1 - k] + g[i][j - 1 - k]) % MOD);// f[i+1][j] = sum_{k=0}^{j-1} (f[i][k] + g[i][k]) * (f[i][j-1-k] + g[i][j-1-k])
        reduce(ans += f[i + 1][n]); // ans += f[i+1][n]
    }

    cout << ans << "\n";
}