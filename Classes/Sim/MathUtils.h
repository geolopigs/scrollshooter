//
//  MathUtils.h
//  Curry
//
//  Created by Shu Chiun Cheah on 5/17/11.
//  Copyright 2011 GeoloPigs. All rights reserved.
//

#if !defined(_MATHUTILS_H)
#define _MATHUTILS_H

#include <CoreGraphics/CGGeometry.h>

extern float CGPointMagnitude(CGPoint givenPoint);
extern CGPoint CGPointNormalize(CGPoint givenPoint);
extern CGPoint CGPointSubtract(CGPoint pointA, CGPoint pointB);
extern float RadiansToDegrees(float radians);
extern float randomFrac();
extern float DotProduct(CGPoint vecA, CGPoint vecB);
extern float Distance(CGPoint pointA, CGPoint pointB);

// normalize a given angle to [0, 2PI]
// assumes given angle is at most one full rotation out of range
float normalizeAngle(float radians);

// returns a rotation value based on zero at (0,1)
extern float vectorToRadians(CGPoint givenVec);

// returns a rotation value based on zero at the given originAngle
extern float vectorToRadians(CGPoint givenVec, float originAngle); 

// returns a direction vector given an angle and a magnitude
CGPoint radiansToVector(CGPoint originVector, float radians, float magnitude);

// returns the magnitude of the smaller angle between two given angles
float SmallerAngleDiff(float radiansA, float radiansB);

#endif // #if !defined(_MATHUTILS_H)