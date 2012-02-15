//
//  TetrisEngine.m
//  R1
//
//  Created by John Bellardo on 3/8/11.
//  Copyright 2011 California State Polytechnic University, San Luis Obispo. All rights reserved.
//

#import "TetrisEngine.h"

@interface TetrisEngine ()

@property (readwrite) int height, timeStep, score, gridVersion;

@end

struct TetrisPiece { 
	int name;
	struct {
		int colOff, rowOff;
	} offsets[TetrisPieceRotations][TetrisPieceBlocks];
};

// Static array that defines all rotations for every piece.
// Each <x,y> point is an offset from the center of the piece.
static struct TetrisPiece pieces[TetrisNumPieces] = {
	{ ITetromino,	{
        { {-2, 0}, { -1, 0}, { 0, 0 }, {1, 0} },  // 0 deg.
        { {0, 0}, { 0, 1}, { 0, 2 }, {0, 3} },  // 90 deg.
        { {-2, 0}, { -1, 0}, { 0, 0 }, {1, 0} },  // 180 deg.
        { {0, 0}, { 0, 1}, { 0, 2 }, {0, 3} },  // 270 deg.
    } },
	{ JTetromino,	{
        { {-1, 0}, { 0, 0}, { 1, 0 }, {-1, 1} }, // 0 deg.
        { {0, 0}, { 0, 1}, { 0, 2 }, {1, 2} }, // 90 deg.
        { {-1, 1}, { 0, 1}, { 1, 1 }, {1, 0} }, // 180 deg.
        { {-1, 0}, { 0, 0}, { 0, 1 }, {0, 2} }, // 270 deg.
    } },
	{ LTetromino,	{
        { {-1, 0}, { 0, 0}, { 1, 0 }, {1, 1} }, // 0 deg.
        { {0, 0}, { 1, 0}, { 0, 1 }, {0, 2} }, // 90 deg.
        { {-1, 1}, { 0, 1}, { 1, 1 }, {-1, 0} }, // 180 deg.
        { {-1, 2}, { 0, 2}, { 0, 1 }, {0, 0} }, // 270 deg.
    } },
	{ OTetromino,	{
        { {-1, 0}, { 0, 0}, { -1, 1 }, {0, 1} }, // 0 deg.
        { {-1, 0}, { 0, 0}, { -1, 1 }, {0, 1} }, // 90 deg.
        { {-1, 0}, { 0, 0}, { -1, 1 }, {0, 1} }, // 180 deg.
        { {-1, 0}, { 0, 0}, { -1, 1 }, {0, 1} }, // 270 deg.
    } },
	{ STetromino,	{
        { {-1, 0}, { 0, 0}, { 0, 1 }, {1, 1} }, // 0 deg.
        { {1, 0}, { 0, 1}, { 1, 1 }, {0, 2} }, // 90 deg.
        { {-1, 0}, { 0, 0}, { 0, 1 }, {1, 1} }, // 180 deg.
        { {1, 0}, { 0, 1}, { 1, 1 }, {0, 2} }, // 270 deg.
    } },
	{ TTetromino,	{
        { {-1, 0}, { 0, 0}, { 1, 0 }, {0, 1} }, // 0 deg.
        { {0, 0}, { 0, 1}, { 1, 1 }, {0, 2} }, // 90 deg.
        { {-1, 1}, { 0, 1}, { 1, 1 }, {0, 0} }, // 180 deg.
        { {0, 1}, { 1, 0}, { 1, 1 }, {1, 2} }, // 270 deg.
    } },
	{ ZTetromino,	{
        { {-1, 1}, { 0, 0}, { 1, 0 }, {0, 1} }, // 0 deg.
        { {0, 0}, { 0, 1}, { 1, 1 }, {1, 2} }, // 90 deg.
        { {-1, 1}, { 0, 0}, { 1, 0 }, {0, 1} }, // 180 deg.
        { {0, 0}, { 0, 1}, { 1, 1 }, {1, 2} }, // 270 deg.
    } }
};

@implementation TetrisEngine
@synthesize grid, height, timeStep, score, gridVersion, antigravity;
@dynamic width, running;

- (id) init
{
	return [self initWithHeight: 12];
}

- (id) initWithHeight: (int) h
{
    
    
	self = [super init];
    
	if (self) {     
		srandom(time(0));
        
		self.height = h;
		self.grid = [[NSMutableArray alloc] initWithCapacity:(self.width * self.height)];
        
        self.antigravity = [[NSUserDefaults standardUserDefaults] boolForKey:@"antigravity"];
        
        [self reset];
    }
    
	return self;
}

- (id) initWithState:(NSDictionary *)state
{
    self = [self initWithHeight: [[state objectForKey: @"height"] intValue]];
    
    self.grid       = [[state objectForKey:  @"grid"]             mutableCopy];
    
    self.height     = [[state objectForKey: @"height"]            intValue];
    self.timeStep   = [[state objectForKey: @"timeStep"]          intValue];
    self.score      = [[state objectForKey: @"score"]             intValue];
    
    pieceCol        = [[state objectForKey: @"pieceCol"]          intValue];
    pieceRow        = [[state objectForKey: @"pieceRow"]          intValue];
    pieceRotation   = [[state objectForKey: @"pieceRotation"]     intValue];
    
    currPiece   = &pieces[[[state objectForKey:@"currPiece"]      intValue]];
    
    return self;
}

- (NSDictionary *) currentState
{
    if (currPiece == nil || gameOver) {
        return nil;
    }
    
    return [[NSDictionary alloc] initWithObjectsAndKeys:
            self.grid,
            @"grid",
            
            [[NSNumber alloc] initWithInt:  self.height],
            @"height",
            [[NSNumber alloc] initWithInt:  self.timeStep],
            @"timeStep",
            [[NSNumber alloc] initWithInt:  self.score],
            @"score",
            
            [[NSNumber alloc] initWithInt:  pieceCol],
            @"pieceCol",
            [[NSNumber alloc] initWithInt:  pieceRow],
            @"pieceRow",
            [[NSNumber alloc] initWithInt:  pieceRotation],
            @"pieceRotation",
            
            [[NSNumber alloc] initWithInt:  (currPiece - &pieces[0])],
            @"currPiece",
            
            nil];
}

// Add the next floating piece to the game board
- (void) nextPiece
{
	currPiece = &pieces[ ((random() % (TetrisNumPieces * 113)) + 3) % TetrisNumPieces];
	pieceCol = self.width / 2;
	pieceRow = self.height - 1;
	pieceRotation = 0;
    
    self.gridVersion++;
}

// Returns YES if the current floating piece will colide with another game board object or
//  edge given a new row / column / rotation value
- (BOOL) currPieceWillCollideAtRow: (int) row col: (int) col rotation: (int) rot
{
	if (!currPiece)
		return NO;
	
	for (int blk = 0; currPiece && blk < TetrisPieceBlocks; blk++) {
		int checkRow = row + currPiece->offsets[rot][blk].rowOff;
		int checkCol = col + currPiece->offsets[rot][blk].colOff;
		
		if (checkRow < 0 || checkCol < 0 || checkCol >= self.width)
			return YES;
        
		// Enables the board to extend upwards past the screen.  Useful
		// when rotating pieces very early in their fall.
		if (checkRow >= self.height)
			continue;
		
		if ([[self.grid  objectAtIndex:TetrisArrIdx(checkRow, checkCol)] intValue] != NoTetromino)
			return YES;
	}
    
	return NO;
}

// Returns YES if any part of the current piece is off the grid
- (BOOL) currPieceOffGrid
{
	if (!currPiece)
		return NO;
	
	for (int blk = 0; currPiece && blk < TetrisPieceBlocks; blk++) {
		int checkRow = pieceRow + currPiece->offsets[pieceRotation][blk].rowOff;
		int checkCol = pieceCol + currPiece->offsets[pieceRotation][blk].colOff;
		
		if (checkRow < 0 || checkRow >= self.height ||
			checkCol < 0 || checkCol >= self.width)
			return YES;
	}
	
	return NO;
}

- (int) width
{
	return TetrisNumCols;
}

- (bool) running
{
    return (stepTimer) ? true : false;
}

- (void) slideLeft
{
	if (self.running &&
        ![self currPieceWillCollideAtRow: pieceRow col: pieceCol - 1 rotation: pieceRotation]) {
		pieceCol--;
        
        self.gridVersion++;
    }
}

- (void) slideRight
{
	if (self.running &&
        ![self currPieceWillCollideAtRow: pieceRow col: pieceCol + 1 rotation: pieceRotation]) {
		pieceCol++;
        
        self.gridVersion++;
    }
}

- (void) slideCW
{
	if (self.running &&
        ![self currPieceWillCollideAtRow: pieceRow col: pieceCol
								rotation: (pieceRotation + 1) % TetrisPieceRotations]) {
            pieceRotation = (pieceRotation + 1) % TetrisPieceRotations;
            
            self.gridVersion++;
        }
}

- (void) slideCCW
{
	int newRot = pieceRotation - 1;
	while (newRot < 0)
		newRot += TetrisPieceRotations;
	if (self.running &&
        ![self currPieceWillCollideAtRow: pieceRow col: pieceCol
								rotation: newRot]) {
            pieceRotation = newRot;
            
            self.gridVersion++;
        }
}

- (void) slideDown {
    if (self.running &&
        ![self currPieceWillCollideAtRow: pieceRow - 1 col: pieceCol rotation: pieceRotation]) {
		pieceRow--;
        
        self.gridVersion++;
    }
}

- (void) slideUp {
    if (self.running && antigravity &&
        ![self currPieceWillCollideAtRow: pieceRow + 1 col: pieceCol rotation: pieceRotation]) {
		pieceRow++;
        
        self.gridVersion++;
    }
}


- (void) start {
    if (!self.running) {
        NSDate *fireDate = [NSDate dateWithTimeIntervalSinceNow:0.0];
        stepTimer = [[NSTimer alloc] initWithFireDate:fireDate
                                             interval:1.0
                                               target:self
                                             selector:@selector(advance)
                                             userInfo:nil
                                              repeats:YES];
        
        NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
        [runLoop addTimer:stepTimer forMode:NSDefaultRunLoopMode];
    }
}

- (void) stop {
    if (self.running) {
        [stepTimer invalidate];
        stepTimer = nil;
    }
}


- (int) pieceAtRow: (int) row column: (int)col
{
	for (int blk = 0; currPiece && blk < TetrisPieceBlocks; blk++) {
		if (row == (currPiece->offsets[pieceRotation][blk].rowOff + pieceRow) &&
			col == (currPiece->offsets[pieceRotation][blk].colOff + pieceCol) )
			return currPiece->name;
	}
	return [[self.grid objectAtIndex:TetrisArrIdx(row, col)] intValue];
}

- (void) commitCurrPiece
{
	// Copy current floating piece into grid state
	for (int blk = 0; currPiece && blk < TetrisPieceBlocks; blk++) {
		[self.grid replaceObjectAtIndex:TetrisArrIdx(currPiece->offsets[pieceRotation][blk].rowOff + pieceRow,
                                                     currPiece->offsets[pieceRotation][blk].colOff + pieceCol)
                             withObject: [[NSNumber alloc] initWithInt:currPiece->name]];
        
        self.gridVersion++;
	}
    
	currPiece = NULL;
	
	// Check for lines that can be eliminated from grid
	int elimRowCnt = 0;
	for (int dstRow = 0; dstRow < self.height; dstRow++) {
		int checkCol = 0;
		for (; checkCol < TetrisNumCols &&
			 [[self.grid objectAtIndex:TetrisArrIdx(dstRow, checkCol)] intValue] != NoTetromino; checkCol++)
			;
		if (checkCol < TetrisNumCols)
			continue;
		
		// Copy grid state into board
		elimRowCnt++;
		for (int srcRow = dstRow + 1; srcRow < self.height; srcRow++)
			for (int srcCol = 0; srcCol < self.width; srcCol++)
				[self.grid replaceObjectAtIndex:TetrisArrIdx(srcRow - 1, srcCol) withObject: [self.grid objectAtIndex:TetrisArrIdx(srcRow, srcCol)]];
        
		for (int col = 0; col < TetrisNumCols; col++)
			[self.grid replaceObjectAtIndex:TetrisArrIdx(self.height - 1, col) withObject: [[NSNumber alloc] initWithInt:NoTetromino]];
		dstRow--;
	}
    
    switch (elimRowCnt) {
        case SINGLE:
            self.score += SINGLE_POINTS;
            break;
            
        case DOUBLE:
            self.score += DOUBLE_POINTS;
            break;
            
        case TRIPLE:
            self.score += TRIPLE_POINTS;
            break;
            
        case QUADRA:
            self.score += QUADRA_POINTS;
            break;
            
        case TETRIS:
            self.score += TETRIS_POINTS;
            break;
            
        default:
            break;
    }
}

- (void) advance
{
	if (!gameOver && self.running) {
        
        self.timeStep++;
        
        if (!currPiece)
            [self nextPiece];
        else if (![self currPieceWillCollideAtRow: pieceRow - 1 col: pieceCol  rotation: pieceRotation])
            pieceRow--;
        else if (![self currPieceOffGrid])
            [self commitCurrPiece];
        else
            gameOver = YES;
        
        if(![self currPieceOffGrid])
            self.gridVersion++;
    }
}

- (void) reset
{
    [self stop];
    
    self.timeStep = self.score = pieceCol = pieceRow = pieceRotation = 0;
    currPiece = nil;
    
    for (NSUInteger i = 0; i < self.width * self.height; i++) {
        if (i < self.grid.count) {
            [self.grid replaceObjectAtIndex:i withObject:[[NSNumber alloc] initWithInt:0]];
            
        } else {
            [self.grid addObject:[[NSNumber alloc] initWithInt:0]];
        }
    }
    
    gameOver = false;    
    self.gridVersion++;
}

@end
