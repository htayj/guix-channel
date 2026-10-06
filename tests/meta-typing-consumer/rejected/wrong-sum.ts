// Add<2, 5> computes the literal 7, so 8 is a type error.
import { Add } from 'meta-typing';
export const sum: Add<2, 5> = 8; // expect TS2322
