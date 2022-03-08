//
//  TPAnimeTrackLayoutViewFunc.h
//  dragDemo
//
//  Created by jaben on 2022/3/7.
//

#ifndef TPAnimeTrackLayoutViewFunc_h
#define TPAnimeTrackLayoutViewFunc_h

#pragma mark - View Function
static inline float leftOfRect(CGRect rect) {
    return rect.origin.x;
}

static inline float widthOfRect(CGRect rect) {
    return rect.size.width;
}

static inline float heightOfRect(CGRect rect) {
    return rect.size.height;
}

static inline float topOfRect(CGRect rect) {
    return rect.origin.y;
}

static inline float bottomOfRect(CGRect rect) {
    return rect.origin.y + rect.size.height;
}

static inline float rightOfRect(CGRect rect) {
    return rect.origin.x + rect.size.width;
}

static inline float centerXOfRect(CGRect rect) {
    return rect.origin.x + rect.size.width/2.f;
}

#pragma mark - IndexPath Function

static inline NSIndexPath *_Nullable nextIndexPathOf(NSIndexPath * _Nonnull indexPath) {
    return [NSIndexPath indexPathForRow:indexPath.row + 1 inSection:indexPath.section];
}

static inline NSIndexPath *_Nullable previousIndexPath(NSIndexPath * _Nonnull indexPath) {
    if (indexPath.row > 0) {
        return [NSIndexPath indexPathForRow:indexPath.row - 1 inSection:indexPath.section];
    }
    return nil;
}

#endif /* TPAnimeTrackLayoutViewFunc_h */
