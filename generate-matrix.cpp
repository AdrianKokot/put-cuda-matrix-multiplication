#include <iostream>
#include <vector>
#include <random>

using namespace std;

random_device rd;
mt19937 gen(rd());
uniform_int_distribution<int> dis(1, 9);

vector<vector<int>> generate_matrix(int rows, int cols)
{
  vector<vector<int>> matrix(rows, vector<int>(cols));

  for (int i = 0; i < rows; i++)
  {
    for (int j = 0; j < cols; j++)
    {
      matrix[i][j] = dis(gen);
    }
  }

  return matrix;
}

void output_matrix(const vector<vector<int>> &matrix)
{
  int rows = matrix.size();
  int cols = matrix[0].size();

  cout << rows << " " << cols << endl;
  for (const auto &row : matrix)
  {
    for (int element : row)
    {
      cout << element << " ";
    }
    cout << endl;
  }
}

int main(int argc, char *argv[])
{
  if (argc < 3)
  {
    cout << "Usage: " << argv[0] << " <rows> <cols> (<rows2> <cols2>)" << endl;
  }

  int r1 = atoi(argv[1]), c1 = atoi(argv[2]);
  int r2 = argc > 3 ? atoi(argv[3]) : r1, c2 = argc > 3 ? atoi(argv[4]) : c1;

  output_matrix(generate_matrix(r1, c1));
  output_matrix(generate_matrix(r2, c2));

  return 0;
}
