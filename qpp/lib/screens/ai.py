import math

class AI:
    def __init__(self):
        # 1. Properly assign instance variables with self
        self.features = 3
        self.action = 3
        self.alpha = 0.3
        
        # 2. Initialize Matrix A (3x3 Identity matrix for each action)
        self.A = []
        for i in range(self.action):
            action_table = []
            for j in range(self.features):
                row = []
                for k in range(self.features):
                    if j == k:
                        row.append(1.0)
                    else:
                        row.append(0.0)
                action_table.append(row)
            self.A.append(action_table)
            
        # 3. Initialize Matrix b (Vector of zeros for each action)
        self.b = []
        for i in range(self.action):
            self.b.append([0.0] * self.features)

    # ==========================================
    # MATH HELPER METHODS (Defined at class level)
    # ==========================================
    
    def dot_product(self, vec1, vec2):
        return sum(vec1[i] * vec2[i] for i in range(len(vec1)))
    
    def mat_vec_multiply(self, M, vec):
        """Multiplies 3x3 Matrix with 3x1 Vector"""
        return [sum(M[i][j] * vec[j] for j in range(len(vec))) for i in range(len(M))]
    
    def inverse(self, M):
        """Calculates 3x3 Determinant and Matrix Inverse analytically."""
        det = (
            M[0][0] * (M[1][1] * M[2][2] - M[1][2] * M[2][1]) -
            M[0][1] * (M[1][0] * M[2][2] - M[1][2] * M[2][0]) +
            M[0][2] * (M[1][0] * M[2][1] - M[1][1] * M[2][0])
        )
        if abs(det) < 1e-9:
            det = 1e-9  # Avoid division by zero
    
        invdet = 1.0 / det
        inv = [
            [(M[1][1] * M[2][2] - M[1][2] * M[2][1]) * invdet, (M[0][2] * M[2][1] - M[0][1] * M[2][2]) * invdet, (M[0][1] * M[1][2] - M[0][2] * M[1][1]) * invdet],
            [(M[1][2] * M[2][0] - M[1][0] * M[2][2]) * invdet, (M[0][0] * M[2][2] - M[0][2] * M[2][0]) * invdet, (M[0][2] * M[1][0] - M[0][0] * M[1][2]) * invdet],
            [(M[1][0] * M[2][1] - M[1][1] * M[2][0]) * invdet, (M[0][1] * M[2][0] - M[0][0] * M[2][1]) * invdet, (M[0][0] * M[1][1] - M[0][1] * M[1][0]) * invdet]
        ]
        return inv

    # ==========================================
    # LINUCB ACTION SELECTION
    # ==========================================
    
    def selectaction(self, acc, speed, hint):
        x = [acc, speed, hint]
        score = []
        
        for i in range(self.action):
            # Fetch specific action's Matrix A and Inverse it
            A_inv = self.inverse(self.A[i])
            
            # Step 1: Weights = A^-1 * b[i]
            weights = self.mat_vec_multiply(A_inv, self.b[i])
            
            # Step 2: Expected Rewards = weights * x
            expected_rewards = self.dot_product(weights, x)
            
            # Step 3: Uncertainty = alpha * sqrt(x^T * A^-1 * x)
            temp = self.mat_vec_multiply(A_inv, x)
            var_val = self.dot_product(x, temp)
            uncertainty = self.alpha * math.sqrt(max(0.0, var_val))
            
            # Step 4: Total UCB Score
            t_score = expected_rewards + uncertainty
            score.append(t_score)
        
        max_score = max(score)
        selected_action = score.index(max_score)
        return selected_action

                   


