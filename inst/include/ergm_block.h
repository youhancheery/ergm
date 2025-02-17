#ifndef _ERGM_BLOCK_H_
#define _ERGM_BLOCK_H_

#include "ergm_nodelist.h"

typedef struct {
  NodeList *tails;
  NodeList *heads;
  int diagonal;
  int directed;
} Block;

static inline Block *BlockInitialize(NodeList *tails, NodeList *heads, int diagonal, int directed) {
  Block *block = Calloc(1, Block);
  block->tails = tails;
  block->heads = heads;
  block->diagonal = diagonal;
  block->directed = directed;
  return block;
}

static inline void BlockDestroy(Block *block) {
  Free(block);
}

static inline void BlockPut2Dyad(Vertex *tail, Vertex *head, Dyad dyadindex, Block *block) {
  int tailindex;
  int headindex;
  
  if(block->diagonal) {
    if(block->directed) {
      dyadindex /= 2;
    }
    tailindex = dyadindex / block->tails->length;
    headindex = dyadindex % (block->heads->length - 1);
    if(tailindex == headindex) {
      headindex = block->heads->length - 1;
    }                  
  } else {
    dyadindex /= 2;
    tailindex = dyadindex / block->heads->length;
    headindex = dyadindex % block->heads->length;        
  }
  
  // 1-based indexing in NLs
  tailindex++;
  headindex++;
  
  if(block->tails->nodes[tailindex] < block->heads->nodes[headindex] || block->directed) {
    *tail = block->tails->nodes[tailindex];
    *head = block->heads->nodes[headindex];
  } else {
    *tail = block->heads->nodes[headindex];
    *head = block->tails->nodes[tailindex];      
  }
}

static inline Dyad BlockDyadCount(Block *block) {
  if(block->diagonal) {
    if(block->directed) {
      return (Dyad)block->tails->length*(block->heads->length - 1);
    } else {
      return (Dyad)block->tails->length*(block->heads->length - 1)/2;      
    }
  } else {
    return (Dyad)block->tails->length*block->heads->length;
  }
}

static inline int BlockDyadCountPositive(Block *block) {
  if(block->diagonal) {
    return block->tails->length > 1;
  } else {
    return block->tails->length > 0 && block->heads->length > 0;      
  }
}

#endif
