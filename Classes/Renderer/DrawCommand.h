//
//  DrawCommand.h
//
//

#import <Foundation/Foundation.h>


@interface DrawCommand : NSObject 
{
	id drawDelegate;
	id drawData;
}
@property (nonatomic,retain) id drawDelegate;
@property (nonatomic,retain) id drawData;

- (id) initWithDrawDelegate:(id)delegate DrawData:(id)data;

@end

@protocol DrawDelegate<NSObject>
- (void) draw:(id)instanceInfo;
@end
