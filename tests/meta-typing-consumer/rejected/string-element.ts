// Sum's public constraint accepts number tuples, not a tuple holding a string.
import { Sum } from 'meta-typing';
export type Total = Sum<['2', 1]>; // expect TS2344
