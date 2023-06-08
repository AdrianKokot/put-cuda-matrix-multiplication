#include <iostream>
#include <fstream>
#include <vector>
#include <chrono>
#include <iomanip>

void matrixMultiplicationCPU(const int *A, const int *B, int *C, const int rowsA, const int colsA, const int rowsB, const int colsB)
{
  for (int rowA = 0; rowA < rowsA; rowA++)
  {
    for (int colB = 0; colB < colsB; colB++)
    {
      int sum = 0;
      for (int i = 0; i < colsA; i++)
      {
        sum += A[rowA * colsA + i] * B[i * colsB + colB];
      }
      C[rowA * colsB + colB] = sum;
    }
  }
}

__global__ void matrixMultiplicationGPU(int *A, int *B, int *C, int rowsA, int colsA, int colsB)
{
  int tid = threadIdx.x + blockIdx.x * blockDim.x;
  int rowA = tid / colsB;
  int colB = tid % colsB;

  if (rowA < rowsA && colB < colsB)
  {
    int sum = 0;
    for (int i = 0; i < colsA; i++)
    {
      sum += A[rowA * colsA + i] * B[i * colsB + colB];
    }
    C[rowA * colsB + colB] = sum;
  }
}

int main(int argc, char *argv[])
{
  if (argc < 2)
  {
    std::cout << "Podaj sciezke do pliku jako parametr wywolania programu." << std::endl;
    return 1;
  }

  std::cout << "| " << std::setw(20) << "Size"
            << " | " << std::setw(15) << "CPU"
            << " | " << std::setw(15) << "GPU"
            << " | " << std::setw(15) << "Speedup"
            << " |" << std::endl;
  std::cout << "| -------------------- | --------------- | --------------- | --------------- |" << std::endl;

  for (int fileNum = 1; fileNum < argc; fileNum++)
  {

    std::string filename = argv[fileNum];

    std::ifstream file(filename);
    if (!file.is_open())
    {
      std::cout << "Nie udalo sie otworzyc pliku." << std::endl;
      return 1;
    }

    int rowsA, colsA, rowsB, colsB;
    file >> rowsA >> colsA;
    int *matrixA = new int[rowsA * colsA];
    for (int i = 0; i < rowsA * colsA; i++)
    {
      file >> matrixA[i];
    }

    file >> rowsB >> colsB;
    int *matrixB = new int[rowsB * colsB];
    for (int i = 0; i < rowsB * colsB; i++)
    {
      file >> matrixB[i];
    }

    if (colsA != rowsB)
    {
      std::cout << "Niepoprawne rozmiary macierzy. Nie mozna wykonac mnozenia." << std::endl;
      std::cout << "ColsA: " << colsA << " RowsA: " << rowsA << " ColsB: " << colsB << " RowsA: " << rowsA << std::endl;

      return 1;
    }

    int *d_A;
    int *d_B;
    int *d_C;
    int sizeA = rowsA * colsA * sizeof(int);
    int sizeB = rowsB * colsB * sizeof(int);
    int sizeC = rowsA * colsB * sizeof(int);

    // CUDA
    auto start_GPU = std::chrono::steady_clock::now();

    cudaMalloc((void **)&d_A, sizeA);
    cudaMalloc((void **)&d_B, sizeB);
    cudaMalloc((void **)&d_C, sizeC);

    cudaMemcpy(d_A, matrixA, sizeA, cudaMemcpyHostToDevice);
    cudaMemcpy(d_B, matrixB, sizeB, cudaMemcpyHostToDevice);

    int threadsPerBlock = 256;
    int blocksPerGrid = (rowsA * colsB + threadsPerBlock - 1) / threadsPerBlock;

    matrixMultiplicationGPU<<<blocksPerGrid, threadsPerBlock>>>(d_A, d_B, d_C, rowsA, colsA, colsB);

    int *matrixC_GPU = new int[rowsA * colsB];
    cudaMemcpy(matrixC_GPU, d_C, sizeC, cudaMemcpyDeviceToHost);

    cudaDeviceSynchronize();

    cudaFree(d_A);
    cudaFree(d_B);
    cudaFree(d_C);

    auto end_GPU = std::chrono::steady_clock::now();
    auto executionTime_GPU = std::chrono::duration_cast<std::chrono::nanoseconds>(end_GPU - start_GPU).count() / 1000000000.0;

    // CPU

    auto start_CPU = std::chrono::steady_clock::now();
    int *matrixC_CPU = new int[rowsA * colsB];
    matrixMultiplicationCPU(matrixA, matrixB, matrixC_CPU, rowsA, colsA, rowsB, colsB);
    auto end_CPU = std::chrono::steady_clock::now();
    auto executionTime_CPU = std::chrono::duration_cast<std::chrono::nanoseconds>(end_CPU - start_CPU).count() / 1000000000.0;

    for (int i = 0; i < rowsA * colsB; i++)
    {
      if (matrixC_CPU[i] != matrixC_GPU[i])
      {
        std::cout << "Wynik mnożenia na CPU i GPU różni się" << std::endl;
        break;
      }
    }

    std::cout << "| " << std::setw(20) << std::to_string(rowsA) + "x" + std::to_string(colsB) << " | " << std::setw(15) << std::fixed << std::setprecision(7) << executionTime_CPU << " | " << std::setw(15) << std::fixed << std::setprecision(7) << executionTime_GPU << " | " << std::setw(15) << std::fixed << std::setprecision(7) << executionTime_CPU / executionTime_GPU << " |" << std::endl;

    delete[] matrixC_CPU;
    delete[] matrixC_GPU;
    delete[] matrixA;
    delete[] matrixB;
  }

  return 0;
}