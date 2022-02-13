//
//  MathUtils.cpp
//  Curry
//
//  Created by Shu Chiun Cheah on 5/17/11.
//  Copyright 2011 GeoloPigs. All rights reserved.
//

#include "MathUtils.h"
#include <math.h>
#include <stdlib.h>
#include <CoreGraphics/CGAffineTransform.h>

float CGPointMagnitude(CGPoint givenPoint)
{
    float mag = (givenPoint.x * givenPoint.x) + (givenPoint.y * givenPoint.y);
    mag = sqrtf(mag);
    return mag;
}

CGPoint CGPointNormalize(CGPoint givenPoint)
{
    float mag = CGPointMagnitude(givenPoint);
    CGPoint result = CGPointMake(givenPoint.x / mag, givenPoint.y / mag);
    return result;
}

CGPoint CGPointSubtract(CGPoint pointA, CGPoint pointB)
{
    CGPoint result = CGPointMake(pointA.x - pointB.x, pointA.y - pointB.y);
    return result;
}

float DotProduct(CGPoint vecA, CGPoint vecB)
{
    float result = (vecA.x * vecB.x) + (vecA.y * vecB.y);
    return result;
}

float Distance(CGPoint pointA, CGPoint pointB)
{
    CGPoint distVec = CGPointSubtract(pointA, pointB);
    float result = CGPointMagnitude(distVec);
    return result;
}

float RadiansToDegrees(float radians)
{
    float result = radians * 180.0f / M_PI;
    return result;
}

float randomFrac()
{
    unsigned int randomNum = arc4random() % 101;
    float frac = static_cast<float>(randomNum) / 100.0f;
    return frac;
}

float normalizeAngle(float radians)
{    
    // only able to handle at most one rotation out of range in either side
    if(radians > (4.0f * M_PI))
    {
        radians = 0.0f;
    }
    if(radians < -(2.0f * M_PI))
    {
        radians = 0.0f;
    }
    
    float result = radians;
    if(0.0f > radians)
    {
        result = (2.0f * M_PI) + radians;
    }
    if((2.0f * M_PI) < radians)
    {
        result -= (2.0f * M_PI);
    }
    return result;
}

float vectorToRadians(CGPoint givenVec)
{
    float result = 0.0f;
    float mag = CGPointMagnitude(givenVec);
    CGPoint vec = CGPointMake(givenVec.x / mag, givenVec.y / mag);
    if(0.0f <= vec.y)
    {
        if(0.0f <= vec.x)
        {
            // first quadrant
            result = atanf(vec.y / vec.x);
        }
        else
        {
            // second quadrant
            result = M_PI - atanf(vec.y / (-vec.x));
        }
    }
    else
    {
        if(0.0f > vec.x)
        {
            // third quadrant
            result = M_PI + atanf(vec.y / vec.x);
        }
        else
        {
            // fourth quadrant
            result = (2.0f * M_PI) - atanf((-vec.y) / vec.x);
        }
    }
    return result;
}

// returns a rotation value based on zero at the given originAngle
float vectorToRadians(CGPoint givenVec, float originAngle)
{
    float result = vectorToRadians(givenVec);

    // normalize originAngle to be within 0 - 2PI
    if(0.0f > originAngle)
    {
        originAngle = (2.0f * M_PI) + originAngle;
    }
    if((2.0f * M_PI) < originAngle)
    {
        originAngle -= (2.0f * M_PI);
    }
    
    // adjust and noramlize result
    result -= originAngle;
    if(0.0f > result)
    {
        // if negative, put it back in range
        result = (2.0f * M_PI) + result;
    }
    if((2.0f * M_PI) < result)
    {
        // if larger than 360, put it back in range
        result -= (2.0f * M_PI);
    }
    return result;
}

CGPoint radiansToVector(CGPoint originVector, float radians, float magnitude)
{
    CGPoint vec = CGPointMake(originVector.x * magnitude, originVector.y * magnitude);
    CGAffineTransform t = CGAffineTransformMakeRotation(radians);
    CGPoint result = CGPointApplyAffineTransform(vec, t);
    return result;
}

float SmallerAngleDiff(float radiansA, float radiansB)
{
    float result = 0.0f;
    float diffPositive = 0.0f;
    float diffNegative = 0.0f;
    if(radiansA < radiansB)
    {
        diffPositive = radiansB - radiansA;
        diffNegative = (2.0f * M_PI) - radiansB + radiansA;
    }
    else
    {
        diffPositive = (2.0f * M_PI) - radiansA + radiansB;
        diffNegative = radiansA - radiansB;
    }
    
    if(diffPositive < diffNegative)
    {
        result = diffPositive;
    }
    else
    {
        result = -diffNegative;
    }
    return result;
}
