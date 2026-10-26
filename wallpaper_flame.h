/*
 * wallpaper_flame.h
 *
 * One "neighbour-hop" function per wallpaper group, for use as a
 * transform/variation in a flame-fractal (chaos-game) renderer. Each
 * function reads the point (*x, *y), picks one of the group's generators
 * (translations to the adjacent tile in each lattice direction, plus that
 * group's rotations/reflections/glides to the neighbouring tile they reach)
 * uniformly at random, applies it, and writes the result back into *x, *y.
 *
 * The formulas match the "Transformations" section of wallpaper.md for
 * each group, 1:1 — see that file for the derivation and diagrams.
 * Translations are included in both + and - directions along each lattice
 * vector (the doc only shows one direction each, since a single direction
 * is enough to generate the group under repeated iteration — but a flame
 * that only ever steps +a1/+a2 would drift monotonically off to infinity
 * instead of exploring the tiling, so both directions are offered here).
 * Rotations/reflections/glides are finite-order (or self-inverse), so they
 * don't need a separate "backwards" variant — repeated iteration already
 * cycles through all of them.
 *
 * Angles (gamma) are in radians. Lengths (a, b) are in whatever world
 * units your flame uses.
 *
 * RNG: WP_RANDOM() must expand to a call returning a float in [0,1).
 * The default uses rand()/RAND_MAX; #define WP_RANDOM() to your own
 * generator (e.g. a faster xorshift) before including this header if
 * you want higher-quality or thread-local randomness.
 */

#ifndef WALLPAPER_FLAME_H
#define WALLPAPER_FLAME_H

#include <math.h>
#include <stdlib.h>

#ifndef WP_RANDOM
#define WP_RANDOM() ((float)rand() / ((float)RAND_MAX + 1.0f))
#endif

#define WP_SQRT3_2 0.86602540378f /* sqrt(3)/2 */

/* ---- p1 (o): oblique lattice, translations only. 4 moves. ---- */
static inline void wp_p1(float *x, float *y, float a, float b, float gamma)
{
    float px = *x, py = *y;
    float a2x = b * cosf(gamma), a2y = b * sinf(gamma);
    int k = (int)(WP_RANDOM() * 4.0f);
    switch (k) {
        case 0: *x = px + a;   *y = py;        break;
        case 1: *x = px - a;   *y = py;        break;
        case 2: *x = px + a2x; *y = py + a2y;  break;
        default:*x = px - a2x; *y = py - a2y;  break;
    }
}

/* ---- p2 (2222): oblique lattice + 180 deg rotation. 6 moves. ---- */
static inline void wp_p2(float *x, float *y, float a, float b, float gamma)
{
    float px = *x, py = *y;
    float a2x = b * cosf(gamma), a2y = b * sinf(gamma);
    int k = (int)(WP_RANDOM() * 6.0f);
    switch (k) {
        case 0: *x = px + a;   *y = py;        break;
        case 1: *x = px - a;   *y = py;        break;
        case 2: *x = px + a2x; *y = py + a2y;  break;
        case 3: *x = px - a2x; *y = py - a2y;  break;
        case 4: *x = -px;      *y = -py;       break; /* 180 deg about (0,0) */
        default:*x = a - px;   *y = -py;       break; /* 180 deg about (a/2,0) */
    }
}

/* ---- pm (**): rectangular lattice, mirrors only. 6 moves. ---- */
static inline void wp_pm(float *x, float *y, float a, float b)
{
    float px = *x, py = *y;
    int k = (int)(WP_RANDOM() * 6.0f);
    switch (k) {
        case 0: *x = px + a;  *y = py;      break;
        case 1: *x = px - a;  *y = py;      break;
        case 2: *x = px;      *y = py + b;  break;
        case 3: *x = px;      *y = py - b;  break;
        case 4: *x = -px;     *y = py;      break; /* mirror at x=0 */
        default:*x = a - px;  *y = py;      break; /* mirror at x=a/2 */
    }
}

/* ---- pg (xx): rectangular lattice, glides only. 5 moves. ---- */
static inline void wp_pg(float *x, float *y, float a, float b)
{
    float px = *x, py = *y;
    int k = (int)(WP_RANDOM() * 5.0f);
    switch (k) {
        case 0: *x = px + a;  *y = py;          break;
        case 1: *x = px - a;  *y = py;          break;
        case 2: *x = px;      *y = py + b;      break;
        case 3: *x = px;      *y = py - b;      break;
        default:*x = -px;     *y = py + b/2.0f; break; /* glide, axis x=0 */
    }
}

/* ---- cm (*x): centered rectangular, mirror + induced glide. 8 moves. ---- */
static inline void wp_cm(float *x, float *y, float a, float b)
{
    float px = *x, py = *y;
    int k = (int)(WP_RANDOM() * 8.0f);
    switch (k) {
        case 0: *x = px + a;         *y = py;             break;
        case 1: *x = px - a;         *y = py;             break;
        case 2: *x = px;             *y = py + b;         break;
        case 3: *x = px;             *y = py - b;         break;
        case 4: *x = px + a/2.0f;    *y = py + b/2.0f;    break; /* centering */
        case 5: *x = px - a/2.0f;    *y = py - b/2.0f;    break;
        case 6: *x = -px;            *y = py;             break; /* mirror x=0 */
        default:*x = a/2.0f - px;    *y = py + b/2.0f;    break; /* glide x=a/4 */
    }
}

/* ---- pmm (*2222): rectangular, two mirror families + 2-fold. 7 moves. ---- */
static inline void wp_pmm(float *x, float *y, float a, float b)
{
    float px = *x, py = *y;
    int k = (int)(WP_RANDOM() * 7.0f);
    switch (k) {
        case 0: *x = px + a; *y = py;      break;
        case 1: *x = px - a; *y = py;      break;
        case 2: *x = px;     *y = py + b;  break;
        case 3: *x = px;     *y = py - b;  break;
        case 4: *x = -px;    *y = py;      break; /* mirror x=0 */
        case 5: *x = px;     *y = -py;     break; /* mirror y=0 */
        default:*x = -px;    *y = -py;     break; /* 180 deg about (0,0) */
    }
}

/* ---- pmg (22*): rectangular, mirror + perpendicular glide. 7 moves. ---- */
static inline void wp_pmg(float *x, float *y, float a, float b)
{
    float px = *x, py = *y;
    int k = (int)(WP_RANDOM() * 7.0f);
    switch (k) {
        case 0: *x = px + a;      *y = py;      break;
        case 1: *x = px - a;      *y = py;      break;
        case 2: *x = px;          *y = py + b;  break;
        case 3: *x = px;          *y = py - b;  break;
        case 4: *x = -px;         *y = py;      break;      /* mirror x=0 */
        case 5: *x = px + a/2.0f; *y = -py;     break;      /* glide y=0 */
        default:*x = a/2.0f - px; *y = -py;     break;      /* 180 deg about (a/4,0) */
    }
}

/* ---- pgg (22x): rectangular, two perpendicular glides. 7 moves. ---- */
static inline void wp_pgg(float *x, float *y, float a, float b)
{
    float px = *x, py = *y;
    int k = (int)(WP_RANDOM() * 7.0f);
    switch (k) {
        case 0: *x = px + a;      *y = py;             break;
        case 1: *x = px - a;      *y = py;             break;
        case 2: *x = px;          *y = py + b;         break;
        case 3: *x = px;          *y = py - b;         break;
        case 4: *x = px + a/2.0f; *y = -py;            break; /* glide y=0 */
        case 5: *x = -px;         *y = py + b/2.0f;    break; /* glide x=0 */
        default:*x = a/2.0f - px; *y = b/2.0f - py;     break; /* 180 deg about (a/4,b/4) */
    }
}

/* ---- cmm (2*22): centered rectangular, two mirrors + 2-fold. 10 moves. ---- */
static inline void wp_cmm(float *x, float *y, float a, float b)
{
    float px = *x, py = *y;
    int k = (int)(WP_RANDOM() * 10.0f);
    switch (k) {
        case 0: *x = px + a;      *y = py;             break;
        case 1: *x = px - a;      *y = py;             break;
        case 2: *x = px;          *y = py + b;         break;
        case 3: *x = px;          *y = py - b;         break;
        case 4: *x = px + a/2.0f; *y = py + b/2.0f;    break; /* centering */
        case 5: *x = px - a/2.0f; *y = py - b/2.0f;    break;
        case 6: *x = -px;         *y = py;             break; /* mirror x=0 */
        case 7: *x = px;          *y = -py;            break; /* mirror y=0 */
        case 8: *x = -px;         *y = -py;            break; /* 180 deg about (0,0) */
        default:*x = a/2.0f - px; *y = b/2.0f - py;     break; /* 180 deg about (a/4,b/4) */
    }
}

/* ---- p4 (442): square lattice, 4-fold rotation. 6 moves. ---- */
static inline void wp_p4(float *x, float *y, float a)
{
    float px = *x, py = *y;
    int k = (int)(WP_RANDOM() * 6.0f);
    switch (k) {
        case 0: *x = px + a; *y = py;        break;
        case 1: *x = px - a; *y = py;        break;
        case 2: *x = px;     *y = py + a;    break;
        case 3: *x = px;     *y = py - a;    break;
        case 4: *x = -py;    *y = px;        break;       /* 90 deg about (0,0) */
        default:*x = a - py; *y = px;        break;       /* 90 deg about (a/2,a/2) */
    }
}

/* ---- p4m (*442): square lattice, full D4 symmetry. 8 moves. ---- */
static inline void wp_p4m(float *x, float *y, float a)
{
    float px = *x, py = *y;
    int k = (int)(WP_RANDOM() * 8.0f);
    switch (k) {
        case 0: *x = px + a; *y = py;      break;
        case 1: *x = px - a; *y = py;      break;
        case 2: *x = px;     *y = py + a;  break;
        case 3: *x = px;     *y = py - a;  break;
        case 4: *x = -py;    *y = px;      break;  /* 90 deg about (0,0) */
        case 5: *x = px;     *y = -py;     break;  /* mirror y=0 */
        case 6: *x = py;     *y = px;      break;  /* mirror y=x */
        default:*x = a - px; *y = py;      break;  /* mirror x=a/2 */
    }
}

/* ---- p4g (4*2): square lattice, 4-fold "pinwheel" + offset mirror. 7 moves. ---- */
static inline void wp_p4g(float *x, float *y, float a)
{
    float px = *x, py = *y;
    int k = (int)(WP_RANDOM() * 7.0f);
    switch (k) {
        case 0: *x = px + a;         *y = py;             break;
        case 1: *x = px - a;         *y = py;             break;
        case 2: *x = px;             *y = py + a;         break;
        case 3: *x = px;             *y = py - a;         break;
        case 4: *x = -py;            *y = px;             break; /* 90 deg about (0,0) */
        case 5: *x = py + a/2.0f;    *y = px - a/2.0f;    break; /* diagonal mirror thru (a/2,0) */
        default:*x = a/2.0f - px;    *y = py + a/2.0f;    break; /* glide, axis x=a/4 */
    }
}

/* ---- p3 (333): hexagonal lattice, 3-fold rotation only. 5 moves. ---- */
static inline void wp_p3(float *x, float *y, float a)
{
    float px = *x, py = *y;
    float a2x = a/2.0f, a2y = a*WP_SQRT3_2;
    int k = (int)(WP_RANDOM() * 5.0f);
    switch (k) {
        case 0: *x = px + a;    *y = py;        break;
        case 1: *x = px - a;    *y = py;        break;
        case 2: *x = px + a2x;  *y = py + a2y;  break;
        case 3: *x = px - a2x;  *y = py - a2y;  break;
        default:*x = -0.5f*px - WP_SQRT3_2*py;  /* 120 deg about (0,0) */
                *y =  WP_SQRT3_2*px - 0.5f*py;  break;
    }
}

/* ---- p3m1 (*333): hexagonal, mirrors through every 3-fold center. 6 moves. ---- */
static inline void wp_p3m1(float *x, float *y, float a)
{
    float px = *x, py = *y;
    float a2x = a/2.0f, a2y = a*WP_SQRT3_2;
    int k = (int)(WP_RANDOM() * 6.0f);
    switch (k) {
        case 0: *x = px + a;    *y = py;        break;
        case 1: *x = px - a;    *y = py;        break;
        case 2: *x = px + a2x;  *y = py + a2y;  break;
        case 3: *x = px - a2x;  *y = py - a2y;  break;
        case 4: *x = -0.5f*px - WP_SQRT3_2*py;  /* 120 deg about (0,0) */
                *y =  WP_SQRT3_2*px - 0.5f*py;  break;
        default:*x = px;        *y = -py;       break; /* mirror at 0 deg (y=0) */
    }
}

/* ---- p31m (3*3): hexagonal, mirrors through only one 3-fold family. 6 moves. ---- */
static inline void wp_p31m(float *x, float *y, float a)
{
    float px = *x, py = *y;
    float a2x = a/2.0f, a2y = a*WP_SQRT3_2;
    int k = (int)(WP_RANDOM() * 6.0f);
    switch (k) {
        case 0: *x = px + a;    *y = py;        break;
        case 1: *x = px - a;    *y = py;        break;
        case 2: *x = px + a2x;  *y = py + a2y;  break;
        case 3: *x = px - a2x;  *y = py - a2y;  break;
        case 4: *x = -0.5f*px - WP_SQRT3_2*py;  /* 120 deg about (0,0) */
                *y =  WP_SQRT3_2*px - 0.5f*py;  break;
        default:*x = -px;       *y = py;        break; /* mirror at 90 deg (x=0) */
    }
}

/* ---- p6 (632): hexagonal lattice, 6-fold rotation. 5 moves. ---- */
static inline void wp_p6(float *x, float *y, float a)
{
    float px = *x, py = *y;
    float a2x = a/2.0f, a2y = a*WP_SQRT3_2;
    int k = (int)(WP_RANDOM() * 5.0f);
    switch (k) {
        case 0: *x = px + a;    *y = py;        break;
        case 1: *x = px - a;    *y = py;        break;
        case 2: *x = px + a2x;  *y = py + a2y;  break;
        case 3: *x = px - a2x;  *y = py - a2y;  break;
        default:*x =  0.5f*px - WP_SQRT3_2*py;  /* 60 deg about (0,0) */
                *y =  WP_SQRT3_2*px + 0.5f*py;  break;
    }
}

/* ---- p6m (*632): hexagonal, full symmetry. 6 moves. ---- */
static inline void wp_p6m(float *x, float *y, float a)
{
    float px = *x, py = *y;
    float a2x = a/2.0f, a2y = a*WP_SQRT3_2;
    int k = (int)(WP_RANDOM() * 6.0f);
    switch (k) {
        case 0: *x = px + a;    *y = py;        break;
        case 1: *x = px - a;    *y = py;        break;
        case 2: *x = px + a2x;  *y = py + a2y;  break;
        case 3: *x = px - a2x;  *y = py - a2y;  break;
        case 4: *x =  0.5f*px - WP_SQRT3_2*py;  /* 60 deg about (0,0) */
                *y =  WP_SQRT3_2*px + 0.5f*py;  break;
        default:*x = px;        *y = -py;       break; /* mirror y=0 */
    }
}

#endif /* WALLPAPER_FLAME_H */
