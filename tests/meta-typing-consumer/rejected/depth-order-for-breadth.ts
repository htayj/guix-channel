// Breadth-first order differs from the depth-first order on this tree.
import { BreadthFirst } from 'meta-typing';
import { Orchard } from '../accepted';
export const levelOrder: BreadthFirst<Orchard> = ['root', 'left', 'twig', 'right']; // expect TS2322
