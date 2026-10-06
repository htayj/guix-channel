// Uniq removes repeated literals, so the unfiltered tuple is rejected.
import { Uniq } from 'meta-typing';
export const unique: Uniq<[4, 0, 4, 2, 0]> = [4, 0, 4, 2, 0]; // expect TS2322
