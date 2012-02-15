//
//  TetrisEngine.h
//  R1
//
//  Created by John Bellardo on 3/8/11.
//  Copyright 2011 California State Polytechnic University, San Luis Obispo. All rights reserved.
//

#import <Foundation/Foundation.h>

#define NoTetromino 0
#define ITetromino  1
#define JTetromino  2
#define LTetromino  3
#define OTetromino  4
#define STetromino  5
#define TTetromino  6
#define ZTetromino  7

#define TetrisNumCols 10
#define TetrisNumRows 

#define TetrisArrSize(rows) ( (rows) * TetrisNumCols )
#define TetrisArrIdx(row, col) ( (row) * TetrisNumCols + (col) )

#define SINGLE          1
#define DOUBLE          2
#define TRIPLE          3
#define QUADRA          4
#define TETRIS          5

#define SINGLE_POINTS   100
#define DOUBLE_POINTS   250
#define TRIPLE_POINTS   450
#define QUADRA_POINTS   700
#define TETRIS_POINTS   1000

#define TetrisPieceBlocks 4
#define TetrisPieceRotations 4
#define TetrisNumPieces 7

@interface TetrisEngine : NSObject {
@private
    NSTimer                   *stepTimer;

    struct TetrisPiece        *currPiece;
    int pieceRow, pieceCol, pieceRotation;

    bool gameOver;
}

@property (readonly) int height, width, timeStep, score, gridVersion;
@property (readonly) bool running;
@property bool antigravity;

@property (strong) NSMutableArray *grid;


- (id) initWithHeight: (int) height;
- (id) initWithState: (NSDictionary *) state;

- (NSDictionary *) currentState;

- (void) slideCCW;
- (void) slideUp;
- (void) slideCW;
- (void) slideLeft;
- (void) slideDown;
- (void) slideRight;

- (void) start;
- (void) stop;

- (void) reset;

- (int) pieceAtRow: (int) row column: (int)col;
- (void) nextPiece;
- (void) commitCurrPiece;
- (BOOL) currPieceWillCollideAtRow: (int) row col: (int) col rotation: (int) rot;
- (BOOL) currPieceOffGrid;

@end
