//
//  ColorArrays.m
//  FEViewer2
//
//  Created by Christian Hansen on 5/3/12.
//  Copyright (c) 2012 Calcul8.it. All rights reserved.
//

#import "ColorArrays.h"

@implementation ColorArrays


#define NO_OF_COLORS 20

+ (GLKVector4 *)materialColorsWithTransparency:(float)transparency
{
    GLKVector4 *colors = calloc(NO_OF_COLORS, sizeof(GLKVector4));
    
    for (NSUInteger color = 0; color < NO_OF_COLORS; color++) 
    {
        switch (color) {
            case 0:
                colors[color] = GLKVector4Make(100.0/256.0f, 149.0f/256.0f, 237.0f/256.0f, transparency); //Cornflower Blue	100-149-237
                break;
                
            case 1:
                colors[color] = GLKVector4Make(119.0/256.0f, 136.0/256.0f, 153.0/256.0f, transparency); //Light Slate Gray	119-136-153
                break;
                
            case 2:
                colors[color] = GLKVector4Make(123.0/256.0f, 104.0/256.0f, 238.0/256.0f, transparency); //Medium Slate Blue	123-104-238
                
                break;
                
            case 3:
                colors[color] = GLKVector4Make(0.0/256.0f, 206.0/256.0f, 209.0/256.0f, transparency); //Dark Turquoise	0-206-209
                break;
                
            case 4:
                colors[color] = GLKVector4Make(60.0/256.0f, 179.0/256.0f, 113.0/256.0f, transparency); //Medium Sea Green	60-179-113
                break;
                
            case 5:
                colors[color] = GLKVector4Make(189.0/256.0f, 183.0/256.0f, 107.0/256.0f, transparency); //Dark Khaki	189-183-107
                break;
                
            case 6:
                colors[color] = GLKVector4Make(238.0/256.0f, 221.0/256.0f, 130.0/256.0f, transparency); //Light Goldenrod	238-221-130
                break;
                
            case 7:
                colors[color] = GLKVector4Make(222.0/256.0f, 184.0/256.0f, 135.0/256.0f, transparency); //Burlywood	222-184-135
                break;
                
            case 8:
                colors[color] = GLKVector4Make(210.0/256.0f, 105.0/256.0f, 30.0/256.0f, transparency); //Chocolate	210-105-30
                break;
                
            case 9:
                colors[color] = GLKVector4Make(233.0/256.0f, 150.0/256.0f, 122.0/256.0f, transparency); //Dark Salmon	233-150-122
                break;
                
            case 10:
                colors[color] = GLKVector4Make(255.0/256.0f, 69.0/256.0f, 0.0/256.0f, transparency); //Orange Red	255-69-0
                break;
                
            case 11:
                colors[color] = GLKVector4Make(219.0/256.0f, 112.0/256.0f, 147.0/256.0f, transparency); //Pale Violet Red	219-112-147
                break;
                
            case 12:
                colors[color] = GLKVector4Make(147.0/256.0f, 112.0/256.0f, 219.0/256.0f, transparency); //Medium Purple	147-112-219
                break;
                
            case 13:
                colors[color] = GLKVector4Make(30.0/256.0f, 144.0/256.0f, 255.0/256.0f, transparency); //Dodger Blue	30-144-255
                break;
                
            case 14:
                colors[color] = GLKVector4Make(95.0/256.0f, 158.0/256.0f, 160.0/256.0f, transparency); //Cadet Blue	95-158-160
                break;
                
            case 15:
                colors[color] = GLKVector4Make(131.0/256.0f, 139.0/256.0f, 131.0/256.0f, transparency); //Honeydew 4	131-139-131
                break;
                
            case 16:
                colors[color] = GLKVector4Make(238.0/256.0f, 203.0/256.0f, 173.0/256.0f, transparency); //Peach Puff 2	238-203-173
                break;
                
            case 17:
                colors[color] = GLKVector4Make(70.0/256.0f, 130.0/256.0f, 180.0/256.0f, transparency); //Steel Blue	70-130-180
                break;
                
            case 18:
                colors[color] = GLKVector4Make(0.0/256.0f, 201.0/256.0f, 87.0/256.0f, transparency); //Emerald green 0-201-87
                break;
                
            case 19:
                colors[color] = GLKVector4Make(113.0/256.0f, 198.0/256.0f, 113.0/256.0f, transparency); //sgi chartreuse 113-198-113
                break;
                
            default:
                break;
        }
    }
    return colors;
}
@end
