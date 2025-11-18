#include <iostream>
#include <vector>
#include <cmath>
#include <string>

using namespace std;
const int MOD = 1000000007;

enum Color { RED, BLACK };
struct Node {
    Color color;
    Node *left;
    Node *right;
    Node(Node* l = nullptr, Node* r = nullptr) : color(RED), left(l), right(r) {}
};

bool check_prop4(Node* node) {
    if (node == nullptr) {
        return true; // NULL node is black, satisfied
    }
    if (node->color == RED) {
        // Check left child
        if (node->left != nullptr && node->left->color == RED) {
            return false;
        }
        // Check right child
        if (node->right != nullptr && node->right->color == RED) {
            return false;
        }
    }
    // Recursively check subtrees
    return check_prop4(node->left) && check_prop4(node->right);
}

/**
 * Validate Property 5: All paths must have the same black-height
 * Returns:
 * - 0:  if node is NULL
 * - -1: if this subtree violates property 5
 * - h:  if this subtree is valid, its black-height is h
 */
int get_black_height(Node* node) {
    if (node == nullptr) {
        return 0; // Black-height of a NULL leaf is 0
    }
    int left_bh = get_black_height(node->left);
    int right_bh = get_black_height(node->right);

    // Check 1: Is the subtree already invalid?
    if (left_bh == -1 || right_bh == -1) {
        return -1;
    }
    // Check 2: Are the black-heights of left and right subtrees equal?
    if (left_bh != right_bh) {
        return -1;
    }
    // Calculate and return the black-height of the current node
    int my_bh = left_bh + (node->color == BLACK ? 1 : 0);
    return my_bh;
}

/**
 * Validate if a colored tree is a legal Red-Black Tree
 */
bool isValidRBTree(Node* root) {
    if (root == nullptr) {
        return true; // An empty tree is valid (although N >= 1 here)
    }
    // 1. Validate Property 2: Root must be black
    if (root->color == RED) {
        return false;
    }
    // 2. Validate Property 4: Children of a red node must be black
    if (!check_prop4(root)) {
        return false;
    }
    // 3. Validate Property 5: All paths must have the same black-height
    if (get_black_height(root) == -1) {
        return false;
    }
    // Property 1 (Red or Black) and Property 3 (NULL is black) are implicitly satisfied
    return true;
}

// -----------------------------------------------------------------
// Stage 1: Generate all possible tree shapes
// -----------------------------------------------------------------

/**
 * Recursively generate all *shapes* of binary trees with n internal nodes (without color)
 * Returns a vector containing the root nodes of all shapes
 */
vector<Node*> generate_shapes(int n) {
    vector<Node*> shapes_list;
    if (n == 0) {
        // Base case: 0 nodes, only NULL
        shapes_list.push_back(nullptr);
        return shapes_list;
    }
    // Recursive case: 1 root + k left subtree nodes + (n-1-k) right subtree nodes
    for (int k = 0; k < n; ++k) {
        vector<Node*> left_shapes = generate_shapes(k);
        vector<Node*> right_shapes = generate_shapes(n - 1 - k);
        // Combine all possible left and right subtrees
        for (Node* l_shape : left_shapes) {
            for (Node* r_shape : right_shapes) {
                Node* new_root = new Node(l_shape, r_shape);
                shapes_list.push_back(new_root);
            }
        }
    }
    return shapes_list;
}

// -----------------------------------------------------------------
// Stage 2: Apply coloring schemes
// -----------------------------------------------------------------

/**
 * Helper function: Collect all N nodes of a tree (in-order traversal)
 */
void get_nodes_in_order(Node* node, vector<Node*>& nodes) {
    if (node == nullptr) {
        return;
    }
    get_nodes_in_order(node->left, nodes);
    nodes.push_back(node);
    get_nodes_in_order(node->right, nodes);
}

/**
 * Helper function: Clean up (delete) a tree
 */
void delete_tree(Node* node) {
    if (node == nullptr) {
        return;
    }
    delete_tree(node->left);
    delete_tree(node->right);
    delete node;
}

int main() {
    int n;
    cin >> n;

    if (n == 0) {
        cout << 1 << endl; // Only NULL tree
        return 0;
    }
    
    // Stage 1: Generate all N-node tree shapes
    vector<Node*> all_shapes = generate_shapes(n);

    long long total_valid_trees = 0;

    // Iterate over each shape
    for (Node* shape : all_shapes) {
        
        // Helper: Get all N nodes of this shape
        vector<Node*> nodes_in_order;
        get_nodes_in_order(shape, nodes_in_order);

        // Stage 2: Iterate over all 2^N coloring schemes
        // (i is an N-bit bitmask, 0=RED, 1=BLACK)
        long long num_colorings = (1LL << n);
        
        for (long long i = 0; i < num_colorings; ++i) {
            
            // Apply the i-th coloring scheme
            for (int j = 0; j < n; ++j) {
                if ((i >> j) & 1) {
                    nodes_in_order[j]->color = BLACK;
                } else {
                    nodes_in_order[j]->color = RED;
                }
            }

            // Stage 3: Validate
            if (isValidRBTree(shape)) {
                total_valid_trees = (total_valid_trees + 1) % MOD;
            }
        }
    }

    cout << total_valid_trees << endl;

    // Clean up memory (very important, or memory will leak)
    for (Node* shape : all_shapes) {
        delete_tree(shape);
    }
    return 0;
}