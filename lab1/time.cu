#include <iostream>
#include <iomanip>
#include <stdio.h>
#include <stdlib.h>
#include <ctime>

void checkCudaError(const char* msg)
{
    cudaError_t err = cudaGetLastError();
    if (cudaSuccess != err)
    {
        fprintf(stderr, "ERROR: %s: %s.\n", msg, cudaGetErrorString(err));
        exit(0);
    }
}

void CustomReverse(float* vec, int size) {
    float* res = new float[size];
    for (int i = 0; i < size; ++i) {
        res[i] = vec[size - i - 1];
    }
}

__global__ void Reverse(float* res, float* vec, int size)
{
    int idx = blockDim.x * blockIdx.x + threadIdx.x;
    int offset = gridDim.x * blockDim.x;

    while (idx < size)
    {
	    res[idx] = vec[size - idx - 1];
	    idx += offset;
    }
}


int main(int argc, const char* argv[])
{
    int size;
    std::cin >> size;
    
    const int MAX = 33554432;
    const int MIN = 0;
    if (size < MIN && size > MAX)
    {
       std::cerr << "ERROR: Incorrect size!\n";
       exit(0);
    }

    float *hostVec = new float[size];

    for (int i = 0; i < size; ++i)
    {
        hostVec[i] = i;
    }
    std::cout << "vector size = " << size << std::endl;

    clock_t time;
    time = clock();
    
    CustomReverse(hostVec, size);
    time = clock() - time;
    std::cout << "CPU" << std::endl;
    std::cout << "time = " << (double)time/CLOCKS_PER_SEC << std::endl;


    float *deviceVec, *deviceRes;

    // Выделяем память для device копий
    cudaMalloc((void**) &deviceVec, sizeof(float) * size);
    cudaMalloc((void**) &deviceRes, sizeof(float) * size);
    // Копируем ввод на device
    cudaMemcpy(deviceVec, hostVec, sizeof(float) * size, cudaMemcpyHostToDevice);
     
    
	int blockCount = 32;
    int threadsCount = 32;   
    


    cudaEvent_t start, end;
    cudaEventCreate(&start);
    checkCudaError("cudaEventCreate");
    cudaEventCreate(&end);
    checkCudaError("cudaEventCreate");
    cudaEventRecord(start);
    checkCudaError("cudaEventRecord");


    // Запускаем kernel
    Reverse<<<blockCount, threadsCount>>>(deviceRes, deviceVec, size);
    checkCudaError("Kernel invocation");
    
    cudaEventRecord(end);
    checkCudaError("cudaEventRecord");
    cudaEventSynchronize(end);
    checkCudaError("cudaEventSynchronize");
    float t;
    cudaEventElapsedTime(&t, start, end);
    checkCudaError("cudaEventElapsedTime");
    cudaEventDestroy(start);
    checkCudaError("cudaEventDestroy");
    cudaEventDestroy(end);
    checkCudaError("cudaEventDestroy");
    printf("GPU\n");
    printf("time = %f\n", t);
    printf("blocks = %d\n", blockCount);
    printf("threads = %d\n", threadsCount);
    cudaMemcpy(hostVec, deviceRes, sizeof(float) * size, cudaMemcpyDeviceToHost);
    checkCudaError("Memcpy");

    //const int accuracy = 10;
    //for (int i = 0; i < size - 1; ++i)
    //{
        //std::cout << std::scientific << std::setprecision(accuracy) << hostVec[i] << " ";
    //}
    //std::cout << std::scientific << std::setprecision(accuracy) << hostVec[size - 1];
    
    cudaFree(deviceVec);
    checkCudaError("Free");
    
    cudaFree(deviceRes);
    checkCudaError("Free");
    
    delete[] hostVec;

    return 0;
}