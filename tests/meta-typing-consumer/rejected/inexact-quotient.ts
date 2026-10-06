// Divide truncates; the exact-equality helper rejects a rounded-up result.
import { Divide } from 'meta-typing';
type Equal<A, B> =
  (<T>() => T extends A ? 1 : 2) extends (<T>() => T extends B ? 1 : 2)
    ? (<T>() => T extends B ? 1 : 2) extends (<T>() => T extends A ? 1 : 2)
      ? true : false
    : false;
type Assert<T extends true> = T;
export type Quotient = Assert<Equal<Divide<9, 4>, 3>>; // expect TS2344
