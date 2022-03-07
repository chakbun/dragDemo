//
//  TPAnimeTrackLayoutViewFunc.h
//  dragDemo
//
//  Created by jaben on 2022/3/7.
//

#ifndef TPAnimeTrackLayoutViewFunc_h
#define TPAnimeTrackLayoutViewFunc_h

#pragma mark - Function
static inline float leftOfRect(CGRect rect) {
    return rect.origin.x;
}

static inline float widthOfRect(CGRect rect) {
    return rect.size.width;
}

static inline float rightOfRect(CGRect rect) {
    return leftOfRect(rect) + widthOfRect(rect);
}

static inline float centerXOfRect(CGRect rect) {
    return leftOfRect(rect) + widthOfRect(rect)/2.f;
}

#endif /* TPAnimeTrackLayoutViewFunc_h */
