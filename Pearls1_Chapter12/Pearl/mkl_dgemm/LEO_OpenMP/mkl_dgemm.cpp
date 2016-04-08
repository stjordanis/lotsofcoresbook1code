//////////////////////////////////////////////////////////////////////////////////
//
// Copyright (c) 2014, FLORIAN WENDE, ZIB
// All rights reserved.
// 
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
//     * Redistributions of source code must retain the above copyright
//       notice, this list of conditions and the following disclaimer.
//     * Redistributions in binary form must reproduce the above copyright
//       notice, this list of conditions and the following disclaimer in the
//       documentation and/or other materials provided with the distribution.
//     * Neither the name of the ZIB nor the
//       names of its contributors may be used to endorse or promote products
//       derived from this software without specific prior written permission.
// 
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
// ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
// WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
// DISCLAIMED. IN NO EVENT SHALL FLORIAN WENDE BE LIABLE FOR ANY
// DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
// (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
// LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
// ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
// SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
// 
//////////////////////////////////////////////////////////////////////////////////

#include <iostream>
#include <iomanip>
#include <cstdlib>
#include <cstdint>
#include <cmath>
#include <cstring>
#include <omp.h>
#include <immintrin.h>
#include <mkl.h>
#include <sched.h>

using namespace std;

#if !defined NUM_GROUPS
#define NUM_GROUPS ( 1 )
#endif

#if !defined GROUP_SIZE
#define GROUP_SIZE ( 16 )
#endif

#if !defined COPY_FRACTION_A
#define COPY_FRACTION_A ( 0.0 )
#endif

#if !defined COPY_FRACTION_B
#define COPY_FRACTION_B ( 0.0 )
#endif

#if !defined COPY_FRACTION_C
#define COPY_FRACTION_C ( 0.0 )
#endif

#if !defined MATRIX_SIZE
#define MATRIX_SIZE ( 2048L )
#endif

//#define PINNING
//#define FIX
//#define BATCH_OUTPUT
#define ITERATIONS ( 100 )
#define ALIGNMENT ( 64 ) // works for SSE, AVX, MIC
#define DEVICE ( 0 )

#define MIN( X, Y ) ( ( X ) < ( Y ) ? ( X ) : ( Y ) )
#define MAX( X, Y ) ( ( X ) > ( Y ) ? ( X ) : ( Y ) )
#define POW_3( X ) ( X*X*X )

void multiply_naive( const double *a, const double *b, double *c );
double get_time_stamp();

int main() {

  double
    start[NUM_GROUPS][ITERATIONS],
    stop[NUM_GROUPS][ITERATIONS],
    totalComputeTime;

#pragma omp parallel num_threads( NUM_GROUPS )
  {

    uint32_t
      groupId = omp_get_thread_num();

    // memory allocation: alignment!
    double
      *a = (double *) _mm_malloc( MATRIX_SIZE*MATRIX_SIZE*sizeof( double ), ALIGNMENT ),
      *b = (double *) _mm_malloc( MATRIX_SIZE*MATRIX_SIZE*sizeof( double ), ALIGNMENT ),
      *c = (double *) _mm_malloc( MATRIX_SIZE*MATRIX_SIZE*sizeof( double ), ALIGNMENT );
    
    // initialize matrix a and b using random numbers
#pragma omp critical ( INIT )
    {

      cout << "# init (group=" << groupId << ") ... ";

      srand48( 1 );
    
      for( uint32_t i=0; i<( MATRIX_SIZE*MATRIX_SIZE ); i++ )
	a[i] = drand48();
      
      for( uint32_t i=0; i<( MATRIX_SIZE*MATRIX_SIZE ); i++ )
	b[i] = drand48();

      cout << "done" << endl << flush;

    } // critical region: INIT
    
    memset( c, 0x0, MATRIX_SIZE*MATRIX_SIZE*sizeof( double ) );
   
#pragma omp barrier

    // init
    if( groupId == 0 )
      cout << "# start copying data to Xeon Phi (all groups) ... " << flush;

#if defined PINNING
#pragma offload target( mic : DEVICE )
    {

#pragma omp parallel num_threads( GROUP_SIZE )
      {
	uint32_t
	  threadId = omp_get_thread_num();
	cpu_set_t
	  cpuMask;
	
	CPU_ZERO( &cpuMask );
	CPU_SET( 1+groupId*GROUP_SIZE+threadId, &cpuMask );
	sched_setaffinity( 0, sizeof( cpu_set_t ), &cpuMask );
      }

    }
#endif // PINNING
    
#if defined FIX
#pragma omp critical ( CREATE_THREADS )
    {
#endif // FIX

#pragma offload target( mic : DEVICE ) \
  in( a : length( MATRIX_SIZE*MATRIX_SIZE ) align( ALIGNMENT ) alloc_if( true ) free_if( false ) ) \
  in( b : length( MATRIX_SIZE*MATRIX_SIZE ) align( ALIGNMENT ) alloc_if( true ) free_if( false ) ) \
  in( c : length( MATRIX_SIZE*MATRIX_SIZE ) align( ALIGNMENT ) alloc_if( true ) free_if( false ) )
      {
	mkl_set_num_threads( GROUP_SIZE );	
#if defined FIX
#pragma omp parallel num_threads( GROUP_SIZE )
	{
	  ; // just create MKL threads
	}
#endif // FIX
      }

#if defined FIX
    } // critical region: CREATE_THREADS
#endif // FIX
    
#pragma omp barrier

    if( groupId == 0 ) {

      cout << "done" << endl;
      cout << "# start computation ... " << flush;
      totalComputeTime = get_time_stamp();

    }

#pragma omp barrier

    // compute
    for( uint32_t i=0; i<ITERATIONS; i++ ) {
      
      start[groupId][i] = get_time_stamp();
#pragma offload target( mic : DEVICE ) \
  in( a : length( (uint32_t)( COPY_FRACTION_A*MATRIX_SIZE*MATRIX_SIZE ) ) alloc_if( false ) free_if( false ) ) \
  in( b : length( (uint32_t)( COPY_FRACTION_B*MATRIX_SIZE*MATRIX_SIZE ) ) alloc_if( false ) free_if( false ) ) \
  out( c : length( (uint32_t)( COPY_FRACTION_C*MATRIX_SIZE*MATRIX_SIZE ) ) alloc_if( false ) free_if( false ) )
      {
	cblas_dgemm( CblasRowMajor, CblasNoTrans, CblasNoTrans, MATRIX_SIZE, MATRIX_SIZE, MATRIX_SIZE, 1.0, a, MATRIX_SIZE, b, MATRIX_SIZE, 0.0, c, MATRIX_SIZE );
      }
      stop[groupId][i] = get_time_stamp();
    
    }

#pragma omp barrier

    if( groupId == 0 ) {

      cout << "done" << endl << flush;
      totalComputeTime = get_time_stamp()-totalComputeTime;

    }
   
    // finalize
#pragma offload target( mic : DEVICE ) \
  in( a : length( 0 ) alloc_if( false ) free_if( true ) ) \
  in( b : length( 0 ) alloc_if( false ) free_if( true ) ) \
  out( c : length( MATRIX_SIZE*MATRIX_SIZE ) alloc_if( false ) free_if( true ) )
    {
      ;
    }
    
#if !defined BATCH_OUTPUT
    // check results
    double
      *cTest = (double *) _mm_malloc( MATRIX_SIZE*MATRIX_SIZE*sizeof( double ), ALIGNMENT );
    memset( cTest, 0x0, MATRIX_SIZE*MATRIX_SIZE*sizeof( double ) );

    // compute on host using the naive matrix multiply kernel
    multiply_naive( a, b, cTest );
    
    // determine deviation
    double
      dev = 0.0;

    for( uint32_t i=0; i<( MATRIX_SIZE*MATRIX_SIZE ); i++ )
      dev += (double)fabs( c[i]-cTest[i] );

    _mm_free( cTest );
    cTest = NULL;

#pragma omp critical ( PRINT )
    {
      cout << "# deviation host vs. phi (group=" << groupId << ") : " << ::setprecision( 16 ) << ::scientific << dev << endl << flush;
    }
#endif // !BATCH_OUTPUT

    // release memory
    _mm_free( a );
    _mm_free( b );
    _mm_free( c );
    a = NULL;
    b = NULL;
    c = NULL;

  }

  // determine performance: naive
  cout << ::setprecision( 6 ) << ::fixed;
#if !defined BATCH_OUTPUT
  cout << "# time per matrix multiplication (naive): " << ( totalComputeTime/ITERATIONS )*1.0E3 << " ms" << endl;
  cout << "# performance (naive): " << 2.0*POW_3( MATRIX_SIZE )*NUM_GROUPS/( totalComputeTime/ITERATIONS )*1.0E-9 << " Gflops/s" << endl;
#endif

  // determine performance: more accurate
  double
    maxStartTime = start[0][0],
    minStopTime = stop[0][ITERATIONS-1];

  for( uint32_t i=1; i<NUM_GROUPS; i++ ) {

    maxStartTime = maxStartTime < start[i][0] ? start[i][0] : maxStartTime;
    minStopTime = minStopTime > stop[i][ITERATIONS-1] ? stop[i][ITERATIONS-1] : minStopTime;

  }

  uint64_t
    overlappingComputations = 0;

  for( uint32_t i=0; i<NUM_GROUPS; i++ )
    for( uint32_t j=0; j<ITERATIONS; j++ )
      if( start[i][j] >= maxStartTime && stop[i][j] <= minStopTime )
	overlappingComputations++;

#if defined BATCH_OUTPUT
  cout << NUM_GROUPS << "\t" << GROUP_SIZE << "\t" << 2.0*POW_3( MATRIX_SIZE )*overlappingComputations/( minStopTime-maxStartTime )*1.0E-9 << "\t" << 2.0*POW_3( MATRIX_SIZE )*NUM_GROUPS/( totalComputeTime/ITERATIONS )*1.0E-9 << endl;
#else // BATCH_OUTPUT
  cout << "# time per matrix multiplication: " << ( minStopTime-maxStartTime )*NUM_GROUPS/overlappingComputations*1.0E3 << " ms" << endl;
  cout << "# performance: " << 2.0*POW_3( MATRIX_SIZE )*overlappingComputations/( minStopTime-maxStartTime )*1.0E-9 << " Gflops/s" << endl;
#endif // !BATCH_OUTPUT

  exit( 0 );

}

// naive matrix multiplication: just for comparison of results!
void multiply_naive( const double *a, const double *b, double *c ) {

  __assume_aligned( a, ALIGNMENT );
  __assume_aligned( b, ALIGNMENT );
  __assume_aligned( c, ALIGNMENT );

#pragma omp parallel for num_threads( GROUP_SIZE )
  for( uint32_t i=0; i<MATRIX_SIZE; i++ ) {

    for( uint32_t j=0; j<MATRIX_SIZE; j++ )
      c[i*MATRIX_SIZE+j] = 0.0;

    for( uint32_t k=0; k<MATRIX_SIZE; k++ )
#pragma simd
      for( uint32_t j=0; j<MATRIX_SIZE; j++ )
	c[i*MATRIX_SIZE+j] += a[i*MATRIX_SIZE+k]*b[k*MATRIX_SIZE+j];
    
  }

}

// timer
double get_time_stamp() {

  timespec t;
  clock_gettime( CLOCK_REALTIME, &t ); // system-wide clock
  return (double)( t.tv_sec+t.tv_nsec*1.0E-9 );

}