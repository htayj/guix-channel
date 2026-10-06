// Results beyond upstream's 0..10 increment table become never, not 11.
import { Add } from 'meta-typing';
export const overflow: Add<9, 2> = 11; // expect TS2322
