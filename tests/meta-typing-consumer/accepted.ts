// Original installed-root consumer; no upstream tests or declaration copies.
import {
  Add, Subtract, Multiply, Divide, Remainder, Sum, MergeSort, QuickSort,
  Uniq, Includes, IndexOf, Range, Chunk, Zip, DepthFirst, BreadthFirst,
  Hanoi, Head, IsNever
} from 'meta-typing';

// Bidirectional exact equality also distinguishes any, never and unions.
type Equal<A, B> =
  (<T>() => T extends A ? 1 : 2) extends (<T>() => T extends B ? 1 : 2)
    ? (<T>() => T extends B ? 1 : 2) extends (<T>() => T extends A ? 1 : 2)
      ? true : false
    : false;
type Assert<T extends true> = T;

export type ArithmeticSum = Assert<Equal<Add<2, 5>, 7>>;
export type ArithmeticSubtract = Assert<Equal<Subtract<8, 5>, 3>>;
export type ArithmeticProduct = Assert<Equal<Multiply<2, 3>, 6>>;
export type IntegerQuotient = Assert<Equal<Divide<9, 4>, 2>>;
export type IntegerRemainder = Assert<Equal<Remainder<9, 4>, 1>>;
export type TupleSum = Assert<Equal<Sum<[2, 1, 4]>, 7>>;
export type UnsupportedOverflow = Assert<Equal<IsNever<Add<9, 2>>, true>>;
export type EmptyHead = Assert<Equal<IsNever<Head<[]>>, true>>;
export type SortedDuplicates = Assert<Equal<MergeSort<[4, 0, 2, 4]>, [0, 2, 4, 4]>>;
export type AlternateSort = Assert<Equal<QuickSort<[4, 0, 2, 4]>, [0, 2, 4, 4]>>;
export type StableUnique = Assert<Equal<Uniq<[4, 0, 4, 2, 0]>, [4, 0, 2]>>;
export type Present = Assert<Equal<Includes<[4, 0, 2], 0>, true>>;
export type Absent = Assert<Equal<Includes<[4, 0, 2], 3>, false>>;
export type FirstOccurrence = Assert<Equal<IndexOf<['oak', 'ash', 'oak'], 'oak'>, 0>>;
export type MissingIndex = Assert<Equal<IndexOf<['oak', 'ash'], 'elm'>, -1>>;
export type ExclusiveRange = Assert<Equal<Range<2, 5>, [2, 3, 4]>>;
export type Grouped = Assert<Equal<Chunk<['oak', 'ash', 'elm'], 2>, [['oak', 'ash'], ['elm']]>>;
export type Zipped = Assert<Equal<Zip<[['oak', 'ash'], [2, 4]]>, [['oak', 2], ['ash', 4]]>>;

// Structural client data; Empty/Branch/Leaf are not exported at package root.
// Unequal depths make DFS and BFS observably different.
export type Orchard = {
  value: 'root';
  left: {
    value: 'left';
    left: { value: 'twig'; left: { empty: true }; right: { empty: true } };
    right: { empty: true };
  };
  right: { value: 'right'; left: { empty: true }; right: { empty: true } };
};
export type Preorder = Assert<Equal<DepthFirst<Orchard>, ['root', 'left', 'twig', 'right']>>;
export type LevelOrder = Assert<Equal<BreadthFirst<Orchard>, ['root', 'left', 'right', 'twig']>>;
export type EmptyTree = Assert<Equal<BreadthFirst<{ empty: true }>, []>>;
export type NamedHanoi = Assert<Equal<Hanoi<2, 'source', 'target', 'spare'>,
  [['source', 'spare'], ['source', 'target'], ['spare', 'target']]>>;

// Actual accepted assignments, in addition to exact-type assertions.
export const sum: Add<2, 5> = 7;
export const product: Multiply<2, 3> = 6;
export const sorted: MergeSort<[4, 0, 2, 4]> = [0, 2, 4, 4];
export const unique: Uniq<[4, 0, 4, 2, 0]> = [4, 0, 2];
export const preorder: DepthFirst<Orchard> = ['root', 'left', 'twig', 'right'];
export const levelOrder: BreadthFirst<Orchard> = ['root', 'left', 'right', 'twig'];
export const moves: Hanoi<2, 'source', 'target', 'spare'> =
  [['source', 'spare'], ['source', 'target'], ['spare', 'target']];
